//
//  UMLayerM2PA.m
//  ulibm2pa
//
//  Created by Andreas Fink on 01.12.14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

//#define POWER_DEBUG  1  /* enable NSLog on poweron/poweroff*/

#import "UMLayerM2PA.h"
#import <ulibsctp/ulibsctp.h>
#import "UMLayerM2PAApplicationContextProtocol.h"
#import "UMM2PATask_sctpStatusIndication.h"
#import "UMM2PATask_sctpDataIndication.h"
#import "UMM2PATask_sctpMonitorIndication.h"

#import "UMM2PATask_AdminInit.h"
#import "UMM2PATask_AdminSetConfig.h"
#import "UMM2PATask_AdminAttach.h"
#import "UMM2PATask_Data.h"
#import "UMM2PATask_PowerOn.h"
#import "UMM2PATask_PowerOff.h"
#import "UMM2PATask_Start.h"
#import "UMM2PATask_Stop.h"
#import "UMM2PATask_Emergency.h"
#import "UMM2PATask_EmergencyCheases.h"
#import "UMM2PATask_SetSlc.h"
#import "UMM2PATask_TimerEvent.h"
#import "UMLayerM2PAUser.h"
#import "UMLayerM2PAUserProfile.h"
#import "UMM2PATask_AdminAttachOrder.h"
#import "UMM2PATask_AdminDetachOrder.h"
#import "UMM2PAUnackedPdu.h"

#import "UMM2PAState_allStates.h"

#define IAC_ASSIGN_AND_LOG(oldstatus,newstatus) \
{ \
	UMM2PAInitialAlignmentControl_State *n = newstatus;\
	if((oldstatus != n) && (self.logLevel <= UMLOG_DEBUG)) \
	{ \
		if(![oldstatus.description isEqualToString: n.description]) \
		{ \
			[self.logFeed debugText:[NSString stringWithFormat:@"IAC Status change %@->%@",oldstatus.description, n.description]]; \
		} \
		oldstatus = n; \
	} \
}

#define LSC_ASSIGN_AND_LOG(oldstatus,newstatus) \
{ \
	UMM2PALinkStateControl_State  *n = newstatus;\
	if((oldstatus != n) && (self.logLevel <= UMLOG_DEBUG))\
	{ \
		if(![oldstatus.description isEqualToString: n.description]) \
		{ \
			[self.logFeed debugText:[NSString stringWithFormat:@"LSC Status change %@->%@",oldstatus.description, n.description]]; \
		} \
		oldstatus = n; \
	} \
}


@implementation UMLayerM2PA

#pragma mark -
#pragma mark Initializer

-(NSString *)layerType
{
    return @"m2pa";
}

- (NSString *)stateString
{
    return _state.description;
}

- (M2PA_Status)stateCode
{
    return _state.statusCode;
}

/*
-(M2PA_Status)m2pa_status
{
    return _state.statusCode;
}

- (void)setM2pa_status:(M2PA_Status)status
{
    NSAssert(0,@"we should not use setM2pa_status anymore\n");
}
*/
- (UMLayerM2PA *)init
{
    @throw([NSException exceptionWithName:@"INVALID_INIT" reason:@"UMLayerM2PA must be initialized via initWithTaskQueueMulti:name:" userInfo:NULL]);
}

- (UMLayerM2PA *)initWithTaskQueueMulti:(UMTaskQueueMulti *)tq
{
    @throw([NSException exceptionWithName:@"INVALID_INIT" reason:@"UMLayerM2PA must be initialized via initWithTaskQueueMulti:name:" userInfo:NULL]);
}

- (UMLayerM2PA *)initWithTaskQueueMulti:(UMTaskQueueMulti *)tq name:(NSString *)name
{
    NSString *s = [NSString stringWithFormat:@"mm2pa/%@",name];
    @autoreleasepool
    {
        self = [super initWithTaskQueueMulti:tq name:s];
        if(self)
        {
            _users = [[UMSynchronizedArray alloc] init];
            _seqNumLock = [[UMMutex alloc]initWithName:@"m2pa-seq-num-mutex"];
            _dataLock = [[UMMutex alloc]initWithName:@"m2pa-data-mutex"];
            _controlLock = [[UMMutex alloc]initWithName:@"m2pa-control-mutex"];
            _incomingDataBufferLock = [[UMMutex alloc]initWithName:@"m2pa-incoming-data-mutex"];
            _unackedMsu = [[UMSynchronizedDictionary alloc]init];
            _state = [[UMM2PAState_Off alloc]initWithLink:self status:M2PA_STATUS_OFF];
            _slc = 0;
            _emergency = NO;
            _congested = NO;
            _local_processor_outage = NO;
            _remote_processor_outage = NO;
            _sctp_status = UMSOCKET_STATUS_OFF;
            _link_restarts = 0;
            _linkstateReadyReceived = 0;
            _ready_sent = 0;
            _paused = NO;
            _speed = 0; /* unlimited */
            _window_size = M2PA_DEFAULT_WINDOW_SIZE;
            _t1 = [[UMTimer alloc]initWithTarget:self selector:@selector(timerFires1) object:NULL seconds:M2PA_DEFAULT_T1 name:@"t1" repeats:NO runInForeground:YES];
            _t1r = [[UMTimer alloc]initWithTarget:self selector:@selector(timerFires1r) object:NULL seconds:M2PA_DEFAULT_T1R name:@"t1r" repeats:NO runInForeground:YES];
            _t2 = [[UMTimer alloc]initWithTarget:self
                                        selector:@selector(timerFires2)
                                          object:NULL seconds:M2PA_DEFAULT_T2
                                            name:@"t2"
                                         repeats:YES runInForeground:YES];
            _t3 = [[UMTimer alloc]initWithTarget:self selector:@selector(timerFires3) object:NULL seconds:M2PA_DEFAULT_T3 name:@"t3" repeats:NO runInForeground:YES];
            _t4 = [[UMTimer alloc]initWithTarget:self selector:@selector(timerFires4) object:NULL seconds:M2PA_DEFAULT_T4_N name:@"t4" repeats:NO runInForeground:YES];
            _t4r = [[UMTimer alloc]initWithTarget:self selector:@selector(timerFires4r) object:NULL seconds:M2PA_DEFAULT_T4_R name:@"t4r" repeats:YES runInForeground:YES];
            _t5 = [[UMTimer alloc]initWithTarget:self selector:@selector(timerFires5) object:NULL seconds:M2PA_DEFAULT_T5 name:@"t5" repeats:NO runInForeground:YES];
            _t6 = [[UMTimer alloc]initWithTarget:self selector:@selector(timerFires6) object:NULL seconds:M2PA_DEFAULT_T6 name:@"t6" repeats:NO runInForeground:YES];
            _t7 = [[UMTimer alloc]initWithTarget:self selector:@selector(timerFires7) object:NULL seconds:M2PA_DEFAULT_T7 name:@"t7" repeats:NO runInForeground:YES];
            _t16 = [[UMTimer alloc]initWithTarget:self selector:@selector(timerFires16) object:NULL seconds:M2PA_DEFAULT_T16 name:@"t16" repeats:NO runInForeground:YES];
            _t17 = [[UMTimer alloc]initWithTarget:self selector:@selector(timerFires17) object:NULL seconds:M2PA_DEFAULT_T17 name:@"t17" repeats:NO runInForeground:YES];
            _t18 = [[UMTimer alloc]initWithTarget:self selector:@selector(timerFires18) object:NULL seconds:M2PA_DEFAULT_T18 name:@"t18" repeats:NO runInForeground:YES];
            _ackTimer = [[UMTimer alloc]initWithTarget:self selector:@selector(ackTimerFires) object:NULL seconds:M2PA_DEFAULT_ACK_TIMER name:@"ack-timer" repeats:NO runInForeground:YES];
            _startTimer = [[UMTimer alloc]initWithTarget:self selector:@selector(startTimerFires) object:NULL seconds:M2PA_DEFAULT_START_TIMER name:@"start-timer" repeats:NO runInForeground:YES];
            _t4n = M2PA_DEFAULT_T4_N;
            _t4e = M2PA_DEFAULT_T4_E;
            _control_link_buffer        = [[NSMutableData alloc] init];
            _data_link_buffer           = [[NSMutableData alloc] init];
            _waitingMessages            = [[UMQueueSingle alloc]init];
            _inboundThroughputPackets   =  [[UMThroughputCounter alloc]initWithResolutionInSeconds: 1.0 maxDuration: 1260.0];
            _outboundThroughputPackets  =  [[UMThroughputCounter alloc]initWithResolutionInSeconds: 1.0 maxDuration: 1260.0];
            _inboundThroughputBytes     =  [[UMThroughputCounter alloc]initWithResolutionInSeconds: 1.0 maxDuration: 1260.0];
            _outboundThroughputBytes    =  [[UMThroughputCounter alloc]initWithResolutionInSeconds: 1.0 maxDuration: 1260.0];
        }
        return self;
    }
}

- (UMM2PAState *)state
{
    return _state;
}

- (void)backtraceException
{
    NSString *s = UMBacktrace(NULL, 0);
    NSLog(@"Backtrace: %@",s);
    fflush(stdout);
    sleep(1);
}

- (void)setState:(UMM2PAState *)state
{
    if(state == NULL)
    {
        [self backtraceException];
        UMAssert((state != NULL),@"state can not be null");
    }
    UMMUTEX_LOCK(_controlLock);
    @try
    {
        if((_logLevel <=UMLOG_DEBUG) || (_stateMachineLogFeed))
        {
            if(_state.statusCode != state.statusCode)
            {
                NSString *s;
                s = [NSString stringWithFormat:@"StateChange: %@->%@",_state.description,state.description];
                if(_logLevel <=UMLOG_DEBUG)
                {
                    [self logDebug:s];
                }
                if(_stateMachineLogFeed)
                {
                    [_stateMachineLogFeed debugText:s];
                }
            }
        }
        _state = state;
    }
    @catch(NSException *e)
    {
        [self logMajorError:[NSString stringWithFormat:@"Exception %@",e]];
    }
    @finally
    {
        UMMUTEX_UNLOCK(_controlLock);
    }
}

#pragma mark -
#pragma mark SCTP Callbacks



- (void) sctpStatusIndication:(UMLayer *)caller
                       userId:(id)uid
                       status:(UMSocketStatus)s
{
    return [self sctpStatusIndication:caller userId:uid status:s reason:NULL];
}

- (void) sctpStatusIndication:(UMLayer *)caller
                       userId:(id)uid
                       status:(UMSocketStatus)s
                       reason:(NSString *)reason
{
    @autoreleasepool
    {
#if defined(POWER_DEBUG)
        NSString *str;
        switch(s)
        {
            case UMSOCKET_STATUS_FOOS:
                str = @"UMSOCKET_STATUS_FOOS(-1)";
                break;
            case UMSOCKET_STATUS_OFF:
                str = @"UMSOCKET_STATUS_OFF(100)";
                break;
            case UMSOCKET_STATUS_OOS:
                str = @"UMSOCKET_STATUS_OOS(101)";
                break;
            case UMSOCKET_STATUS_IS:
                str = @"UMSOCKET_STATUS_IS(102)";
                break;
            case UMSOCKET_STATUS_LISTENING:
                str = @"UMSOCKET_STATUS_LISTENING(103)";
                break;
            default:
                str = [NSString stringWithFormat:@"UNKNOWN(%d)",s];
        }
        NSLog(@"sctpStatusIndication in m2pa %@ from %@ status:%@",_layerName,caller.layerName,str);        
#endif
        UMM2PATask_sctpStatusIndication *task = [[UMM2PATask_sctpStatusIndication alloc]initWithReceiver:self
                                                                                                  sender:caller
                                                                                                  userId:uid
                                                                                                  status:s
                                                                                                  reason:reason];
        [self queueFromLowerWithPriority:task];
    }
}

- (void) sctpDataIndication:(UMLayer *)caller
                     userId:(id)uid
                   streamId:(uint16_t)sid
                 protocolId:(uint32_t)pid
                       data:(NSData *)d
{
    @autoreleasepool
    {
        UMM2PATask_sctpDataIndication *task = [[UMM2PATask_sctpDataIndication alloc]initWithReceiver:self
                                                                                              sender:caller
                                                                                              userId:uid
                                                                                            streamId:sid
                                                                                          protocolId:pid
                                                                                                data:d];
        [self queueFromLower:task];
    }
}

- (void) sctpMonitorIndication:(UMLayer *)caller
                        userId:(id)uid
                      streamId:(uint16_t)sid
                    protocolId:(uint32_t)pid
                          data:(NSData *)d
                      incoming:(BOOL)in
{
    @autoreleasepool
    {
        UMM2PATask_sctpMonitorIndication *task = [[UMM2PATask_sctpMonitorIndication alloc]initWithReceiver:self
                                                                                                    sender:caller
                                                                                                    userId:uid
                                                                                                  streamId:sid
                                                                                                protocolId:pid
                                                                                                      data:d
                                                                                                  incoming:in];
        [self queueFromLower:task];
    }
}
- (void)sctpReportsUp
{
    UMMUTEX_LOCK(_controlLock);
    @try
    {
        _sctpUpReceived++;
        
        if([_state isKindOfClass:[UMM2PAState_Off class]])
        {
            self.state = [_state eventSctpUp];
        }
        if([_state isKindOfClass:[UMM2PAState_OutOfService class]])
        {
            [self start];
        }
    }
    @catch(NSException *e)
    {
        [self logMajorError:[NSString stringWithFormat:@"Exception %@",e]];
    }
    @finally
    {
        UMMUTEX_UNLOCK(_controlLock);
    }
}

- (void)sctpReportsDown
{
    UMMUTEX_LOCK(_controlLock);
    @try
    {
        _sctpDownReceived++;
        self.state = [_state eventSctpDown];
    }
    @catch(NSException *e)
    {
        [self logMajorError:[NSString stringWithFormat:@"Exception %@",e]];
    }
    @finally
    {
        UMMUTEX_UNLOCK(_controlLock);
    }
}

- (void) _sctpStatusIndicationTask:(UMM2PATask_sctpStatusIndication *)task
{
    [self setSctp_status:task.status reason:task.reason];
}

- (UMSocketStatus)sctp_status
{
    return _sctp_status;
}

- (void)setSctp_status:(UMSocketStatus )newStatus
{
    [self setSctp_status:newStatus reason:NULL];
}

- (void)setSctp_status:(UMSocketStatus )newStatus reason:(NSString *)reason
{
    int old_sctp_status = _sctp_status;
    _sctp_status = newStatus;
    
    if(old_sctp_status == _sctp_status)
    {
        /* nothing has changed we can ignore */
        return;
    }

    if( (old_sctp_status != UMSOCKET_STATUS_OFF)
       && (_sctp_status == UMSOCKET_STATUS_OFF))
    {
        /* SCTP Link has died */
        if(reason==NULL)
        {
            [_state logStatemachineEvent:"sctp-link-died"];
        }
        else
        {
            NSString *s = [NSString stringWithFormat:@"sctp-link-died %@",reason];
            [_state logStatemachineEvent:s.UTF8String];
        }
        [self sctpReportsDown];
        [_sctpLink openFor:self sendAbortFirst:NO reason:@"sctp-link-died"];
    }
    if( (old_sctp_status != UMSOCKET_STATUS_IS)
    && (_sctp_status == UMSOCKET_STATUS_IS))
    {
        /* SCTP link came up properly. Lets start M2PA now on it */
        [self sctpReportsUp];
    }

    NSArray *usrs = [_users arrayCopy];
    {
        /* we should pass service indicator /network indicator /user info back too? */
        for(UMLayerM2PAUser *u in usrs)
        {
            if([u.profile wantsSctpLinkstateMessages])
            {
                [u.user m2paSctpStatusIndication:self
                                             slc:_slc
                                          userId:u.linkName
                                          status:_sctp_status];
            }
        }
    }
}

- (void) _sctpDataIndicationTask:(UMM2PATask_sctpDataIndication *)task
{
    @autoreleasepool
    {
        if(self.logLevel <= UMLOG_DEBUG)
        {
            [self logDebug:@"sctpDataIndication:"];
            [self logDebug:[NSString stringWithFormat:@" data: %@",task.data.description]];
            [self logDebug:[NSString stringWithFormat:@" streamId: %d",task.streamId]];
            [self logDebug:[NSString stringWithFormat:@" protocolId: %d",task.protocolId]];
            [self logDebug:[NSString stringWithFormat:@" userId: %@",task.userId  ? task.userId : @"(null)"]];
        }
        if(task.protocolId != SCTP_PROTOCOL_IDENTIFIER_M2PA)
        {
            NSMutableString *s = [[NSMutableString alloc]init];
            [s appendString:@"----PROTOCOL IDENTIFIER IS NOT M2PA----"];
            [s appendString:@"\n  in sctpDataIndication:"];
            [s appendFormat:@"\n    data: %@",task.data.description];
            [s appendFormat:@"\n    streamId: %d",task.streamId];
            [s appendFormat:@"\n    protocolId: %d",task.protocolId];
            [s appendFormat:@"\n    userId: %@",task.userId  ? task.userId : @"(null)"];
            [self protocolViolation:s];
            return;
        }

        const uint8_t *dptr;
        dptr = task.data.bytes;
        if(task.data.length < 8)
        {
            NSString *e = [NSString stringWithFormat:@"received too short M2PA packet\n%@",task.data.hexString];
            [self protocolViolation:e];
        }
        else
        {
            uint8_t version       =  (uint8_t) dptr[0];
            uint8_t message_class =  (uint8_t) dptr[2];
            uint8_t message_type  =  (uint8_t) dptr[3];
            if(version !=1)
            {
                NSString *e = [NSString stringWithFormat:@"received M2PA packet with unknown version=%d\n%@",version,task.data.hexString];
                [self protocolViolation:e];
            }
            else if(message_class !=11)
            {
                NSString *e = [NSString stringWithFormat:@"received M2PA packet with unknown message class=%d\n%@",message_class,task.data.hexString];
                [self protocolViolation:e];
            }

            if((task.streamId == M2PA_STREAM_LINKSTATE) || ( message_type==2))
            {
                [self sctpIncomingLinkstateMessage:task.data];
            }
            else if((task.streamId == M2PA_STREAM_USERDATA) && (message_type==1))
            {
                [self sctpIncomingDataMessage:task.data];
            }
            else
            {
                NSString *e = [NSString stringWithFormat:@"invalid M2PA packet received. StreamId=%u Version=%u, messageClass=%u messageType=%u\n%@",task.streamId,version,message_class,message_type,task.data.hexString];
                [self protocolViolation:e];
            }
        }
    }
}

- (void) _sctpMonitorIndicationTask:(UMM2PATask_sctpMonitorIndication *)task
{
    /* needs to be defined to comply with the API */
}

-(void) protocolViolation: (NSString *)reason
{
    @autoreleasepool
    {
        NSString *e = [NSString stringWithFormat:@"PROTOCOL VIOLATION: %@",reason];
        [self logMajorError:e];
        [_stateMachineLogFeed debugText:e];
#if defined(POWER_DEBUG)
        NSLog(@"protocol violation for m2pa %@: %@",_layerName,reason);
#endif
        [self powerOff:e];
    }
}

-(void) protocolViolation
{
    @autoreleasepool
    {
        [self logMajorError:@"PROTOCOL VIOLATION"];
        [_stateMachineLogFeed debugText:@"PROTOCOL VIOLATION"];
#if defined(POWER_DEBUG)
        NSLog(@"protocol violation for m2pa %@",_layerName);
#endif
        [self powerOff:@"PROTOCOL VIOLATION"];
    }
}

- (void) sctpIncomingDataMessage:(NSData *)data
{
    @autoreleasepool
    {
        [_inboundThroughputPackets increaseBy:1];
        [_inboundThroughputBytes increaseBy:(uint32_t)data.length];
        u_int32_t len;
        const char *dptr;
        [_incomingDataBufferLock lock];
        @try
        {
            [_data_link_buffer appendData:data];
            dptr = _data_link_buffer.bytes;
            while([_data_link_buffer length] >= 16)
            {
                len = ntohl(*(u_int32_t *)&dptr[4]);
                if(_data_link_buffer.length < len)
                {
                    if(self.logLevel <=UMLOG_DEBUG)
                    {
                        [self logDebug:[NSString stringWithFormat:@"not enough data received yet %lu bytes in buffer, expecting %u",
                                        _data_link_buffer.length,
                                        len]];
                    }
                    break;
                }
                else
                {
                    /* dumpHeader here */
                }
            
                /* BSN in a packet is the last FSN received from the peer */
                /* so we set _bsn for the next outgoing packet */
                /* _bsn2 is the last received bsn from the other side */
                u_int32_t currentRxBsn = ntohl(*(u_int32_t *)&dptr[8]) & FSN_BSN_MASK;
                u_int32_t currentRxFsn = ntohl(*(u_int32_t *)&dptr[12]) & FSN_BSN_MASK;
                [self bsnAckFrom:_lastRxBsn to:currentRxBsn];
                _lastRxBsn = currentRxBsn;
                _lastRxFsn = currentRxFsn;
                [self checkSpeed];
            
                int userDataLen = len-16;
                if(userDataLen < 0)
                {
                    [self logMajorError:@"m2pa userDataLen is < 0"];
                    [self protocolViolation];
                    return;
                }
                if(userDataLen > 0)
                {
                    if(_useAckTimer == YES)
                    {
                        UMMUTEX_LOCK(_dataLock);
                        [_ackTimer start];
                        UMMUTEX_UNLOCK(_dataLock);
                    }
                    else
                    {
                        [self ackTimerFires];
                    }
                }
                NSData *userData = [NSData dataWithBytes:&dptr[16] length:userDataLen];
                UMMUTEX_LOCK(_controlLock);
                @try
                {
                    self.state = [_state eventReceiveUserData:userData];
                    if(![self.state isKindOfClass: [UMM2PAState_InService class]])
                    {
                        self.state = [[UMM2PAState_InService alloc]initWithLink:self status:M2PA_STATUS_IS];
                    }
                    [self notifyMtp3UserData:userData];
                }
                @catch(NSException *e)
                {
                    [self logMajorError:[NSString stringWithFormat:@"Exception %@",e]];
                }
                @finally
                {
                    UMMUTEX_UNLOCK(_controlLock);
                }
                [_data_link_buffer replaceBytesInRange: NSMakeRange(0,len) withBytes:"" length:0];
            }
        }
        @finally
        {
            [_incomingDataBufferLock unlock];
        }
    }
}

- (void)bsnAckFrom:(int)start to:(int)end
{
    if((_lastTxFsn >= FSN_BSN_MASK) || (end >= FSN_BSN_MASK))
    {
        _outstanding = 0;
    }
    else
    {
        _outstanding = ((long)_lastTxFsn - (long)end ) % FSN_BSN_SIZE;
    }

    int j= 0;
    if(end > start)
    {
        for(u_int32_t i = (start+1); i <= end; i++)
        {
            [_unackedMsu removeObjectForKey:@(i % FSN_BSN_SIZE)];
            j++;
            if(j > (2*_window_size))
            {
                break;
            }
        }
    }
    else if (start < end)
    {
        for(u_int32_t i = (start+1); i <= (end + FSN_BSN_SIZE); i++)
        {
            [_unackedMsu removeObjectForKey:@(i % FSN_BSN_SIZE)];
            j++;
            if(j > (2*_window_size))
            {
                break;
            }
        }
    }
}


- (void) notifyMtp3UserData:(NSData *)userData
{
    @autoreleasepool
    {
        NSArray *usrs = [_users arrayCopy];
        for(UMLayerM2PAUser *u in usrs)
        {
            UMLayerM2PAUserProfile *profile = u.profile;
            if([profile wantsDataMessages])
            {
                id user = u.user;
                [user m2paDataIndication:self
                                     slc:_slc
                            mtp3linkName:u.linkName
                                    data:userData];

            }
        }
    }
}

- (void) sctpIncomingLinkstateMessage:(NSData *)data
{
    @autoreleasepool
    {

        M2PA_linkstate_message linkstatus;
        uint32_t len;
        const char *dptr;
        
        if(self.logLevel <= UMLOG_DEBUG)
        {
            [self logDebug:[NSString stringWithFormat:@" %d bytes of linkstatus data received",(int)data.length]];
        }
        UMMUTEX_LOCK(_controlLock);
        @try
        {
            [_control_link_buffer appendData:data];
            if(_control_link_buffer.length < 20)
            {
                [self logDebug:@"not enough data received yet"];
            }
            else
            {
                dptr = _control_link_buffer.bytes;
                len = ntohl(*(u_int32_t *)&dptr[4]);
                linkstatus = ntohl(*(u_int32_t *)&dptr[16]);

                if(self.logLevel <= UMLOG_DEBUG)
                {
                    NSString *ls = [UMLayerM2PA linkStatusString:linkstatus];
                    [self logDebug:[NSString stringWithFormat:@"Received %@",ls]];
                }
                switch(linkstatus)
                {
                    case M2PA_LINKSTATE_ALIGNMENT:				/* 1 */
                        [self _alignment_received];
                        break;
                    case M2PA_LINKSTATE_PROVING_NORMAL:			/* 2 */
                        [self _proving_normal_received];
                        break;
                    case M2PA_LINKSTATE_PROVING_EMERGENCY:		/* 3 */
                        [self _proving_emergency_received];
                        break;
                    case M2PA_LINKSTATE_READY:					/* 4 */
                        [self _linkstate_ready_received];
                        break;
                    case M2PA_LINKSTATE_PROCESSOR_OUTAGE:		/* 5 */
                        [self _linkstate_processor_outage_received];
                        break;
                    case M2PA_LINKSTATE_PROCESSOR_RECOVERED:	/* 6 */
                        [self _linkstate_processor_recovered_received];
                        break;
                    case M2PA_LINKSTATE_BUSY:					/* 7 */
                        [self _linkstate_busy_received];
                        break;
                    case M2PA_LINKSTATE_BUSY_ENDED:				/* 8 */
                        [self _linkstate_busy_ended_received];
                        break;
                    case M2PA_LINKSTATE_OUT_OF_SERVICE:		/* 9 */
                        /* other side tells us they are out of service. I wil let mtp3 know and have it send us a start */
                        [self _oos_received];
                        //m2pa_oos_received(link);
                        break;
                    default:
                        [self logMajorError:[NSString stringWithFormat:@"Unknown linkstate '0x%04X' received",linkstatus]];
                }
                /* according to RFC 4165, the additional stuff are filler bytes */
                [_control_link_buffer replaceBytesInRange: NSMakeRange(0,len) withBytes:"" length:0];
            }
        }
        @catch(NSException *e)
        {
            [self logMajorError:[NSString stringWithFormat:@"Exception %@",e]];
        }
        @finally
        {
            UMMUTEX_UNLOCK(_controlLock);
        }
    }
}

- (void) _oos_received
{
    UMMUTEX_LOCK(_controlLock);
    @try
    {
        _linkstateOutOfServiceReceived++;
        if(_state == NULL)
        {
            _state = [[UMM2PAState_Off alloc]initWithLink:self status:M2PA_STATUS_OFF];
        }
        self.state = [_state eventLinkstatusOutOfService];
    }
    @finally
    {
        UMMUTEX_UNLOCK(_controlLock);
    }
}

- (void) _alignment_received
{
    UMMUTEX_LOCK(_controlLock);
    @try
    {
        self.state = [_state eventLinkstatusAlignment];
        _linkstateAlignmentReceived++;
        _linkstateProvingReceived=0;
        _linkstateProvingSent=0;
    }
    @catch(NSException *e)
    {
        [self logMajorError:[NSString stringWithFormat:@"Exception %@",e]];
    }
    @finally
    {
        UMMUTEX_UNLOCK(_controlLock);
    }
}

- (void) _proving_normal_received
{
    UMMUTEX_LOCK(_controlLock);
    @try
    {
        _linkstateProvingReceived++;
        self.state = [_state eventLinkstatusProvingNormal];
    }
    @catch(NSException *e)
    {
        [self logMajorError:[NSString stringWithFormat:@"Exception %@",e]];
    }
    @finally
    {
        UMMUTEX_UNLOCK(_controlLock);
    }
}

- (void) _proving_emergency_received
{
    UMMUTEX_LOCK(_controlLock);
    @try
    {
        _linkstateProvingReceived++;
        if(_emergency == NO)
        {
            _emergency = YES;
        }
        self.state = [_state eventLinkstatusProvingEmergency];
    }
    @catch(NSException *e)
    {
        [self logMajorError:[NSString stringWithFormat:@"Exception %@",e]];
    }
    @finally
    {
        UMMUTEX_UNLOCK(_controlLock);
    }
}

- (void) _linkstate_ready_received
{
    UMMUTEX_LOCK(_controlLock);
    @try
    {
        _linkstateReadyReceived++;
        self.state = [_state eventLinkstatusReady];
    }
    @catch(NSException *e)
    {
        [self logMajorError:[NSString stringWithFormat:@"Exception %@",e]];
    }
    @finally
    {
        UMMUTEX_UNLOCK(_controlLock);
    }
}

- (void) _linkstate_processor_outage_received
{
    UMMUTEX_LOCK(_controlLock);
    @try
    {
        _linkstateProcessorOutageReceived++;
        self.state = [_state eventLinkstatusProcessorOutage];
    }
    @catch(NSException *e)
    {
        [self logMajorError:[NSString stringWithFormat:@"Exception %@",e]];
    }
    @finally
    {
        UMMUTEX_UNLOCK(_controlLock);
    }
}

- (void) _linkstate_processor_recovered_received
{
    UMMUTEX_LOCK(_controlLock);
    @try
    {
        _linkstateProcessorRecoveredReceived++;
        self.state = [_state eventLinkstatusProcessorRecovered];
    }
    @catch(NSException *e)
    {
        [self logMajorError:[NSString stringWithFormat:@"Exception %@",e]];
    }
    @finally
    {
        UMMUTEX_UNLOCK(_controlLock);
    }
}

- (void) _linkstate_busy_received
{
    UMMUTEX_LOCK(_controlLock);
    @try
    {
        _linkstateBusyReceived++;
        self.state = [_state eventLinkstatusBusy];
    }
    @catch(NSException *e)
    {
        [self logMajorError:[NSString stringWithFormat:@"Exception %@",e]];
    }
    @finally
    {
        UMMUTEX_UNLOCK(_controlLock);
    }
}

- (void) _linkstate_busy_ended_received
{
    UMMUTEX_LOCK(_controlLock);
    @try
    {
        _linkstateBusyEndedReceived++;

        self.state = [_state eventLinkstatusBusyEnded];
    /* FIXME: this belongs into the state machine now */
        _link_congestion_cleared_time = [NSDate date];
        _congested = NO;
        [_t6 stop];
    }
    @catch(NSException *e)
    {
        [self logMajorError:[NSString stringWithFormat:@"Exception %@",e]];
    }
    @finally
    {
        UMMUTEX_UNLOCK(_controlLock);
    }
    [self sendCongestionClearedIndication];
    if([_waitingMessages count]>0)
    {
        [_t7 start];
    }
}

- (void) linktestTimerReportsFailure
{
    UMMUTEX_LOCK(_controlLock);
    @try
    {
        if(_state == NULL)
        {
            _state = [[UMM2PAState_Off alloc]initWithLink:self  status:M2PA_STATUS_OFF];
        }
        else
        {
            self.state = [_state eventLinkstatusOutOfService];
        }
    }
    @catch(NSException *e)
    {
        [self logMajorError:[NSString stringWithFormat:@"Exception %@",e]];
    }
    @finally
    {
        UMMUTEX_UNLOCK(_controlLock);
    }
}

- (void)startDequeuingMessages
{
    @autoreleasepool
    {
        UMLayerTask *task = [_waitingMessages getFirst];
        while(task)
        {
            [self queueFromUpperWithPriority:task];
            task = [_waitingMessages getFirst];
        }
    }
}

- (void) sendCongestionClearedIndication
{
    @autoreleasepool
    {
        NSArray *usrs = [_users arrayCopy];
        for(UMLayerM2PAUser *u in usrs)
        {
            if([u.profile wantsM2PALinkstateMessages])
            {
                [u.user m2paCongestionCleared:self
                                   slc:_slc
                                userId:u.linkName];
            }
        }
    }
}

- (void) sendCongestionIndication
{
    @autoreleasepool
    {
        NSArray *usrs = [_users arrayCopy];
        for(UMLayerM2PAUser *u in usrs)
        {
            if([u.profile wantsM2PALinkstateMessages])
            {
                [u.user m2paCongestion:self
                                   slc:_slc
                                userId:u.linkName];
            }
        }
    }
}

- (void) adminAttachConfirm:(UMLayer *)attachedLayer
                     userId:(id)uid
{
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"adminAttachConfirm"];
    }
    _sctpLink = (UMLayerSctp *)attachedLayer;
}


- (void) adminAttachFail:(UMLayer *)attachedLayer
                  userId:(id)uid
                  reason:(NSString *)reason
{
    [self logMajorError:[NSString stringWithFormat:@"adminAttachFail reason %@",reason]];
}


- (void) adminDetachConfirm:(UMLayer *)attachedLayer
                     userId:(id)uid
{
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"adminDetachConfirm"];
    }
    _sctpLink = NULL;
    
}


- (void) adminDetachFail:(UMLayer *)attachedLayer
                  userId:(id)uid
                  reason:(NSString *)reason
{
    [self logMajorError:[NSString stringWithFormat:@"adminDetachFail reason %@",reason]];
}


- (void)sentAckConfirmFrom:(UMLayer *)sender
                  userInfo:(NSDictionary *)userInfo
{
    
}


- (void)sentAckFailureFrom:(UMLayer *)sender
                  userInfo:(NSDictionary *)userInfo
                     error:(NSString *)err
                    reason:(NSString *)reason
                 errorInfo:(NSDictionary *)ei
{

}
#pragma mark -
#pragma mark Timer Callbacks

- (void)timerFires1
{
    [_t1 stop];
    [self queueTimerEvent:NULL timerName:@"t1"];

}

- (void)timerFires1r
{
    [self queueTimerEvent:NULL timerName:@"t1r"];
}

- (void)timerFires2
{
    [_t2 stop];
    [self queueTimerEvent:NULL timerName:@"t2"];
}
- (void)timerFires3
{
    [_t3 stop];
    [self queueTimerEvent:NULL timerName:@"t3"];
}
- (void)timerFires4
{
    [_t4 stop];
	[self queueTimerEvent:NULL timerName:@"t4"];
}

- (void)timerFires4r
{
	[self queueTimerEvent:NULL timerName:@"t4r"];
}

- (void)timerFires5
{
    [_t5 stop];
	[self queueTimerEvent:NULL timerName:@"t5"];
}
- (void)timerFires6
{
    [_t6 stop];
	[self queueTimerEvent:NULL timerName:@"t6"];
}

- (void)timerFires7
{
    [_t7 stop];
	[self queueTimerEvent:NULL timerName:@"t7"];
}

- (void)timerFires16
{
    [_t16 stop];
    [self queueTimerEvent:NULL timerName:@"t16"];
}


- (void)timerFires17
{
    [_t17 stop];
    [self queueTimerEvent:NULL timerName:@"t17"];
}


- (void)timerFires18
{
    [_t18 stop];
    [self queueTimerEvent:NULL timerName:@"t18"];
}

- (void)ackTimerFires
{
    if(_state.statusCode != M2PA_STATUS_IS)
    {
        return;
    }
    [self sendEmptyUserDataPacket];
}

- (void)startTimerFires
{
    if(_state.statusCode != M2PA_STATUS_OFF)
    {
        return;
    }
    [self powerOn];
}

- (void)_timerFires1
{
    UMMUTEX_LOCK(_controlLock);
    @try
    {
        self.state = [_state eventTimer1];
    }
    @catch(NSException *e)
    {
        [self logMajorError:[NSString stringWithFormat:@"Exception %@",e]];
    }
    @finally
    {
        UMMUTEX_UNLOCK(_controlLock);
    }
}

- (void)_timerFires1r
{
    UMMUTEX_LOCK(_controlLock);
    @try
    {
        self.state = [_state eventTimer1r];
    }
    @catch(NSException *e)
    {
        [self logMajorError:[NSString stringWithFormat:@"Exception %@",e]];
    }
    @finally
    {
        UMMUTEX_UNLOCK(_controlLock);
    }
}

- (void)_timerFires2
{
    UMMUTEX_LOCK(_controlLock);
    @try
    {
        self.state = [_state eventTimer2];
    }
    @catch(NSException *e)
    {
        [self logMajorError:[NSString stringWithFormat:@"Exception %@",e]];
    }
    @finally
    {
        UMMUTEX_UNLOCK(_controlLock);
    }
}

- (void)_timerFires3
{
    UMMUTEX_LOCK(_controlLock);
    @try
    {
        self.state = [_state eventTimer3];
    }
    @catch(NSException *e)
    {
        [self logMajorError:[NSString stringWithFormat:@"Exception %@",e]];
    }
    @finally
    {
        UMMUTEX_UNLOCK(_controlLock);
    }
}

- (void)_timerFires4
{
    UMMUTEX_LOCK(_controlLock);
    @try
    {
        self.state = [_state eventTimer4];
    }
    @catch(NSException *e)
    {
        [self logMajorError:[NSString stringWithFormat:@"Exception %@",e]];
    }
    @finally
    {
        UMMUTEX_UNLOCK(_controlLock);
    }
}

- (void)_timerFires4r
{
    UMMUTEX_LOCK(_controlLock);
    @try
    {
        self.state = [_state eventTimer4r];
    }
    @catch(NSException *e)
    {
        [self logMajorError:[NSString stringWithFormat:@"Exception %@",e]];
    }
    @finally
    {
        UMMUTEX_UNLOCK(_controlLock);
    }
}

- (void)_timerFires5
{
    UMMUTEX_LOCK(_controlLock);
    @try
    {
        self.state = [_state eventTimer5];
    }
    @catch(NSException *e)
    {
        [self logMajorError:[NSString stringWithFormat:@"Exception %@",e]];
    }
    @finally
    {
        UMMUTEX_UNLOCK(_controlLock);
    }
}

- (void)_timerFires6
{
	/* Figure 13/Q.703 (sheet 2 of 7) */
    UMMUTEX_LOCK(_controlLock);
    @try
    {
        self.state = [_state eventTimer6];
        _linkstate_busy = NO;
        [_t7 stop];
    }
    @catch(NSException *e)
    {
        [self logMajorError:[NSString stringWithFormat:@"Exception %@",e]];
    }
    @finally
    {
        UMMUTEX_UNLOCK(_controlLock);
    }
}
- (void)_timerFires7
{
    UMMUTEX_LOCK(_controlLock);
    @try
    {
        self.state = [_state eventTimer7];
    }
    @catch(NSException *e)
    {
        [self logMajorError:[NSString stringWithFormat:@"Exception %@",e]];
    }
    @finally
    {
        UMMUTEX_UNLOCK(_controlLock);
    }
}


#pragma mark -
#pragma mark Task Creators

- (void)adminInit
{
    @autoreleasepool
    {
        UMLayerTask *task = [[UMM2PATask_AdminInit alloc]initWithReceiver:self sender:NULL];
        [self queueFromAdmin:task];
    }
}

- (void)adminAttachOrder:(UMLayerSctp *)sctp_layer;
{
    @autoreleasepool
    {
        UMLayerTask *task = [[UMM2PATask_AdminAttachOrder alloc]initWithReceiver:self sender:NULL layer:sctp_layer];
        [self queueFromAdmin:task];
    }
}

- (void)adminSetConfig:(NSDictionary *)cfg applicationContext:(id<UMLayerM2PAApplicationContextProtocol>)appContext
{
    @autoreleasepool
    {
        UMLayerTask *task = [[UMM2PATask_AdminSetConfig alloc]initWithReceiver:self sender:NULL config:cfg applicationContext:appContext];
        [self queueFromAdmin:task];
    }
}

- (void)adminAttachFor:(id<UMLayerM2PAUserProtocol>)attachingLayer
{
    @autoreleasepool
    {
        UMLayerTask *task = [[UMM2PATask_AdminInit alloc]initWithReceiver:self sender:attachingLayer];
        [self queueFromAdmin:task];
    }
}

- (void)adminAttachFor:(id<UMLayerM2PAUserProtocol>)caller
               profile:(UMLayerM2PAUserProfile *)p
			  linkName:(NSString *)linkName
                   slc:(int)xslc

{
    @autoreleasepool
    {
        UMAssert(linkName != NULL,@"no link name passed to MTP2 adminAttachFor");
        UMAssert(p != NULL,@"no profile MTP2 adminAttachFor");

        UMLayerTask *task =  [[UMM2PATask_AdminAttach alloc]initWithReceiver:self
                                                                      sender:caller
                                                                     profile:p
                                                                         slc:xslc
                                                                    linkName:linkName];
        [self queueFromAdmin:task];
    }
}

- (void)dataFor:(id<UMLayerM2PAUserProtocol>)caller
           data:(NSData *)sendingData
     ackRequest:(NSDictionary *)ack
          async:(BOOL)async
            dpc:(int)dpc
{
    @autoreleasepool
    {

        UMM2PATask_Data *task = [[UMM2PATask_Data alloc] initWithReceiver:self
                                                               sender:caller
                                                                 data:sendingData
                                                           ackRequest:ack
                                                                  dpc:dpc];
        /* we can not queue this as otherwise the sequence might been destroyed */
        if(async==NO)
        {
            [task main];
        }
        else
        {
            [self queueFromUpper:task];
        }
    }
}

- (void)powerOnFor:(id<UMLayerM2PAUserProtocol>)caller forced:(BOOL)forced reason:(NSString *)reason
{
    if(forced)
    {
        _forcedOutOfService = NO;
    }
    @autoreleasepool
    {
        UMM2PATask_PowerOn *task = [[UMM2PATask_PowerOn alloc]initWithReceiver:self sender:caller];
        task.reason = reason;
        [self queueFromUpperWithPriority:task];
    }
}


- (void)powerOffFor:(id<UMLayerM2PAUserProtocol>)caller forced:(BOOL)forced reason:(NSString *)reason
{
    _forcedOutOfService = forced;
    @autoreleasepool
    {
#if defined(POWER_DEBUG)
        NSLog(@"powerOffFor called from %@ for m2pa %@ forced:%@",caller.layerName,_layerName,forced ? @"YES" : @"NO");
#endif
        UMM2PATask_PowerOff *task = [[UMM2PATask_PowerOff alloc]initWithReceiver:self sender:caller];
        task.reason = reason;
        [self queueFromUpperWithPriority:task];
    }
}

- (void)startFor:(id<UMLayerM2PAUserProtocol>)caller forced:(BOOL)forced reason:(NSString *)reason
{
    
    if(forced)
    {
        _forcedOutOfService = NO;
    }
    @autoreleasepool
    {
#if defined(POWER_DEBUG)
        NSLog(@"startFor called from %@ for m2pa %@ forced:%@",caller.layerName,_layerName,forced ? @"YES" : @"NO");
#endif
        UMM2PATask_Start *task = [[UMM2PATask_Start alloc]initWithReceiver:self sender:caller];
        task.reason = reason;
        [self queueFromUpperWithPriority:task];
    }
}

- (void)stopFor:(id<UMLayerM2PAUserProtocol>)caller forced:(BOOL)forced reason:(NSString *)reason
{
    @autoreleasepool
    {
#if defined(POWER_DEBUG)
        NSLog(@"stopFor called from %@ for m2pa %@ forced:%@",caller.layerName,_layerName,forced ? @"YES" : @"NO");
#endif
        UMM2PATask_Stop *task = [[UMM2PATask_Stop alloc]initWithReceiver:self sender:caller];
        task.reason = reason;
        [self queueFromUpperWithPriority:task];
    }
}


- (void)emergencyFor:(id<UMLayerM2PAUserProtocol>)caller
{
    UMLayerTask *task = [[UMM2PATask_Emergency alloc]initWithReceiver:self sender:caller];
    [self queueFromUpperWithPriority:task];
}

- (void)emergencyCheasesFor:(id<UMLayerM2PAUserProtocol>)caller
{
    UMLayerTask *task = [[UMM2PATask_EmergencyCheases alloc]initWithReceiver:self sender:caller];
    [self queueFromUpperWithPriority:task];
}

- (void)setSlcFor:(id<UMLayerM2PAUserProtocol>)caller slc:(int)xslc
{
    UMLayerTask *task = [[UMM2PATask_SetSlc alloc]initWithReceiver:self sender:caller slc:xslc];
    [self queueFromUpperWithPriority:task];
}

- (void)queueTimerEvent:(id)caller timerName:(NSString *)tname
{
    UMLayerTask *task = [[UMM2PATask_TimerEvent alloc]initWithReceiver:self sender:caller timerName:tname];
    [self queueFromAdmin:task];
}

/* LAYER API. The following methods are called by queued tasks */
#pragma mark -
#pragma mark Task Executors

- (void)_adminInitTask:(UMM2PATask_AdminInit *)task
{
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:[NSString stringWithFormat:@"adminInit"]];
    }
}

- (void) _adminAttachOrderTask:(UMM2PATask_AdminAttachOrder *)task
{
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"adminAttachOrder"];
    }

    UMLayerSctp *sctp = task.layer;
    _sctpLink = sctp;
    UMLayerSctpUserProfile *profile = [[UMLayerSctpUserProfile alloc]initWithDefaultProfile];
    [sctp adminAttachFor:self profile:profile userId:self.layerName];
}

- (void) _adminDetachOrderTask:(UMM2PATask_AdminDetachOrder *)task
{
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"adminAttachOrder"];
    }
    [_sctpLink adminDetachFor:self userId:self.layerName];
}


- (void)_adminSetConfigTask:(UMM2PATask_AdminSetConfig *)task
{
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:[NSString stringWithFormat:@"setConfig %@",task.config]];
    }
    [self setConfig:task.config applicationContext:task.applicationContext];
}

- (void)_adminAttachTask:(UMM2PATask_AdminAttach *)task
{
    id<UMLayerM2PAUserProtocol> user = (id<UMLayerM2PAUserProtocol>)task.sender;

    UMLayerM2PAUser *u = [[UMLayerM2PAUser alloc]init];
    u.linkName = task.linkName;
    u.user = user;
    u.profile = task.profile;
	u.linkName = task.linkName;
    _slc = task.slc;

    [_users addObject:u];
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:[NSString stringWithFormat:@"attachedFrom %@",user.layerName]];
    }
    [user adminAttachConfirm:self
                         slc:task.slc
					userId:task.linkName];
}

- (void)notifySpeedExceeded
{
    NSArray *usrs = [_users arrayCopy];
    for(UMLayerM2PAUser *u in usrs)
    {
        if([u.profile wantsSpeedMessages])
        {
            [u.user m2paSpeedLimitReached:self
                                      slc:_slc
                                   userId:u.linkName];
        }
    }
}

- (void)notifySpeedExceededCleared
{
    /* if we drop out of speed excess we can resume. however if we are still in congestion status
     we have to wait it to clear */
    //   time(&link->link_speed_excess_cleared_time);
    //   m2pa_send_speed_exceeded_cleared_indication_to_mtp3(link);

    NSArray *usrs = [_users arrayCopy];
    for(UMLayerM2PAUser *u in usrs)
    {
        if([u.profile wantsSpeedMessages])
        {
            [u.user m2paSpeedLimitReachedCleared:self
                                      slc:_slc
                                   userId:u.linkName];
        }
    }
}


- (void)notifyMtp3Congestion
{
    NSArray *usrs = [_users arrayCopy];
    for(UMLayerM2PAUser *u in usrs)
    {
        if([u.profile wantsSpeedMessages])
        {
            [u.user m2paCongestion:self
                               slc:_slc
                            userId:u.linkName];
        }
    }
}

- (void)notifyMtp3CongestionCleared
{
    /* if we drop out of speed excess we can resume. however if we are still in congestion status
     we have to wait it to clear */
    //   time(&link->link_speed_excess_cleared_time);
    //   m2pa_send_speed_exceeded_cleared_indication_to_mtp3(link);

    NSArray *usrs = [_users arrayCopy];
    for(UMLayerM2PAUser *u in usrs)
    {
        if([u.profile wantsSpeedMessages])
        {
            [u.user m2paCongestionCleared:self
                                      slc:_slc
                                   userId:u.linkName];
        }
    }
}

- (void)checkSpeed
{
    int last_speed_status;
    double	current_speed;

    [_seqNumLock lock];
    if((_lastTxFsn == FSN_BSN_MASK) || (_lastRxFsn == FSN_BSN_MASK))
    {
        _outstanding = 0;
        _lastRxFsn = _lastTxFsn;
    }
    else
    {
        _outstanding = ((long)_lastTxFsn - (long)_lastRxBsn ) % FSN_BSN_SIZE;
    }
    [_seqNumLock unlock];

    last_speed_status = _speed_status;

    //	error(0,"fsn: %u, bsn: %u, outstanding %u",link->fsn,link->bsn2,link->outstanding);

    if (_outstanding > _window_size)
    {
        _speed_status = SPEED_EXCEEDED;
    }
    else
    {
        _speed_status = SPEED_WITHIN_LIMIT;
        current_speed = [_outboundThroughputPackets getSpeedForSeconds:3];
        if(_speed <= 0)
        {
            _speed_status = SPEED_WITHIN_LIMIT;
        }
        else if (current_speed > _speed)
        {
            _speed_status = SPEED_EXCEEDED;
        }
        else
        {
            _speed_status = SPEED_WITHIN_LIMIT;
        }
    }
    if((last_speed_status == SPEED_WITHIN_LIMIT)
       && (_speed_status == SPEED_EXCEEDED))
    {
        [self notifySpeedExceeded];
    }
    else if((last_speed_status == SPEED_EXCEEDED)
            && (_speed_status == SPEED_WITHIN_LIMIT)
            && (_congested == NO))
    {
        [self notifySpeedExceededCleared];
    }
}

- (void)sendData:(NSData *)data
          stream:(uint16_t)streamId
      ackRequest:(NSDictionary *)ackRequest
             dpc:(int)dpc
{
    [_outboundThroughputPackets increaseBy:1];
    [_outboundThroughputBytes increaseBy:(uint32_t)data.length];
    UMMUTEX_LOCK(_dataLock);
    UMMUTEX_LOCK(_seqNumLock);
    @try
    {
        [_t1 stop]; /* alignment ready	*/
        [_t6 stop]; /* Remote congestion	*/
        /* if data is passed NULL; we send a empty ack packet and do not increase FSN */
        if(data != NULL)
        {
            _lastTxFsn = (_lastTxFsn+1) % FSN_BSN_SIZE;
        }
        /* The FSN and BSN values range from 0 to 16,777,215 */
        if((_lastTxFsn == FSN_BSN_MASK) || (_lastRxBsn == FSN_BSN_MASK))
        {
            _outstanding = 0;
            _lastRxBsn = _lastTxFsn;
        }
        else
        {
            _outstanding = ((long)_lastTxFsn - (long)_lastRxBsn ) % FSN_BSN_SIZE;
        }
        
        _lastTxBsn = _lastRxFsn;
        uint8_t header[16];
        size_t totallen =  sizeof(header) + data.length;
        header[0] = M2PA_VERSION1; /* version field */
        header[1] = 0; /* spare field */
        header[2] = M2PA_CLASS_RFC4165; /* m2pa_message_class = draft13;*/
        header[3] = M2PA_TYPE_USER_DATA; /*m2pa_message_type;*/
        header[4] = (totallen >> 24) & 0xFF;
        header[5] = (totallen >> 16) & 0xFF;
        header[6] = (totallen >> 8) & 0xFF;
        header[7] = (totallen >> 0) & 0xFF;
        header[8] = (_lastTxBsn >> 24) & 0xFF;
        header[9] = (_lastTxBsn >> 16) & 0xFF;
        header[10] = (_lastTxBsn >> 8) & 0xFF;
        header[11] = (_lastTxBsn >> 0) & 0xFF;
        header[12] = (_lastTxFsn >> 24) & 0xFF;
        header[13] = (_lastTxFsn >> 16) & 0xFF;
        header[14] = (_lastTxFsn >> 8) & 0xFF;
        header[15] = (_lastTxFsn >> 0) & 0xFF;

        if((streamId == M2PA_STREAM_USERDATA) && (data.length > 0))
        {
            UMM2PAUnackedPdu *updu = [[UMM2PAUnackedPdu alloc]init];
            updu.data = data;
            updu.dpc = dpc;
            _unackedMsu[@(_lastTxFsn)] = updu;
        }
        NSMutableData *sctpData = [[NSMutableData alloc]initWithBytes:&header length:sizeof(header)];
        if(data)
        {
            [sctpData appendData:data];
        }
        [_ackTimer stop];
        [_sctpLink dataFor:self
                      data:sctpData
                  streamId:streamId
                protocolId:SCTP_PROTOCOL_IDENTIFIER_M2PA
                ackRequest:ackRequest
               synchronous:YES];
    }
    @catch(NSException *e)
    {
        [self logMajorError:[NSString stringWithFormat:@"Exception: %@",e]];
    }
    @finally
    {
        UMMUTEX_UNLOCK(_seqNumLock);
        UMMUTEX_UNLOCK(_dataLock);
    }
}

- (void)sendEmptyUserDataPacket
{
    uint16_t    streamId = M2PA_STREAM_USERDATA;

    UMMUTEX_LOCK(_dataLock);
    UMMUTEX_LOCK(_seqNumLock);
    @try
    {
        _lastTxFsn = (_lastTxFsn+0) % FSN_BSN_SIZE; /* we do NOT increase the counter for empty packets */
        /* The FSN and BSN values range from 0 to 16,777,215 */
        if((_lastTxFsn == FSN_BSN_MASK) || (_lastRxFsn == FSN_BSN_MASK))
        {
            _outstanding = 0;
            _lastRxFsn = _lastTxFsn;
        }
        else
        {
            _outstanding = ((long)_lastTxFsn - (long)_lastRxBsn ) % FSN_BSN_SIZE;
        }
        _lastTxBsn = _lastRxFsn;
        uint8_t header[16];
        size_t totallen =  sizeof(header) + 0;
        header[0] = M2PA_VERSION1; /* version field */
        header[1] = 0; /* spare field */
        header[2] = M2PA_CLASS_RFC4165; /* m2pa_message_class = draft13;*/
        header[3] = M2PA_TYPE_USER_DATA; /*m2pa_message_type;*/
        header[4] = (totallen >> 24) & 0xFF;
        header[5] = (totallen >> 16) & 0xFF;
        header[6] = (totallen >> 8) & 0xFF;
        header[7] = (totallen >> 0) & 0xFF;
        header[8] = (_lastTxBsn >> 24) & 0xFF;
        header[9] = (_lastTxBsn >> 16) & 0xFF;
        header[10] = (_lastTxBsn >> 8) & 0xFF;
        header[11] = (_lastTxBsn >> 0) & 0xFF;
        header[12] = (_lastTxFsn >> 24) & 0xFF;
        header[13] = (_lastTxFsn >> 16) & 0xFF;
        header[14] = (_lastTxFsn >> 8) & 0xFF;
        header[15] = (_lastTxFsn >> 0) & 0xFF;
        NSMutableData *sctpData = [[NSMutableData alloc]initWithBytes:&header length:sizeof(header)];
        [_sctpLink dataFor:self
                      data:sctpData
                  streamId:streamId
                protocolId:SCTP_PROTOCOL_IDENTIFIER_M2PA
                ackRequest:NULL
               synchronous:YES];
    }
    @catch(NSException *e)
    {
        [self logMajorError:[NSString stringWithFormat:@"Exception: %@",e]];
    }
    @finally
    {
        UMMUTEX_UNLOCK(_seqNumLock);
        UMMUTEX_UNLOCK(_dataLock);
    }
}

- (void)_dataTask:(UMM2PATask_Data *)task
{
    NSData *mtp3_data = task.data;
    if(mtp3_data == NULL)
    {
        return;
    }
    [_submission_speed increase];
    [self checkSpeed];
    if(_congested)
    {
        [_waitingMessages append:task];
    }
    else
    {
        UMMUTEX_LOCK(_dataLock);
        @try
        {
            [_state eventSendUserData:mtp3_data
                           ackRequest:task.ackRequest
                                  dpc:task.dpc];
        }
        @catch(NSException *e)
        {
            [self logMajorError:[NSString stringWithFormat:@"Exception %@",e]];
        }
        @finally
        {
            UMMUTEX_UNLOCK(_dataLock);
        }
    }
}

- (void) resetSequenceNumbers
{
    [_seqNumLock lock];
    _lastTxFsn = 0x00FFFFFF; /* last sent FSN */
    _lastTxBsn = 0x00FFFFFF; /* last received FSN, next BSN to send. */
    _lastRxBsn = 0x00FFFFFF; /* last received bsn */
    [_seqNumLock unlock];
}

- (void)_powerOnTask:(UMM2PATask_PowerOn *)task
{
    [self resetSequenceNumbers];
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"powerOn"];
    }
    [self powerOn];

}

- (void)_powerOffTask:(UMM2PATask_PowerOff *)task
{
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"powerOff"];
    }
    [_stateMachineLogFeed debugText:@"PowerOff requested from upper layer"];

    NSString *s = [NSString stringWithFormat:@"powerOff requested-from-mtp3 (%@)", task.reason ? task.reason : @""];
    [self powerOff:s];
}

- (void)_startTask:(UMM2PATask_Start *)task
{
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"start"];
    }
    [self addToLayerHistoryLog:[NSString stringWithFormat:@"start (%@)", task.reason ? task.reason : @""]];
    [self start];

}

- (void)_stopTask:(UMM2PATask_Stop *)task
{
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"stop"];
    }
    [self addToLayerHistoryLog:[NSString stringWithFormat:@"stop (%@)", task.reason ? task.reason : @""]];
    [self stop];
}

- (void)_emergencyTask:(UMM2PATask_Emergency *)task
{
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"emergency"];
    }
    _emergency = YES;
}

- (void)_emergencyCheasesTask:(UMM2PATask_EmergencyCheases *)task
{
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"emergencyCheases"];
    }
    _emergency = NO;
}

- (void)_setSlcTask:(UMM2PATask_SetSlc *)task
{
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:[NSString stringWithFormat:@"settingSLC to %d",task.slc]];
    }

    _slc = task.slc;
}

- (void)_timerEventTask:(UMM2PATask_TimerEvent *)task
{
    UMMUTEX_LOCK(_controlLock);
    @try
    {
        NSString *timerName = task.timerName;
        if([timerName isEqualToString:@"t1"])
        {
            [self _timerFires1];
        }
        if([timerName isEqualToString:@"t1r"])
        {
            [self _timerFires1r];
        }

        else 	if([timerName isEqualToString:@"t2"])
        {
            [self _timerFires2];
        }
        else 	if([timerName isEqualToString:@"t3"])
        {
            [self _timerFires3];
        }
        else 	if([timerName isEqualToString:@"t4"])
        {
            [self _timerFires4];
        }
        else 	if([timerName isEqualToString:@"t4r"])
        {
            [self _timerFires4r];
        }
        else 	if([timerName isEqualToString:@"t5"])
        {
            [self _timerFires5];
        }
        else 	if([timerName isEqualToString:@"t6"])
        {
            [self _timerFires6];
        }
        else 	if([timerName isEqualToString:@"t7"])
        {
            [self _timerFires7];
        }
        else
        {
            UMAssert(0,@"Unknown timer fires: '%@'",timerName);
        }
    }
    @catch(NSException *e)
    {
        [self logMajorError:[NSString stringWithFormat:@"Exception %@",e]];
    }
    @finally
    {
        UMMUTEX_UNLOCK(_controlLock);
    }
}

#pragma mark -
#pragma mark Helpers

- (void)startupInitialisation
{
    _linkstateAlignmentReceived = 0;
    _linkstateAlignmentSent = 0;
    _linkstateProvingSent = 0;
    _linkstateProvingReceived = 0;
    _local_processor_outage = NO;
    _remote_processor_outage = NO;
    _emergency = NO;
    [self resetSequenceNumbers];
    _outstanding = 0;
    _linkstateReadyReceived = 0;
    _ready_sent = 0;
    _linkstateAlignmentReceived=0;
    _linkstateAlignmentSent=0;
    _linkstateProvingReceived=0;
    _linkstateProvingSent=0;
    [_inboundThroughputPackets clear];
    [_inboundThroughputBytes clear];
    [_outboundThroughputPackets clear];
    [_outboundThroughputBytes clear];
    [_submission_speed clear];
}


- (void)powerOn
{
    UMMUTEX_LOCK(_controlLock);
    @try
    {
        _powerOnCounter++;
        self.state = [[UMM2PAState_Off alloc]initWithLink:self  status:M2PA_STATUS_OFF];
        [self.state sendLinkstateOutOfService:YES];
        self.state = [_state eventPowerOn];
    }
    @catch(NSException *e)
    {
        [self logMajorError:[NSString stringWithFormat:@"Exception %@",e]];
    }
    @finally
    {
        UMMUTEX_UNLOCK(_controlLock);
    }
    /* we do additinoal stuff for power on in sctpReportsUp */
 }

- (void)powerOff
{
    [self powerOff:NULL];
}

- (void)powerOff:(NSString *)reason
{
#if defined(POWER_DEBUG)
    NSLog(@"powerOff called for m2pa %@. Queuing task",_layerName);
#endif
    
    UMMUTEX_LOCK(_controlLock);
    @try
    {
        _powerOffCounter++;
        self.state = [_state eventStop];
        self.state = [_state eventPowerOff];
        [_sctpLink closeFor:self reason:reason];
        [self startupInitialisation];
    }
    @catch(NSException *e)
    {
        NSString *s = [NSString stringWithFormat:@"Exception %@",e];
        [self logMajorError:s];
        [_stateMachineLogFeed debugText:s];
#if defined(POWER_DEBUG)
        NSLog(@"Exception: %@",e);
#endif
    }
    @finally
    {
        UMMUTEX_UNLOCK(_controlLock);
    }
}

- (void)start
{
#if defined(POWER_DEBUG)
    NSLog(@"start called for m2pa %@. Queuing task",_layerName);
#endif

    UMMUTEX_LOCK(_controlLock);
    @try
    {
        _startCounter++;
        if([_state isKindOfClass:[UMM2PAState_OutOfService class]])
        {
            self.state = [_state eventStart];
        }
        if([_state isKindOfClass:[UMM2PAState_OutOfService class]])
        {
            /* we are still in OOS so we have FOOS set */
            [_state sendLinkstateOutOfService:YES];
        }
        else if([_state isKindOfClass:[UMM2PAState_InitialAlignment class]])
        {
            [_state sendLinkstateAlignment:YES];
        }
    }
    @catch(NSException *e)
    {
            [self logMajorError:[NSString stringWithFormat:@"Exception %@",e]];
    }
    @finally
    {
        UMMUTEX_UNLOCK(_controlLock);
    }
}

- (void)stop
{
#if defined(POWER_DEBUG)
    NSLog(@"stop called for m2pa %@. Queuing task",_layerName);
#endif

    UMMUTEX_LOCK(_controlLock);
    @try
    {
        _stopCounter++;
        self.state = [_state eventStop];
    }
    @catch(NSException *e)
    {
        [self logMajorError:[NSString stringWithFormat:@"Exception %@",e]];
    }
    @finally
    {
        UMMUTEX_UNLOCK(_controlLock);
    }
}

+ (NSString *)linkStatusString:(M2PA_linkstate_message) linkstate
{
    switch(linkstate)
    {
        case M2PA_LINKSTATE_ALIGNMENT:
            return @"ALIGNMENT (SIO)";
            break;
        case M2PA_LINKSTATE_PROVING_NORMAL:
            return @"PROVING_NORMAL (SIN)";
            break;
        case M2PA_LINKSTATE_PROVING_EMERGENCY:
            return @"PROVING_EMERGENCY (SIE)";
            break;
        case M2PA_LINKSTATE_READY:
            return @"READY (FISU)";
            break;
        case M2PA_LINKSTATE_PROCESSOR_OUTAGE:
            return @"PROCESSOR_OUTAGE";
            break;
        case M2PA_LINKSTATE_PROCESSOR_RECOVERED:
            return @"PROCESSOR_RECOVERED";
            break;
        case M2PA_LINKSTATE_BUSY:
            return @"BUSY";
            break;
        case M2PA_LINKSTATE_BUSY_ENDED:
            return @"BUSY_ENDED";
            break;
        case M2PA_LINKSTATE_OUT_OF_SERVICE:
            return @"OUT_OF_SERVICE (SIOS)";
            break;
        default:
            return @"UNKNOWN";
            break;
    }
}

+ (NSString *)m2paStatusString:(M2PA_Status) linkstate
{
    switch(linkstate)
    {
        case M2PA_STATUS_FOOS:
            return @"FORCED-OUT-OF-SERVICE";
            break;
        case M2PA_STATUS_DISCONNECTED:
            return @"DISCONNECTED";
            break;
        case M2PA_STATUS_OFF:
            return @"OFF";
            break;
        case M2PA_STATUS_OOS:
            return @"OOS";
            break;
        case M2PA_STATUS_INITIAL_ALIGNMENT:
            return @"INITIAL-ALIGNMENT";
            break;
        case M2PA_STATUS_ALIGNED_NOT_READY:
            return @"ALIGNED-NOT-READY";
            break;
        case M2PA_STATUS_ALIGNED_READY:
            return @"ALIGNED-READY";
            break;
        case M2PA_STATUS_IS:
            return @"IN-SERVICE";
            break;
        default:
            return @"UNKNOWN";
            break;
    }
}

- (int)sendLinkstatus:(M2PA_linkstate_message)linkstate synchronous:(BOOL)sync
{
    /* we can not send linkstat messages while control is occuring as the state might change */
    UMMUTEX_LOCK(_controlLock);
    @autoreleasepool
    {
        NSString *ls = [UMLayerM2PA linkStatusString:linkstate];
        switch(self.sctp_status)
        {

            case UMSOCKET_STATUS_OFF:
                [self logDebug:[NSString stringWithFormat:@"Can not send %@ due to UMSOCKET_STATUS_OFF",ls ]];
                NSLog(@"sctp_status=%d",_sctp_status);
                NSLog(@"sync=%d",sync ? 1 : 0);
                NSLog(@"sctpLink.status=%d",_sctpLink.status);
                NSLog(@"m2pa.state=%@ (%d) %@",self.stateString,self.stateCode,_state.description);
                usleep(100000); /* sleep 0.1 sec */
                return -1;
            case UMSOCKET_STATUS_OOS:
                [self logDebug:[NSString stringWithFormat:@"Can not send %@ due to UMSOCKET_STATUS_OOS",ls ]];
                usleep(0.1);
                return -2;
            case UMSOCKET_STATUS_FOOS:
                [self logDebug:[NSString stringWithFormat:@"Can not send %@ due to UMSOCKET_STATUS_FOOS",ls ]];
                usleep(0.1);
                return -3;
            
            case UMSOCKET_STATUS_LISTENING:
                [self logDebug:[NSString stringWithFormat:@"Can not send %@ due to UMSOCKET_STATUS_LISTENING",ls ]];
                usleep(0.1);
                return -4;

            case UMSOCKET_STATUS_IS:
            default:
                break;
        }
        if(_logLevel<=UMLOG_DEBUG)
        {
            [self logDebug:[NSString stringWithFormat:@"Sending Linkstatus %@",ls ]];
        }

    #define	M2PA_LINKSTATE_PACKETLEN	20
        if(linkstate == M2PA_LINKSTATE_READY)
        {
            _ready_sent++;
        }
        unsigned char m2pa_header[M2PA_LINKSTATE_PACKETLEN];
        
        m2pa_header[0]  = M2PA_VERSION1; /* version field */
        m2pa_header[1]  = 0; /* spare field */
        m2pa_header[2]  = M2PA_CLASS_RFC4165; /* m2pa_message_class;*/
        m2pa_header[3]  = M2PA_TYPE_LINK_STATUS; /*m2pa_message_type;*/
        m2pa_header[4]  = (M2PA_LINKSTATE_PACKETLEN >> 24)& 0xFF;
        m2pa_header[5]  = (M2PA_LINKSTATE_PACKETLEN >> 16)& 0xFF;
        m2pa_header[6]  = (M2PA_LINKSTATE_PACKETLEN >> 8)& 0xFF;
        m2pa_header[7]  = (M2PA_LINKSTATE_PACKETLEN >> 0)& 0xFF;
        m2pa_header[8]  = 0x00;
        m2pa_header[9]  = 0xFF;
        m2pa_header[10] = 0xFF;
        m2pa_header[11] = 0xFF;
        m2pa_header[12] = 0x00;
        m2pa_header[13] = 0xFF;
        m2pa_header[14] = 0xFF;
        m2pa_header[15] = 0xFF;
        m2pa_header[16] = (linkstate >> 24) & 0xFF;
        m2pa_header[17] = (linkstate >> 16) & 0xFF;
        m2pa_header[18] = (linkstate >> 8) & 0xFF;
        m2pa_header[19] = (linkstate >> 0) & 0xFF;

        NSData *data = [NSData dataWithBytes:m2pa_header length:M2PA_LINKSTATE_PACKETLEN];
        
        if(self.logLevel <= UMLOG_DEBUG)
        {
            [self logDebug:[NSString stringWithFormat:@"Sending %@",ls]];
            //mm_m2pa_header_dump13(link,data);
        }
        [_sctpLink dataFor:self
                      data:data
                  streamId:M2PA_STREAM_LINKSTATE
                protocolId:SCTP_PROTOCOL_IDENTIFIER_M2PA
                ackRequest:NULL
               synchronous:sync];
    }
    UMMUTEX_UNLOCK(_controlLock);
    return 0;
}

#pragma mark -
#pragma mark Config Handling

-(void)rcStart
{
    _receptionEnabled=YES;
}

- (void)rcStop
{
    _receptionEnabled=NO;

}

-(void)doStop
{
    
}

-(void)cancelProcessorOutage
{
    self.local_processor_outage = NO;
    self.remote_processor_outage = NO;
}

-(void)cancelLocalProcessorOutage
{
    self.local_processor_outage = NO;
}

-(void)txcStart
{
    
}

- (void)notifyMtp3Disconnected
{
    @autoreleasepool
    {
        NSArray *usrs = [_users arrayCopy];
        for(UMLayerM2PAUser *u in usrs)
        {
            if([u.profile wantsM2PALinkstateMessages])
            {
                [u.user m2paStatusIndication:self
                                         slc:_slc
                                      userId:u.linkName
                                      status:M2PA_STATUS_DISCONNECTED];
            }
        }
    }
}

- (void)notifyMtp3Off
{
    @autoreleasepool
    {
        NSArray *usrs = [_users arrayCopy];
        for(UMLayerM2PAUser *u in usrs)
        {
            if([u.profile wantsM2PALinkstateMessages])
            {
                [u.user m2paStatusIndication:self
                                         slc:_slc
                                      userId:u.linkName
                                      status:M2PA_STATUS_OFF];
            }
        }
    }
}

- (void)notifyMtp3:(M2PA_Status)status async:(BOOL)async;
{
    @autoreleasepool
    {
        NSArray *usrs = [_users arrayCopy];
        for(UMLayerM2PAUser *u in usrs)
        {
            if([u.profile wantsM2PALinkstateMessages])
            {
                [u.user m2paStatusIndication:self
                                         slc:_slc
                                      userId:u.linkName
                                      status:status
                                       async:async];
            }
        }
    }
}

- (void)notifyMtp3OutOfService
{
    [self notifyMtp3:M2PA_STATUS_OOS async:YES];
}

- (void)notifyMtp3Stop
{
    [self notifyMtp3:M2PA_STATUS_OFF async:NO];
}

-(void)notifyMtp3RemoteProcessorOutage
{
    @autoreleasepool
    {
        NSArray *usrs = [_users arrayCopy];
        for(UMLayerM2PAUser *u in usrs)
        {
            if([u.profile wantsM2PALinkstateMessages])
            {
                [u.user m2paProcessorOutage:self slc:_slc userId:u.linkName];
            }
        }
    }
}

-(void)notifyMtp3RemoteProcessorRecovered
{
    @autoreleasepool
    {
        NSArray *usrs = [_users arrayCopy];
        for(UMLayerM2PAUser *u in usrs)
        {
            if([u.profile wantsM2PALinkstateMessages])
            {
                [u.user m2paProcessorRestored:self slc:_slc userId:u.linkName];
            }
        }
    }
}

-(void) notifyMtp3InService
{
    [self notifyMtp3:M2PA_STATUS_IS async:YES];
}

#pragma mark -
#pragma mark Config Handling

- (NSDictionary *)config
{
    NSMutableDictionary *config = [[NSMutableDictionary alloc]init];
    [self addLayerConfig:config];
    config[@"attach-to"] = _sctpLink.layerName;
    config[@"window-size"] = @(_window_size);
    config[@"speed"] = @(_speed);
    config[@"t1"] =@(_t1.seconds);
    config[@"t1r"] =@(_t1r.seconds);
    config[@"t2"] =@(_t2.seconds);
    config[@"t3"] =@(_t3.seconds);
    config[@"t4e"] =@(_t4e);
    config[@"t4n"] =@(_t4n);
    config[@"t4r"] =@(_t4r.seconds);
    config[@"t5"] =@(_t5.seconds);
    config[@"t6"] =@(_t6.seconds);
    config[@"t7"] =@(_t7.seconds);
    config[@"ack-timer"] =@(_ackTimer.seconds);
    return config;
}

- (void)setConfig:(NSDictionary *)cfg applicationContext:(id)appContext
{
    @autoreleasepool
    {
        [self readLayerConfig:cfg];

        if(cfg[@"name"])
        {
            self.layerName = [cfg[@"name"] stringValue];
        }
        if(cfg[@"attach-to"])
        {
            NSString *attachTo =  [cfg[@"attach-to"] stringValue];
            _sctpLink = [appContext getSCTP:attachTo];
            if(_sctpLink == NULL)
            {
                NSString *s = [NSString stringWithFormat:@"Can not find sctp layer '%@' referred from m2pa layer '%@'",attachTo,self.layerName];
                @throw([NSException exceptionWithName:[NSString stringWithFormat:@"CONFIG_ERROR FILE %s line:%ld",__FILE__,(long)__LINE__]
                                               reason:s
                                             userInfo:NULL]);
            }
        }
        if(cfg[@"window-size"])
        {
            _window_size = [cfg[@"window-size"] intValue];
        }
        if (cfg[@"speed"])
        {
            _speed = [cfg[@"speed"] doubleValue];
        }
        if (cfg[@"t1"])
        {
            _t1.seconds = [cfg[@"t1"] doubleValue];
        }
        if (cfg[@"t1r"])
        {
            _t1r.seconds = [cfg[@"t1r"] doubleValue];
        }
        if (cfg[@"t2"])
        {
            _t2.seconds = [cfg[@"t2"] doubleValue];
        }
        if (cfg[@"t3"])
        {
            _t3.seconds = [cfg[@"t3"] doubleValue];
        }
        if (cfg[@"t4e"])
        {
            _t4e = [cfg[@"t4e"] doubleValue];
        }
        if (cfg[@"t4n"])
        {
            _t4n = [cfg[@"t4n"] doubleValue];
        }
        if (cfg[@"t4r"])
        {
            _t4r.seconds = [cfg[@"t4r"] doubleValue];
        }
        if (cfg[@"t5"])
        {
            _t5.seconds = [cfg[@"t5"] doubleValue];
        }
        if (cfg[@"t6"])
        {
            _t6.seconds = [cfg[@"t6"] doubleValue];
        }
        if (cfg[@"t7"])
        {
            _t7.seconds = [cfg[@"t7"] doubleValue];
        }
        if (cfg[@"ack-timer"])
        {
            _ackTimer.seconds = [cfg[@"ack-timer"] doubleValue];
            if(_ackTimer.seconds == 0)
            {
                _useAckTimer = NO;
            }
            else
            {
                _useAckTimer = YES;
            }
        }

        if(cfg[@"state-machine-log"])
        {
            NSString *fileName = [cfg[@"state-machine-log"] stringValue];
            UMLogDestination *dst = [[UMLogFile alloc]initWithFileName:fileName];
            if(dst)
            {
                dst.level = UMLOG_DEBUG;
                UMLogHandler *handler = [[UMLogHandler alloc]init];
                [handler addLogDestination:dst];
                _stateMachineLogFeed = [[UMLogFeed alloc]initWithHandler:handler section:@"m2pa-state-machine"];
            }
        }
        [self adminAttachOrder:_sctpLink];
    }
}

static NSDateFormatter *dateFormatter = NULL;

- (NSDictionary *)apiStatus
{
    @autoreleasepool
    {

        NSMutableDictionary *d = [[NSMutableDictionary alloc]init];
        
        d[@"name"] = self.layerName;
        d[@"state"] = [_state description];
        d[@"attach-to"] = _sctpLink.layerName;
        d[@"local-processor-outage"] = _local_processor_outage ? @(YES) : @(NO);
        d[@"remote-processor-outage"] = _remote_processor_outage ? @(YES) : @(NO);
        d[@"level3-indication"] = _level3Indication ? @(YES) : @(NO);
        d[@"slc"] = @(_slc);
        d[@"bsn-tx"] = @(_lastTxBsn);
        d[@"fsn-tx"] = @(_lastTxFsn);
        d[@"bsn-rx"] = @(_lastRxBsn);
        d[@"outstanding"] = @(_outstanding);
        d[@"congested"] = _congested ? @(YES) : @(NO);
        d[@"emergency"] = _emergency ? @(YES) : @(NO);
        d[@"paused"] = _paused ? @(YES) : @(NO);
        d[@"link-restarts"] = @(_link_restarts);
        d[@"ready-received"] = @(_linkstateReadyReceived);
        d[@"ready-sent"] = @(_ready_sent);
        d[@"reception-enabled"] = _receptionEnabled ? @(YES) : @(NO);
        d[@"configured-speed"] = @(_speed);
        d[@"window-size"] = @(_window_size);
        d[@"current-speed-tx-packets"]  =   [_outboundThroughputPackets getSpeedTripleJson];
        d[@"current-speed-tx-bytes"]    =   [_outboundThroughputBytes getSpeedTripleJson];
        d[@"current-speed-rx-packets"]  =   [_inboundThroughputPackets getSpeedTripleJson];
        d[@"current-speed-rx-bytes"]    =   [_inboundThroughputBytes getSpeedTripleJson];
        d[@"submission-speed"]          =   [_submission_speed getSpeedTripleJson];

        if(dateFormatter==NULL)
        {
            dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
            [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
            [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSSSSS"];
        }
        if(_link_up_time)
        {
            d[@"link-up-time"] =  [dateFormatter stringFromDate:_link_up_time];
        }
        if(_link_down_time)
        {
            d[@"link-down-time"] =  [dateFormatter stringFromDate:_link_down_time];
        }
        if(_link_congestion_time)
        {
            d[@"link-congestion-time"] =  [dateFormatter stringFromDate:_link_congestion_time];
        }
        if(_link_congestion_cleared_time)
        {
            d[@"link-congestion-cleared-time"] =  [dateFormatter stringFromDate:_link_congestion_cleared_time];
        }
        if(_link_speed_excess_time)
        {
            d[@"link-speed-excess-time"] =  [dateFormatter stringFromDate:_link_speed_excess_time];
        }
        if(_link_speed_excess_cleared_time)
        {
            d[@"link-speed-excess-cleared-time"] =  [dateFormatter stringFromDate:_link_speed_excess_cleared_time];
        }
        if(_speed_status == SPEED_WITHIN_LIMIT)
        {
            d[@"speed-status"] = @"within-limit";
        }
        else
        {
            d[@"speed-status"] = @"speed-exceeded";
        }
        d[@"waiting-messages-count"] = @(_waitingMessages.count);
        return d;
    }
}

- (void)stopDetachAndDestroy
{
    /* FIXME: do something here */
}

- (UMSynchronizedSortedDictionary *)m2paStatusDict
{
    UMSynchronizedSortedDictionary *dict = [[UMSynchronizedSortedDictionary alloc]init];
    dict[@"name"] = self.layerName;
    dict[@"state.link.name"]  = _state.link.layerName;
    dict[@"state.statusCode"] = @(_state.statusCode);
    dict[@"state.class"] = [_state className];
    switch(_state.statusCode)
    {
        case M2PA_STATUS_FOOS:
            dict[@"state.description"] = @"M2PA_STATUS_FOOS";
            break;
        case M2PA_STATUS_DISCONNECTED:
            dict[@"state.description"] = @"M2PA_STATUS_DISCONNECTED";
            break;
        case M2PA_STATUS_OFF:
            dict[@"state.description"] = @"M2PA_STATUS_OFF";
            break;
        case M2PA_STATUS_OOS:
            dict[@"state.description"] = @"M2PA_STATUS_OOS";
            break;
        case M2PA_STATUS_INITIAL_ALIGNMENT:
            dict[@"state.description"] = @"M2PA_STATUS_INITIAL_ALIGNMENT";
            break;
        case M2PA_STATUS_ALIGNED_NOT_READY:
            dict[@"state.description"] = @"M2PA_STATUS_ALIGNED_NOT_READY";
            break;
        case M2PA_STATUS_ALIGNED_READY:
            dict[@"state.description"] = @"M2PA_STATUS_ALIGNED_READY";
            break;
        case M2PA_STATUS_IS:
            dict[@"state.description"] = @"M2PA_STATUS_IS";
            break;
        default:
            dict[@"state.description"] = @"M2PA_STATUS_INVALID";
            break;
    }
    switch(_sctp_status)
    {
        case UMSOCKET_STATUS_FOOS:
            dict[@"sctp-socket-status"] = @"UMSOCKET_STATUS_FOOS";
            break;
        case UMSOCKET_STATUS_OFF:
            dict[@"sctp-socket-status"] = @"UMSOCKET_STATUS_OFF";
            break;
        case UMSOCKET_STATUS_OOS:
            dict[@"sctp-socket-status"] = @"UMSOCKET_STATUS_OOS";
            break;
        case UMSOCKET_STATUS_IS:
            dict[@"sctp-socket-status"] = @"UMSOCKET_STATUS_IS";
            break;
        case UMSOCKET_STATUS_LISTENING:
            dict[@"sctp-socket-status"] = @"UMSOCKET_STATUS_LISTENING";
            break;
    }
    if(_sctpLink.status != _sctp_status)
    {
        dict[@"sctp-status-mismatch"] = @(YES);
        switch(_sctpLink.status)
        {
            case UMSOCKET_STATUS_FOOS:
                dict[@"sctp.socket-status"] = @"UMSOCKET_STATUS_FOOS";
                break;
            case UMSOCKET_STATUS_OFF:
                dict[@"sctp.socket-status"] = @"UMSOCKET_STATUS_OFF";
                break;
            case UMSOCKET_STATUS_OOS:
                dict[@"sctp.socket-status"] = @"UMSOCKET_STATUS_OOS";
                break;
            case UMSOCKET_STATUS_IS:
                dict[@"sctp.socket-status"] = @"UMSOCKET_STATUS_IS";
                break;
            case UMSOCKET_STATUS_LISTENING:
                dict[@"sctp.socket-status"] = @"UMSOCKET_STATUS_LISTENING";
                break;
        }
    }
    dict[@"linkstate-busy"] = @(_linkstate_busy);
    dict[@"congested"] = @(_congested);
    dict[@"emergency"] = @(_emergency);
    dict[@"local-processor-outage"] = @(_remote_processor_outage);
    dict[@"remote-processor-outage"] = @(_remote_processor_outage);
    dict[@"slc"] = @(_slc);
    dict[@"forced-out-of-service"] = @(_forcedOutOfService);
    dict[@"last-rx-fsn"] = @(_lastRxFsn);
    dict[@"last-rx-bsn"] = @(_lastRxBsn);
    dict[@"last-tx-fsn"] = @(_lastTxFsn);
    dict[@"last-tx-bsn"] = @(_lastTxBsn);
    dict[@"t4n"] = @(_t4n);
    dict[@"t4e"] = @(_t4e);
    dict[@"sctp"] = _sctpLink.layerName;

    dict[@"t1"] = [_t1 timerDescription];
    dict[@"t1r"] = [_t1r timerDescription];
    dict[@"t2"] = [_t2 timerDescription];
    dict[@"t3"] = [_t3 timerDescription];
    dict[@"t4"] = [_t4 timerDescription];
    dict[@"t4r"] = [_t4r timerDescription];
    dict[@"t5"] = [_t5 timerDescription];
    dict[@"t6"] = [_t6 timerDescription];
    dict[@"t7"] = [_t7 timerDescription];

    dict[@"t16"] = [_t16 timerDescription];
    dict[@"t17"] = [_t17 timerDescription];
    dict[@"t18"] = [_t18 timerDescription];

    dict[@"use-ack-timer"] = @(_useAckTimer);
    dict[@"ack-timer"] = [_ackTimer timerDescription];
    dict[@"start-timer"] = [_startTimer timerDescription];
    dict[@"speed"] = @(_speed);
    dict[@"paused"] = @(_paused);
    dict[@"further-proving"] = @(_furtherProving);
    dict[@"reception-enabled"] = @(_receptionEnabled);
    dict[@"window-size"] = @(_window_size);
    switch(_pocStatus)
    {
        case PocStatus_idle:
            dict[@"poc-status"] = @"PocStatus_idle";
            break;
        case PocStatus_inService:
            dict[@"poc-status"] = @"PocStatus_inService";
            break;
        default:
            dict[@"poc-status"] = @"invalid";
            break;
    }
    dict[@"window-size"] = @(_window_size);
    if(_link_down_time)
    {
        dict[@"link-down-time"] = _link_down_time;
    }
    if(_link_congestion_time)
    {
        dict[@"link-congestion-time"] = _link_congestion_time;
    }
    if(_link_speed_excess_time)
    {
        dict[@"link-speed-excess-time"] = _link_speed_excess_time;
    }
    if(_link_congestion_cleared_time)
    {
        dict[@"link-congestion-cleared-time"] = _link_congestion_cleared_time;
    }
    if(_link_speed_excess_cleared_time)
    {
        dict[@"link-speed-excess-cleared-time"] = _link_speed_excess_cleared_time;
    }
    dict[@"submission-speed"] = [_submission_speed getSpeedTripleJson];
    dict[@"inbound-throughput-packets"] = [_inboundThroughputPackets getSpeedTripleJson];
    dict[@"outbound-throughput-packets"] = [_outboundThroughputPackets getSpeedTripleJson];
    dict[@"inbound-throughput-bytes"] = [_inboundThroughputBytes getSpeedTripleJson];
    dict[@"outbound-throughput-bytes"] = [_outboundThroughputBytes getSpeedTripleJson];
    dict[@"inbound-throughput-packets"] = [_submission_speed getSpeedTripleJson];

    if(_link_up_time)
    {
        dict[@"link-up-time"] = _link_up_time;
    }
    if(_link_down_time)
    {
        dict[@"link-down-time"] = _link_down_time;
    }
    if(_link_congestion_time)
    {
        dict[@"link-congestion-time"] = _link_congestion_time;
    }
    if(_link_speed_excess_time)
    {
        dict[@"link-speed-excess-time"] = _link_speed_excess_time;
    }
    if(_link_congestion_cleared_time)
    {
        dict[@"link-congestion-cleared-time"] = _link_congestion_cleared_time;
    }
    if(_link_speed_excess_cleared_time)
    {
        dict[@"link-speed-excess-cleared-time"] = _link_speed_excess_cleared_time;
    }
    switch(_speed_status)
    {
        case SPEED_WITHIN_LIMIT:
            dict[@"speed-status"] = @"within-limit";
            break;
        case SPEED_EXCEEDED:
            dict[@"speed-status"] = @"exceeded";
            break;
    }    
    dict[@"last-events"] = [_layerHistory getLogArrayWithDatesAndOrder:YES];
    return dict;
}

@end
