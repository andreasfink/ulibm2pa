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
            _unackedMsu = [[UMSynchronizedDictionary alloc]init];
            _state = [[UMM2PAState_Disconnected alloc]initWithLink:self status:M2PA_STATUS_DISCONNECTED];
            _seqNumLock = [[UMMutex alloc]initWithName:@"seq-num-lock"];
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
                                          object:NULL
                                         seconds:M2PA_DEFAULT_T2
                                            name:@"t2"
                                         repeats:NO
                                 runInForeground:YES];
            _t3 = [[UMTimer alloc]initWithTarget:self selector:@selector(timerFires3) object:NULL seconds:M2PA_DEFAULT_T3 name:@"t3" repeats:NO runInForeground:YES];
            _t4 = [[UMTimer alloc]initWithTarget:self selector:@selector(timerFires4) object:NULL seconds:M2PA_DEFAULT_T4_N name:@"t4" repeats:NO runInForeground:YES];
            _t5 = [[UMTimer alloc]initWithTarget:self selector:@selector(timerFires5) object:NULL seconds:M2PA_DEFAULT_T5 name:@"t5" repeats:NO runInForeground:YES];
            _t6 = [[UMTimer alloc]initWithTarget:self selector:@selector(timerFires6) object:NULL seconds:M2PA_DEFAULT_T6 name:@"t6" repeats:NO runInForeground:YES];
            _t7 = [[UMTimer alloc]initWithTarget:self selector:@selector(timerFires7) object:NULL seconds:M2PA_DEFAULT_T7 name:@"t7" repeats:NO runInForeground:YES];
            _t16 = [[UMTimer alloc]initWithTarget:self selector:@selector(timerFires16) object:NULL seconds:M2PA_DEFAULT_T16 name:@"t16" repeats:NO runInForeground:YES];
            _t17 = [[UMTimer alloc]initWithTarget:self selector:@selector(timerFires17) object:NULL seconds:M2PA_DEFAULT_T17 name:@"t17" repeats:NO runInForeground:YES];
            _t18 = [[UMTimer alloc]initWithTarget:self selector:@selector(timerFires18) object:NULL seconds:M2PA_DEFAULT_T18 name:@"t18" repeats:NO runInForeground:YES];
            _ackTimer = [[UMTimer alloc]initWithTarget:self selector:@selector(ackTimerFires) object:NULL seconds:M2PA_DEFAULT_ACK_TIMER name:@"ack-timer" repeats:NO runInForeground:YES];
            _startTimer = [[UMTimer alloc]initWithTarget:self selector:@selector(startTimerFires) object:NULL seconds:M2PA_DEFAULT_START_TIMER name:@"start-timer" repeats:NO runInForeground:YES];
            _repeatTimer = [[UMTimer alloc]initWithTarget:self selector:@selector(repeatTimerFires) object:NULL seconds:M2PA_DEFAULT_REPEAT_OOS_TIMER name:@"repeat-timer" repeats:YES runInForeground:YES];

            _t4n = M2PA_DEFAULT_T4_N;
            _t4e = M2PA_DEFAULT_T4_E;
            _t4r = M2PA_DEFAULT_T4_R;
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
            }
}

#pragma mark -
#pragma mark SCTP Callbacks


- (void) sctpStatusIndication:(UMLayer *)caller
                       userId:(id)uid
                       status:(UMSocketStatus)s
                       reason:(NSString *)reason
                       socket:(NSNumber *)socketNumber
{
    @autoreleasepool
    {
//#if defined(POWER_DEBUG)
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
//#endif
        UMM2PATask_sctpStatusIndication *task = [[UMM2PATask_sctpStatusIndication alloc]initWithReceiver:self
                                                                                                  sender:caller
                                                                                                  userId:uid
                                                                                                  status:s
                                                                                                  reason:reason
                                                                                                  socket:socketNumber];
        [self queueFromLowerWithPriority:task];
    }
}


- (void) sctpDataIndication:(UMLayer *)caller
                     userId:(id)uid
                   streamId:(uint16_t)sid
                 protocolId:(uint32_t)pid
                       data:(NSData *)d
{
    [self sctpDataIndication:caller
                         userId:uid
                       streamId:sid
                     protocolId:pid
                           data:d
                      socket:NULL];
}

- (void) sctpDataIndication:(UMLayer *)caller
                     userId:(id)uid
                   streamId:(uint16_t)sid
                 protocolId:(uint32_t)pid
                       data:(NSData *)d
                     socket:(NSNumber *)socketNumber
{
    @autoreleasepool
    {
        UMM2PATask_sctpDataIndication *task = [[UMM2PATask_sctpDataIndication alloc]initWithReceiver:self
                                                                                              sender:caller
                                                                                              userId:uid
                                                                                            streamId:sid
                                                                                          protocolId:pid
                                                                                                data:d
                                                                                              socket:socketNumber];
        [self queueFromLower:task];
    }
}

- (void) sctpMonitorIndication:(UMLayer *)caller
                        userId:(id)uid
                      streamId:(uint16_t)sid
                    protocolId:(uint32_t)pid
                          data:(NSData *)d
                      incoming:(BOOL)in
                        socket:(NSNumber *)socketNumber
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
- (void)sctpReportsUp:(NSNumber *)socketNumber
{
    _sctpUpReceived++;
    
    if(([_state isKindOfClass:[UMM2PAState_Disconnected class]])
        ||([_state isKindOfClass:[UMM2PAState_Connecting class]]))
    {
        self.state = [_state eventSctpUp:(NSNumber *)socketNumber];
    }
    if([_state isKindOfClass:[UMM2PAState_OutOfService class]])
    {
        [_state sendLinkstateOutOfService:YES];
        [self start];
    }
}

- (void)sctpReportsDown:(NSNumber *)socketNumber
{
    _sctpDownReceived++;
    self.state = [_state eventSctpDown:socketNumber];
}

- (void) _sctpStatusIndicationTask:(UMM2PATask_sctpStatusIndication *)task
{
    [self setSctp_status:task.status reason:task.reason socketNumber:task.socketNumber];
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
    [self setSctp_status:newStatus reason:reason socketNumber:NULL];
}

- (void)setSctp_status:(UMSocketStatus )newStatus reason:(NSString *)reason socketNumber:(NSNumber *)socketNumber
{
    int old_sctp_status = _sctp_status;
    _sctp_status = newStatus;

    if(_logLevel <=UMLOG_DEBUG)
    {
        NSString *s = [NSString stringWithFormat:@"M2PA: SCTP Status change %@->%@ (%@)",[UMSocket statusDescription:old_sctp_status],    [UMSocket statusDescription:newStatus],reason];
        [self logDebug:s];
    }

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
        [self sctpReportsDown:socketNumber];
        /* this is the job of the state machine now */
        //[_sctpLink openFor:self sendAbortFirst:NO reason:@"sctp-link-died"];
    }
    if( (old_sctp_status != UMSOCKET_STATUS_IS)
    && (_sctp_status == UMSOCKET_STATUS_IS))
    {
        /* SCTP link came up properly. Lets start M2PA now on it */
        [self sctpReportsUp:socketNumber];
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
                [self sctpIncomingLinkstateMessage:task.data socketNumber:task.socketNumber];
            }
            else if((task.streamId == M2PA_STREAM_USERDATA) && (message_type==1))
            {
                [self sctpIncomingDataMessage:task.data socketNumber:task.socketNumber];
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
        [self addToLayerHistoryLog:e];
#if defined(POWER_DEBUG)
        NSLog(@"protocol violation for m2pa %@: %@",_layerName,reason);
#endif
        [self powerOff:e];
    }
}

-(void) protocolViolation
{
    [self protocolViolation:@"PROTOCOL VIOLATION"];
}

- (void) sctpIncomingDataMessage:(NSData *)data socketNumber:(NSNumber *)socketNumber
{
    @autoreleasepool
    {
        [_inboundThroughputPackets increaseBy:1];
        [_inboundThroughputBytes increaseBy:(uint32_t)data.length];
        u_int32_t len;
        const char *dptr;
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
                    [_ackTimer start];
                }
                else
                {
                    [self ackTimerFires];
                }
            }
            NSData *userData = [NSData dataWithBytes:&dptr[16] length:userDataLen];
                        @try
            {
                self.state = [_state eventReceiveUserData:userData socketNumber:socketNumber];
                if([self.state isKindOfClass: [UMM2PAState_InService class]])
                {
                    [self notifyMtp3UserData:userData];
                }
            }
            @catch(NSException *e)
            {
                [self logMajorError:[NSString stringWithFormat:@"Exception %@",e]];
            }
            @finally
            {
                            }
            [_data_link_buffer replaceBytesInRange: NSMakeRange(0,len) withBytes:"" length:0];
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

- (void) sctpIncomingLinkstateMessage:(NSData *)data socketNumber:(NSNumber *)socketNumber
{
    @autoreleasepool
    {
        
        M2PA_linkstate_message linkstatus;
        uint32_t len;
        const char *dptr;

        if(self.logLevel <= UMLOG_DEBUG)
        {
            [self logDebug:[NSString stringWithFormat:@" sctpIncomingLinkstateMessage %@",data.hexString]];
        }
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
                        [self _alignment_received:socketNumber];
                        break;
                    case M2PA_LINKSTATE_PROVING_NORMAL:			/* 2 */
                        [self _proving_normal_received:socketNumber];
                        break;
                    case M2PA_LINKSTATE_PROVING_EMERGENCY:		/* 3 */
                        [self _proving_emergency_received:socketNumber];
                        break;
                    case M2PA_LINKSTATE_READY:					/* 4 */
                        [self _linkstate_ready_received:socketNumber];
                        break;
                    case M2PA_LINKSTATE_PROCESSOR_OUTAGE:		/* 5 */
                        [self _linkstate_processor_outage_received:socketNumber];
                        break;
                    case M2PA_LINKSTATE_PROCESSOR_RECOVERED:	/* 6 */
                        [self _linkstate_processor_recovered_received:socketNumber];
                        break;
                    case M2PA_LINKSTATE_BUSY:					/* 7 */
                        [self _linkstate_busy_received:socketNumber];
                        break;
                    case M2PA_LINKSTATE_BUSY_ENDED:				/* 8 */
                        [self _linkstate_busy_ended_received:socketNumber];
                        break;
                    case M2PA_LINKSTATE_OUT_OF_SERVICE:		/* 9 */
                        /* other side tells us they are out of service. I wil let mtp3 know and have it send us a start */
                        [self _oos_received:socketNumber];
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
                    }
    }
}

- (void) _oos_received:(NSNumber *)socketNumber
{
    _linkstateOutOfServiceReceived++;
    if(_state == NULL)
    {
        _state = [[UMM2PAState_Disconnected alloc]initWithLink:self status:M2PA_STATUS_CONNECTING];
    }
    self.state = [_state eventLinkstatusOutOfService:socketNumber];
}

- (void) _alignment_received:(NSNumber *)socketNumber
{
    self.state = [_state eventLinkstatusAlignment:socketNumber];
    _linkstateAlignmentReceived++;
    _linkstateProvingReceived=0;
    _linkstateProvingSent=0;
}

- (void) _proving_normal_received:(NSNumber *)socketNumber
{
    _linkstateProvingReceived++;
    self.state = [_state eventLinkstatusProvingNormal:socketNumber];
}

- (void) _proving_emergency_received:(NSNumber *)socketNumber
{
        @try
    {
        _linkstateProvingReceived++;
        if(_emergency == NO)
        {
            _emergency = YES;
        }
        self.state = [_state eventLinkstatusProvingEmergency:socketNumber];
    }
    @catch(NSException *e)
    {
        [self logMajorError:[NSString stringWithFormat:@"Exception %@",e]];
    }
    @finally
    {
            }
}

- (void) _linkstate_ready_received:(NSNumber *)socketNumber
{
        @try
    {
        _linkstateReadyReceived++;
        self.state = [_state eventLinkstatusReady:socketNumber];
    }
    @catch(NSException *e)
    {
        [self logMajorError:[NSString stringWithFormat:@"Exception %@",e]];
    }
    @finally
    {
            }
}

- (void) _linkstate_processor_outage_received:(NSNumber *)socketNumber
{
        @try
    {
        _linkstateProcessorOutageReceived++;
        self.state = [_state eventLinkstatusProcessorOutage:socketNumber];
    }
    @catch(NSException *e)
    {
        [self logMajorError:[NSString stringWithFormat:@"Exception %@",e]];
    }
    @finally
    {
            }
}

- (void) _linkstate_processor_recovered_received:(NSNumber *)socketNumber
{
        @try
    {
        _linkstateProcessorRecoveredReceived++;
        self.state = [_state eventLinkstatusProcessorRecovered:socketNumber];
    }
    @catch(NSException *e)
    {
        [self logMajorError:[NSString stringWithFormat:@"Exception %@",e]];
    }
    @finally
    {
            }
}

- (void) _linkstate_busy_received:(NSNumber *)socketNumber
{
        @try
    {
        _linkstateBusyReceived++;
        self.state = [_state eventLinkstatusBusy:socketNumber];
    }
    @catch(NSException *e)
    {
        [self logMajorError:[NSString stringWithFormat:@"Exception %@",e]];
    }
    @finally
    {
            }
}

- (void) _linkstate_busy_ended_received:(NSNumber *)socketNumber
{
        @try
    {
        _linkstateBusyEndedReceived++;

        self.state = [_state eventLinkstatusBusyEnded:socketNumber];
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
            }
    [self sendCongestionClearedIndication];
    if([_waitingMessages count]>0)
    {
        [_t7 start];
    }
}

- (void) linktestTimerReportsFailure
{
    if(_state == NULL)
    {
        _state = [[UMM2PAState_Disconnected alloc]initWithLink:self  status:M2PA_STATUS_DISCONNECTED];
    }
    else
    {
        self.state = [_state eventLinkstatusOutOfService:NULL];
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
    [self queueTimerEvent:NULL timerName:@"t1"];
}

- (void)timerFires1r
{
    [self queueTimerEvent:NULL timerName:@"t1r"];
}

- (void)timerFires2
{
    [self queueTimerEvent:NULL timerName:@"t2"];
}

- (void)repeatTimerFires
{
    [self queueTimerEvent:NULL timerName:@"repeat"];
}

- (void)timerFires3
{
    [self queueTimerEvent:NULL timerName:@"t3"];
}

- (void)timerFires4
{
	[self queueTimerEvent:NULL timerName:@"t4"];
}

- (void)timerFires5
{
	[self queueTimerEvent:NULL timerName:@"t5"];
}
- (void)timerFires6
{
	[self queueTimerEvent:NULL timerName:@"t6"];
}

- (void)timerFires7
{
	[self queueTimerEvent:NULL timerName:@"t7"];
}

- (void)timerFires16
{
    [self queueTimerEvent:NULL timerName:@"t16"];
}

- (void)timerFires17
{
    [self queueTimerEvent:NULL timerName:@"t17"];
}


- (void)timerFires18
{
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
    [self queueTimerEvent:NULL timerName:@"start-timer"];
}

- (void)_startTimer
{
    if(_state.statusCode == M2PA_STATUS_DISCONNECTED)
    {
        [self powerOn];
    }
}

- (void)_timerFires1
{
    self.state = [_state eventTimer1];
}

- (void)_timerFires1r
{
    self.state = [_state eventTimer1r];
}

- (void)_timerFires2
{
    self.state = [_state eventTimer2];
}

- (void)_timerFires3
{
    self.state = [_state eventTimer3];
}

- (void)_timerFires4
{
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
            }
}

- (void)_repeatTimerFires
{
        @try
    {
        self.state = [_state eventRepeatTimer];
    }
    @catch(NSException *e)
    {
        [self logMajorError:[NSString stringWithFormat:@"Exception %@",e]];
    }
    @finally
    {
            }
}

- (void)_timerFires5
{
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
            }
}

- (void)_timerFires6
{
	/* Figure 13/Q.703 (sheet 2 of 7) */
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
            }
}

- (void)_timerFires7
{
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
            }
}

- (void)_timerFires16
{
    self.state = [_state eventTimer16];
}

- (void)_timerFires17
{
    self.state = [_state eventTimer17];
}

- (void)_timerFires18
{
    self.state = [_state eventTimer18];
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
        [self queueFromUpper:task];
    }
}

- (void)powerOnFor:(id<UMLayerM2PAUserProtocol>)caller forced:(BOOL)forced reason:(NSString *)reason
{
    @autoreleasepool
    {
        UMM2PATask_PowerOn *task = [[UMM2PATask_PowerOn alloc]initWithReceiver:self sender:caller];
        task.reason = reason;
        task.forced =forced;
        [self queueFromUpperWithPriority:task];
    }
}


- (void)powerOffFor:(id<UMLayerM2PAUserProtocol>)caller forced:(BOOL)forced reason:(NSString *)reason
{
    @autoreleasepool
    {
#if defined(POWER_DEBUG)
        NSLog(@"powerOffFor called from %@ for m2pa %@ forced:%@",caller.layerName,_layerName,forced ? @"YES" : @"NO");
#endif
        UMM2PATask_PowerOff *task = [[UMM2PATask_PowerOff alloc]initWithReceiver:self sender:caller];
        task.reason = reason;
        task.forced = forced;
        [self queueFromUpperWithPriority:task];
    }
}

- (void)startFor:(id<UMLayerM2PAUserProtocol>)caller forced:(BOOL)forced reason:(NSString *)reason
{
    
    @autoreleasepool
    {
#if defined(POWER_DEBUG)
        NSLog(@"startFor called from %@ for m2pa %@ forced:%@",caller.layerName,_layerName,forced ? @"YES" : @"NO");
#endif
        UMM2PATask_Start *task = [[UMM2PATask_Start alloc]initWithReceiver:self sender:caller];
        task.reason = reason;
        if(forced)
        {
            task.forced = forced;
        }
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
        task.forced = forced;
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
    UMM2PATask_SetSlc *task = [[UMM2PATask_SetSlc alloc]initWithReceiver:self sender:caller slc:xslc];
    [self queueFromUpperWithPriority:task];
}

- (void)queueTimerEvent:(id)caller timerName:(NSString *)tname
{
    UMM2PATask_TimerEvent *task = [[UMM2PATask_TimerEvent alloc]initWithReceiver:self sender:caller timerName:tname];
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

    UMMUTEX_LOCK(_seqNumLock);
    if((_lastTxFsn == FSN_BSN_MASK) || (_lastRxFsn == FSN_BSN_MASK))
    {
        _outstanding = 0;
        _lastRxFsn = _lastTxFsn;
    }
    else
    {
        _outstanding = ((long)_lastTxFsn - (long)_lastRxBsn ) % FSN_BSN_SIZE;
    }
    UMMUTEX_UNLOCK(_seqNumLock);

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
                ackRequest:ackRequest];
    }
    @catch(NSException *e)
    {
        [self logMajorError:[NSString stringWithFormat:@"Exception: %@",e]];
    }
}

- (void)sendEmptyUserDataPacket
{
    uint16_t    streamId = M2PA_STREAM_USERDATA;

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
            ackRequest:NULL];
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
        [_state eventSendUserData:mtp3_data
                       ackRequest:task.ackRequest
                              dpc:task.dpc];
    }
}

- (void) resetSequenceNumbers
{
    UMMUTEX_LOCK(_seqNumLock);
    _lastTxFsn = 0x00FFFFFF; /* last sent FSN */
    _lastTxBsn = 0x00FFFFFF; /* last received FSN, next BSN to send. */
    _lastRxBsn = 0x00FFFFFF; /* last received bsn */
    UMMUTEX_UNLOCK(_seqNumLock);
}

- (void)_powerOnTask:(UMM2PATask_PowerOn *)task
{
    [self resetSequenceNumbers];
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"powerOn"];
    }
    if(task.forced)
    {
        _forcedOutOfService = NO;
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

    if(task.forced)
    {
        _forcedOutOfService = YES;
    }
    NSString *s = [NSString stringWithFormat:@"powerOff requested-from-mtp3 (%@)", task.reason ? task.reason : @""];
    [self powerOff:s];
}

- (void)_startTask:(UMM2PATask_Start *)task
{
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"start"];
    }
    if(task.forced)
    {
        _forcedOutOfService = NO;
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
        @try
    {
        NSString *timerName = task.timerName;
        if([timerName isEqualToString:@"t1"])
        {
            [self _timerFires1];
        }
        else if([timerName isEqualToString:@"t1r"])
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
        else if([timerName isEqualToString:@"repeat"])
        {
            [self _repeatTimerFires];
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
        else     if([timerName isEqualToString:@"t16"])
        {
            [self _timerFires16];
        }
        else     if([timerName isEqualToString:@"t17"])
        {
            [self _timerFires17];
        }
        else     if([timerName isEqualToString:@"t18"])
        {
            [self _timerFires18];
        }
        else     if([timerName isEqualToString:@"start-timer"])
        {
            [self _startTimer];
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
    _powerOnCounter++;
    self.state = [[UMM2PAState_Disconnected alloc]initWithLink:self  status:M2PA_STATUS_DISCONNECTED];
    self.state = [_state eventPowerOn];
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
            }
}

- (void)start
{
#if defined(POWER_DEBUG)
    NSLog(@"start called for m2pa %@. Queuing task",_layerName);
#endif

        @try
    {
        _startCounter++;
        self.state = [_state eventStart];
    }
    @catch(NSException *e)
    {
        [self logMajorError:[NSString stringWithFormat:@"Exception %@",e]];
    }
    @finally
    {
            }
}

- (void)stop
{
#if defined(POWER_DEBUG)
    NSLog(@"stop called for m2pa %@. Queuing task",_layerName);
#endif

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
        case M2PA_STATUS_CONNECTING:
            return @"CONNECTING";
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
    @autoreleasepool
    {
        NSString *ls = [UMLayerM2PA linkStatusString:linkstate];
        NSLog(@"sendLinkstatus:%@ sync:%@",ls,sync ? @"YES" : @"NO");
        switch(self.sctp_status)
        {
            case UMSOCKET_STATUS_OFF:
            {
                NSString *s = [NSString stringWithFormat:@"Can not send %@ due to UMSOCKET_STATUS_OFF",ls];
                [self logDebug:s];
                [self addToLayerHistoryLog:s];
                usleep(100000); /* sleep 0.1 sec */
                return -1;
            }
            case UMSOCKET_STATUS_OOS:
            {
                NSString *s = [NSString stringWithFormat:@"Can not send %@ due to UMSOCKET_STATUS_OOS",ls ];
                [self logDebug:s];
                [self addToLayerHistoryLog:s];
                usleep(100000);
                return -2;
            }
            case UMSOCKET_STATUS_FOOS:
            {
                NSString *s = [NSString stringWithFormat:@"Can not send %@ due to UMSOCKET_STATUS_FOOS",ls ];
                [self logDebug:s];
                [self addToLayerHistoryLog:s];
                usleep(100000);
                return -3;
            }
            case UMSOCKET_STATUS_LISTENING:
            {
                NSString *s = [NSString stringWithFormat:@"Can not send %@ due to UMSOCKET_STATUS_LISTENING",ls ];
                [self logDebug:s];
                [self addToLayerHistoryLog:s];
                usleep(100000);
                return -4;
            }
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
            [self logDebug:[NSString stringWithFormat:@"Sending %@ (%@)",ls,data.hexString]];
        }
        NSAssert(_sctpLink !=NULL,@"SCTP Link is NULL?!?");

        [_sctpLink dataFor:self
                      data:data
                  streamId:M2PA_STREAM_LINKSTATE
                protocolId:SCTP_PROTOCOL_IDENTIFIER_M2PA
                ackRequest:NULL
               synchronous:sync];
        
        if(_logLevel<=UMLOG_DEBUG)
        {
            UMSocketSCTP *s = _sctpLink.directSocket;
            if(s==NULL)
            {
                [self addToLayerHistoryLog:@"_sctpLink.directSocket is NULL"];
            }
            else
            {
                [self addToLayerHistoryLog:[NSString stringWithFormat:@"_sctpLink.directSocket.sock is %d",s.sock]];
                [self addToLayerHistoryLog:[NSString stringWithFormat:@"_sctpLink.directSocket.status is %d",s.status]];
            }
        }
    }
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


- (void)notifyMtp3:(M2PA_Status)status
{
    @autoreleasepool
    {
        if(_lastNotifiedStatus!=status)
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
                                           async:YES];
                }
            }
        }
        _lastNotifiedStatus = status;
    }
}

- (void)notifyMtp3Disconnected
{
    [self notifyMtp3:M2PA_STATUS_DISCONNECTED];
}

- (void)notifyMtp3Connecting
{
    [self notifyMtp3:M2PA_STATUS_CONNECTING];
}

- (void)notifyMtp3OutOfService
{
    [self notifyMtp3:M2PA_STATUS_OOS];
}

-(void)notifyMtp3InitialAlignment
{
    [self notifyMtp3:M2PA_STATUS_INITIAL_ALIGNMENT];
}

-(void)notifyMtp3AlignedNotReady
{
    [self notifyMtp3:M2PA_STATUS_ALIGNED_NOT_READY];
}
-(void)notifyMtp3AlignedReady
{
    [self notifyMtp3:M2PA_STATUS_ALIGNED_READY];
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
    [self notifyMtp3:M2PA_STATUS_IS];
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
    config[@"t4r"] =@(_t4r);
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
            _t4r = [cfg[@"t4r"] doubleValue];
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
        case M2PA_STATUS_CONNECTING:
            dict[@"state.description"] = @"M2PA_STATUS_CONNECTING";
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
    dict[@"t5"] = [_t5 timerDescription];
    dict[@"t6"] = [_t6 timerDescription];
    dict[@"t7"] = [_t7 timerDescription];
    dict[@"t16"] = [_t16 timerDescription];
    dict[@"t17"] = [_t17 timerDescription];

    dict[@"repeat_timer"] = [_repeatTimer timerDescription];
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
