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

#import "UMM2PALinkStateControl_AllStates.h"
#import "UMM2PAInitialAlignmentControl_AllStates.h"

#define IAC_ASSIGN_AND_LOG(oldstatus,newstatus) \
{ \
	UMM2PAInitialAlignmentControl_State *n = newstatus;\
	if((oldstatus != n) && (self.logLevel <= UMLOG_DEBUG)) \
	{ \
		if(![oldstatus.description isEqualToString: n.description]); \
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
		if(![oldstatus.description isEqualToString: n.description]); \
		{ \
			[self.logFeed debugText:[NSString stringWithFormat:@"LSC Status change %@->%@",oldstatus.description, n.description]]; \
		} \
		oldstatus = n; \
	} \
}


@implementation UMLayerM2PA

#pragma mark -
#pragma mark Initializer


+ (NSString *)statusAsString:(M2PA_Status)s
{
    switch(s)
    {
        case  M2PA_STATUS_UNUSED:
            return @"M2PA_STATUS_UNUSED";
        case M2PA_STATUS_OFF:
            return @"M2PA_STATUS_OFF";
        case M2PA_STATUS_OOS:
            return @"M2PA_STATUS_OOS";
        case M2PA_STATUS_INITIAL_ALIGNMENT:
            return @"M2PA_STATUS_INITIAL_ALIGNMENT";
        case M2PA_STATUS_ALIGNED_NOT_READY:
            return @"M2PA_STATUS_ALIGNED_NOT_READY";
        case M2PA_STATUS_ALIGNED_READY:
            return @"M2PA_STATUS_ALIGNED_READY";
        case M2PA_STATUS_IS:
            return @"M2PA_STATUS_IS";
    }
    return @"M2PA_STATUS_INVALID";
}

-(M2PA_Status)m2pa_status
{
    return _m2pa_status;
}

- (void)setM2pa_status:(M2PA_Status)status
{
    M2PA_Status old_status = _m2pa_status;

    if(old_status == status)
    {
        return;
    }
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:
         [NSString stringWithFormat: @"STATUS CHANGE: %@ -> %@",
          [UMLayerM2PA statusAsString:old_status],
          [UMLayerM2PA statusAsString:status]]];
    }
    _m2pa_status = status;

    if((old_status != M2PA_STATUS_IS)
       && (status == M2PA_STATUS_IS))
    {
        _link_restarts++;
		_link_up_time = [NSDate date];
    }

    if((old_status == M2PA_STATUS_IS)
       && (status != M2PA_STATUS_IS))
    {
        _link_down_time = [NSDate date];
    }

    NSMutableArray *a = [[NSMutableArray alloc]init];
    NSArray *usrs = [_users arrayCopy];

    /* we should pass service indicator /network indicator /user info back too? */
    for(UMLayerM2PAUser *u in usrs)
    {
        if([u.profile wantsM2PALinkstateMessages])
        {
            [a addObject:u];
        }
    }

    for(UMLayerM2PAUser *u in a)
    {
        [u.user m2paStatusIndication:self
                                 slc:_slc
                              userId:u.userId
                              status:_m2pa_status];
    }
}

- (UMLayerM2PA *)init
{
    @throw([NSException exceptionWithName:@"INVALID_INIT" reason:@"UMLayerM2PA must be initialized via initWithTaskQueueMulti" userInfo:NULL]);
}

- (UMLayerM2PA *)initWithTaskQueueMulti:(UMTaskQueueMulti *)tq
{
    return [self initWithTaskQueueMulti:tq name:@""];
}

- (UMLayerM2PA *)initWithTaskQueueMulti:(UMTaskQueueMulti *)tq name:(NSString *)name
{
    self = [super initWithTaskQueueMulti:tq name:name];
    if(self)
    {
        _users = [[UMSynchronizedArray alloc] init];
        _seqNumLock = [[UMMutex alloc]initWithName:@"m2pa-seq-num-mutex"];
        _dataLock = [[UMMutex alloc]initWithName:@"m2pa-data-mutex"];
        _controlLock = [[UMMutex alloc]initWithName:@"m2pa-control-mutex"];
        _incomingDataBufferLock = [[UMMutex alloc]initWithName:@"m2pa-incoming-data-mutex"];

        _lscState = [[UMM2PALinkStateControl_PowerOff alloc]initWithLink:self];
        _iacState = [[UMM2PAInitialAlignmentControl_Idle alloc] initWithLink:self];
        _slc = 0;
        _emergency = NO;
        _congested = NO;
        _local_processor_outage = NO;
        _remote_processor_outage = NO;
        _sctp_status = SCTP_STATUS_OOS;
        _m2pa_status = M2PA_STATUS_OFF;

        _autostart = NO;
        _link_restarts = NO;
        _ready_received = 0;
        _ready_sent = 0;
        _paused = NO;
        _speed = 0; /* unlimited */
        _window_size = M2PA_DEFAULT_WINDOW_SIZE;
        
        _t1 = [[UMTimer alloc]initWithTarget:self selector:@selector(timerFires1) object:NULL seconds:M2PA_DEFAULT_T1 name:@"t1" repeats:NO];
        _t2 = [[UMTimer alloc]initWithTarget:self selector:@selector(timerFires2) object:NULL seconds:M2PA_DEFAULT_T2 name:@"t2" repeats:NO];
        _t3 = [[UMTimer alloc]initWithTarget:self selector:@selector(timerFires3) object:NULL seconds:M2PA_DEFAULT_T3 name:@"t3" repeats:NO];
        _t4 = [[UMTimer alloc]initWithTarget:self selector:@selector(timerFires4) object:NULL seconds:M2PA_DEFAULT_T4_N name:@"t4" repeats:NO];
        _t4r = [[UMTimer alloc]initWithTarget:self selector:@selector(timerFires4r) object:NULL seconds:M2PA_DEFAULT_T4_R name:@"t4r" repeats:YES];
        _t5 = [[UMTimer alloc]initWithTarget:self selector:@selector(timerFires5) object:NULL seconds:M2PA_DEFAULT_T5 name:@"t5" repeats:NO];
        _t6 = [[UMTimer alloc]initWithTarget:self selector:@selector(timerFires6) object:NULL seconds:M2PA_DEFAULT_T6 name:@"t6" repeats:NO];
        _t7 = [[UMTimer alloc]initWithTarget:self selector:@selector(timerFires7) object:NULL seconds:M2PA_DEFAULT_T7 name:@"t7" repeats:NO];
        
        _t4n = M2PA_DEFAULT_T4_N;
        _t4e = M2PA_DEFAULT_T4_E;
        _speedometer = [[UMThroughputCounter alloc]initWithResolutionInSeconds: 1.0 maxDuration: 1260.0];
        _control_link_buffer = [[NSMutableData alloc] init];
        _data_link_buffer = [[NSMutableData alloc] init];
        _waitingMessages = [[UMQueue alloc]init];

        _inboundThroughputPackets =  [[UMThroughputCounter alloc]initWithResolutionInSeconds: 1.0 maxDuration: 1260.0];
        _outboundThroughputPackets =  [[UMThroughputCounter alloc]initWithResolutionInSeconds: 1.0 maxDuration: 1260.0];
        _inboundThroughputBytes =  [[UMThroughputCounter alloc]initWithResolutionInSeconds: 1.0 maxDuration: 1260.0];
        _outboundThroughputBytes =  [[UMThroughputCounter alloc]initWithResolutionInSeconds: 1.0 maxDuration: 1260.0];

    }
    return self;
}

#pragma mark -
#pragma mark SCTP Callbacks

#pragma mark -
#pragma mark SCTP Callbacks


- (void) sctpStatusIndication:(UMLayer *)caller
                       userId:(id)uid
                       status:(SCTP_Status)s
{
    UMM2PATask_sctpStatusIndication *task = [[UMM2PATask_sctpStatusIndication alloc]initWithReceiver:self
                                                                                              sender:caller
                                                                                              userId:uid
                                                                                              status:s];
    [self queueFromLowerWithPriority:task];
    
}

- (void) sctpDataIndication:(UMLayer *)caller
                     userId:(id)uid
                   streamId:(uint16_t)sid
                 protocolId:(uint32_t)pid
                       data:(NSData *)d
{
    UMM2PATask_sctpDataIndication *task = [[UMM2PATask_sctpDataIndication alloc]initWithReceiver:self
                                                                                          sender:caller
                                                                                          userId:uid
                                                                                        streamId:sid
                                                                                      protocolId:pid
                                                                                            data:d];
    [self queueFromLower:task];
}


- (void) sctpMonitorIndication:(UMLayer *)caller
                        userId:(id)uid
                      streamId:(uint16_t)sid
                    protocolId:(uint32_t)pid
                          data:(NSData *)d
                      incoming:(BOOL)in
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

- (void)sctpReportsUp
{
    /***************************************************************************
     **
     ** m2pa_up
     ** called upon SCTP reporting a association to be up
     ** according to figure 8/Q.703 and RFC4165 page 35
     */
	[_controlLock lock];
    [self logInfo:@"sctpReportsUp"];
    /* send link status out of service to the other side */
    /* this is done in m2pa_start! */
    /* cancel local processor outage */
    _local_processor_outage = NO;
    _remote_processor_outage = NO;
    /* cancel emergency */
    _emergency = NO;
    /* status is now OOS */
    self.m2pa_status = M2PA_STATUS_OOS;
    /* FIXME: we should probably inform MTP3 ? */
    /* we now wait for MTP3 to tell us to start the link */
    [self resetSequenceNumbers];
    _outstanding = 0;
    _ready_received = 0;
    _ready_sent = 0;
    [_speedometer clear];
    [_submission_speed clear];
    _lscState  = [_lscState eventPowerOn:self];
	[_controlLock unlock];

}

- (void)sctpReportsDown
{
	[_controlLock lock];
    [self logInfo:@"sctpReportsDown"];
    self.m2pa_status = M2PA_STATUS_OFF;
    /* we now wait for MTP3 to tell us to start the link again */
    _lscState  = [_lscState eventPowerOff:self];
    _iacState  = [_iacState eventPowerOff:self];
	[_controlLock unlock];
}

- (void) _sctpStatusIndicationTask:(UMM2PATask_sctpStatusIndication *)task
{
    self.sctp_status = task.status;
}

- (SCTP_Status)sctp_status
{
    return _sctp_status;
}

- (void)setSctp_status:(SCTP_Status )newStatus;
{
    int old_sctp_status = _sctp_status;
    _sctp_status = newStatus;
    
    if(old_sctp_status == _sctp_status)
    {
        /* nothing happened we can ignore */
        return;
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
                                          userId:u.userId
                                          status:_sctp_status];
            }
        }
    }

    
    if(	(old_sctp_status == SCTP_STATUS_IS)
       && ((_sctp_status == SCTP_STATUS_OFF)
           || (_sctp_status == SCTP_STATUS_OOS)) )
    {
        /* SCTP Link has died */
        [self sctpReportsDown];
        [_sctpLink openFor:self];
    }
    
    if(((old_sctp_status == SCTP_STATUS_OOS)
        || (old_sctp_status == SCTP_STATUS_OFF))
       && (_sctp_status == SCTP_STATUS_IS))
    {
        /* SCTP link came up properly. Lets start M2PA now on it */
        [self sctpReportsUp];
    }
}

- (void) _sctpDataIndicationTask:(UMM2PATask_sctpDataIndication *)task
{
    NSData *data;
    
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
        [self logMajorError:@"PROTOCOL IDENTIFIER IS NOT M2PA"];
        return;
    }

    switch(task.streamId)
    {
        case M2PA_STREAM_LINKSTATE:
            if(self.logLevel <= UMLOG_DEBUG)
            {
                [self logDebug:@"M2PA_STREAM_LINKSTATE received"];
            }
            data = task.data;
            [self sctpIncomingLinkstateMessage:data];
            break;
        case M2PA_STREAM_USERDATA:
            if(self.logLevel <= UMLOG_DEBUG)
            {
                [self logDebug:@"M2PA_STREAM_USERDATA received"];
            }
            data = task.data;
            [self sctpIncomingDataMessage:data];
            break;
        default:
            [self logMajorError:@"UNKNOWN STREAM IDENTIFIER"];
            break;
    }
}

- (void) _sctpMonitorIndicationTask:(UMM2PATask_sctpMonitorIndication *)task
{
    /* needs to be defined to comply with the API */
}

-(void) protocolViolation
{
     [self powerOff];
}

- (void) sctpIncomingDataMessage:(NSData *)data
{
    [_inboundThroughputPackets increaseBy:1];
    [_inboundThroughputBytes increaseBy:(uint32_t)data.length];

    u_int32_t len;
    
    const char *dptr;

    [_incomingDataBufferLock lock];
    @try
    {
        [_data_link_buffer appendData:data];
        while([_data_link_buffer length] >= 16)
        {
            dptr = _data_link_buffer.bytes;
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
            /* so we set BSN for the next outgoing packet */
            _bsn = ntohl(*(u_int32_t *)&dptr[12]) & FSN_BSN_MASK;
            _bsn2 = ntohl(*(u_int32_t *)&dptr[8]) & FSN_BSN_MASK;
        
            if((_fsn >= FSN_BSN_MASK) || (_bsn2 >= FSN_BSN_MASK))
            {
                _outstanding = 0;
                _bsn2 =  _fsn;
            }
            else
            {
                _outstanding = ((long)_fsn - (long)_bsn2 ) % FSN_BSN_SIZE;
            }
            [self checkSpeed];
            int userDataLen = len-16;
            if(userDataLen < 0)
            {
                [self logMajorError:@"m2pa userDataLen is < 0"];
                [self protocolViolation];
                return;
            }
            NSData *userData = [NSData dataWithBytes:&dptr[16] length:(userDataLen)];
            
            if (self.m2pa_status!=M2PA_STATUS_IS)
            {
                self.m2pa_status = M2PA_STATUS_IS;
            }
            NSArray *usrs = [_users arrayCopy];
            for(UMLayerM2PAUser *u in usrs)
            {
                UMLayerM2PAUserProfile *profile = u.profile;
                if([profile wantsDataMessages])
                {
                    id user = u.user;
                    NSString *uid = u.userId;
                    [user m2paDataIndication:self
                                         slc:_slc
                                      userId:uid
                                        data:userData];

                }
            }
            [_data_link_buffer replaceBytesInRange: NSMakeRange(0,len) withBytes:"" length:0];
        }
    }
    @finally
    {
        [_incomingDataBufferLock unlock];
    }
}

- (void) sctpIncomingLinkstateMessage:(NSData *)data
{
    M2PA_linkstate_message linkstatus;
    uint32_t len;
    const char *dptr;
    
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:[NSString stringWithFormat:@" %d bytes of linkstatus data received",(int)data.length]];
    }
    
    [_controlLock lock];
    @try
    {
        [_control_link_buffer appendData:data];
        if(_control_link_buffer.length < 20)
        {
            [self logDebug:@"not enough data received yet"];
            return;
        }
 
        dptr = _control_link_buffer.bytes;
        len = ntohl(*(u_int32_t *)&dptr[4]);
        linkstatus = ntohl(*(u_int32_t *)&dptr[16]);

        if(self.logLevel <= UMLOG_DEBUG)
        {
			NSString *ls = [self linkStatusString:linkstatus];
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
    @finally
    {
        [_controlLock unlock];
    }
}

- (void) _oos_received
{
	[_controlLock lock];
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"Received M2PA_LINKSTATE_OUT_OF_SERVICE"];
    }
    _lscState  = [_lscState eventSIOS:self];
    _iacState  = [_iacState eventSIOS:self];
	[_controlLock unlock];
}

- (void) _alignment_received
{
	[_controlLock lock];
    _lscState  = [_lscState eventSIO:self];
    _iacState  = [_iacState eventSIO:self];
	[_controlLock unlock];

}

- (void) _proving_normal_received
{
	[_controlLock lock];
    _lscState  = [_lscState eventSIN:self];
    _iacState  = [_iacState eventSIN:self];
	[_controlLock unlock];
}

- (void) _proving_emergency_received
{
	[_controlLock lock];
    _lscState  = [_lscState eventSIE:self];
    _iacState  = [_iacState eventSIE:self];
	[_controlLock unlock];
}


- (void) _linkstate_ready_received
{
	[_controlLock lock];
    _lscState  = [_lscState eventFisu:self];
    //_iacState  = [_iacState eventFisu:self];
	[_controlLock unlock];
}

- (void) _linkstate_processor_outage_received
{

	[_controlLock lock];
    _lscState  = [_lscState eventLocalProcessorOutage:self];
    _iacState  = [_iacState eventLocalProcessorOutage:self];
	[_controlLock unlock];
}

- (void) _linkstate_processor_recovered_received
{
	[_controlLock lock];
    _lscState  = [_lscState eventLocalProcessorRecovered:self];
    _iacState  = [_iacState eventLocalProcessorRecovered:self];

	[_controlLock unlock];

}

- (void) _linkstate_busy_received
{
	[_controlLock lock];
    _lscState  = [_lscState eventSIB:self];
    //_iacState  = [_iacState eventSIB:self];
	[_controlLock unlock];
}

- (void) _linkstate_busy_ended_received
{
	[_controlLock lock];
    _lscState  = [_lscState eventContinue:self];
    //_iacState  = [_iacState eventContinue:self];
	[_controlLock unlock];

    _link_congestion_cleared_time = [NSDate date];
    _congested = NO;
    [_t6 stop];
    [self sendCongestionClearedIndication];
    if([_waitingMessages count]>0)
    {
        [_t7 start];
    }
}

- (void)startDequingMessages
{
    UMLayerTask *task = [_waitingMessages getFirst];
    while(task)
    {
        [self queueFromUpperWithPriority:task];
        task = [_waitingMessages getFirst];
    }
}

- (void) sendCongestionClearedIndication
{
    NSArray *usrs = [_users arrayCopy];
    for(UMLayerM2PAUser *u in usrs)
    {
        if([u.profile wantsM2PALinkstateMessages])
        {
            [u.user m2paCongestionCleared:self
                               slc:_slc
                            userId:u.userId];
        }
    }
}

- (void) sendCongestionIndication
{
    NSArray *usrs = [_users arrayCopy];
    for(UMLayerM2PAUser *u in usrs)
    {
        if([u.profile wantsM2PALinkstateMessages])
        {
            [u.user m2paCongestion:self
                               slc:_slc
                            userId:u.userId];
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

/****/
- (void)_timerFires1
{
    
}
- (void)_timerFires2
{
    
}

- (void)_timerFires3
{
}




- (void)_timerFires4
{
	IAC_ASSIGN_AND_LOG(_iacState,[_iacState eventTimer4:self]);
}

- (void)_timerFires4r
{
	IAC_ASSIGN_AND_LOG(_iacState,[_iacState eventTimer4r:self]);
}

- (void)_timerFires5
{

}

- (void)_timerFires6
{
	/* Figure 13/Q.703 (sheet 2 of 7) */

	LSC_ASSIGN_AND_LOG(_lscState,[_lscState eventLinkFailure:self]);
	_linkstate_busy = NO;
	[_t7 stop];
}
- (void)_timerFires7
{
}


#pragma mark -
#pragma mark Task Creators

- (void)adminInit
{
    UMLayerTask *task = [[UMM2PATask_AdminInit alloc]initWithReceiver:self sender:NULL];
    [self queueFromAdmin:task];
}
- (void)adminAttachOrder:(UMLayerSctp *)sctp_layer;
{
    UMLayerTask *task = [[UMM2PATask_AdminAttachOrder alloc]initWithReceiver:self sender:NULL layer:sctp_layer];
    [self queueFromAdmin:task];
}

- (void)adminSetConfig:(NSDictionary *)cfg applicationContext:(id<UMLayerM2PAApplicationContextProtocol>)appContext
{
    UMLayerTask *task = [[UMM2PATask_AdminSetConfig alloc]initWithReceiver:self sender:NULL config:cfg applicationContext:appContext];
    [self queueFromAdmin:task];
}

- (void)adminAttachFor:(id<UMLayerM2PAUserProtocol>)attachingLayer
{
    UMLayerTask *task = [[UMM2PATask_AdminInit alloc]initWithReceiver:self sender:attachingLayer];
    [self queueFromAdmin:task];
}

- (void)adminAttachFor:(id<UMLayerM2PAUserProtocol>)caller
               profile:(UMLayerM2PAUserProfile *)p
                userId:(id)uid
                    ni:(int)xni
                   slc:(int)xslc;

{
    UMAssert(uid.length > 0,@"no user id passed to MTP2 adminAttachFor");
    UMAssert(p !=0,@"no profile MTP2 adminAttachFor");

    UMLayerTask *task =  [[UMM2PATask_AdminAttach alloc]initWithReceiver:self
                                                                  sender:caller
                                                                 profile:p
                                                                      ni:xni
                                                                     slc:xslc
                                                                  userId:uid];
    [self queueFromAdmin:task];
}


- (void)dataFor:(id<UMLayerM2PAUserProtocol>)caller
           data:(NSData *)sendingData
     ackRequest:(NSDictionary *)ack
{
    UMLayerTask *task = [[UMM2PATask_Data alloc] initWithReceiver:self
                                                           sender:caller
                                                             data:sendingData
                                                       ackRequest:ack];
    [self queueFromUpper:task];
}

- (void)powerOnFor:(id<UMLayerM2PAUserProtocol>)caller
{
    UMLayerTask *task = [[UMM2PATask_PowerOn alloc]initWithReceiver:self sender:caller];
    [self queueFromUpperWithPriority:task];
}

- (void)powerOffFor:(id<UMLayerM2PAUserProtocol>)caller
{
    UMLayerTask *task = [[UMM2PATask_PowerOff alloc]initWithReceiver:self sender:caller];
    [self queueFromUpperWithPriority:task];
}

- (void)startFor:(id<UMLayerM2PAUserProtocol>)caller
{
    UMLayerTask *task = [[UMM2PATask_Start alloc]initWithReceiver:self sender:caller];
    [self queueFromUpperWithPriority:task];
}

- (void)stopFor:(id<UMLayerM2PAUserProtocol>)caller
{
    UMLayerTask *task = [[UMM2PATask_Stop alloc]initWithReceiver:self sender:caller];
    [self queueFromUpperWithPriority:task];
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

- (void)queueTimerEvent:(id<UMLayerM2PAUserProtocol>)caller timerName:(NSString *)tname
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
    u.userId = task.userId;
    u.user = user;
    u.profile = task.profile;
    _slc = task.slc;
    _networkIndicator = task.ni;

    [_users addObject:u];
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:[NSString stringWithFormat:@"attachedFrom %@",user.layerName]];
    }
    [user adminAttachConfirm:self
                         slc:task.slc
                      userId:task.userId];
}

- (void)notifySpeedExceeded
{
/* if we are sending too fast we have to pause, if the link is congested or not */
/* however if we are in congestion status already, we have already sent this message */
/* but it doesnt hurt to pause twice */
//time(&link->link_speed_excess_time);
//m2pa_send_speed_exceeded_indication_to_mtp3(link);
}

- (void)notifySpeedExceededCleared
{
    
    /* if we drop out of speed excess we can resume. however if we are still in congestion status
     we have to wait it to clear */
 //   time(&link->link_speed_excess_cleared_time);
 //   m2pa_send_speed_exceeded_cleared_indication_to_mtp3(link);
}
- (void)checkSpeed
{
    int last_speed_status;
    double	current_speed;

    [_seqNumLock lock];
    _outstanding = ((long)_fsn - (long)_bsn2) % FSN_BSN_SIZE;
    if((_fsn == 0) || (_bsn2== 0) || (_fsn >=FSN_BSN_MASK) || (_bsn2 >=FSN_BSN_MASK))
    {
        _outstanding = 0;
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
        current_speed = [_speedometer getSpeedForSeconds:3];
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
{
    [_outboundThroughputBytes increaseBy:(uint32_t)data.length];
    [_outboundThroughputPackets increaseBy:1];

    [_dataLock lock];
    [_t1 stop]; /* alignment ready	*/
    [_t6 stop]; /* Remote congestion	*/


    [_seqNumLock lock];
    _fsn = (_fsn+1) % FSN_BSN_SIZE;
    /* The FSN and BSN values range from 0 to 16,777,215 */
    if((_fsn == FSN_BSN_MASK) || (_bsn2 == FSN_BSN_MASK))
    {
        _outstanding = 0;
        _bsn2 = _fsn;
        //mm_layer_log_debug((mm_generic_layer *)link,PLACE_M2PA_GENERAL,"TX Outstanding set to 0");
    }
    else
    {
        _outstanding = ((long)_fsn - (long)_bsn2 ) % FSN_BSN_SIZE;
        //mm_layer_log_debug((mm_generic_layer *)link,PLACE_M2PA_GENERAL,"TX Outstanding=%u",link->outstanding);
    }
    [_seqNumLock unlock];


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
    header[8] = (_bsn >> 24) & 0xFF;
    header[9] = (_bsn >> 16) & 0xFF;
    header[10] = (_bsn >> 8) & 0xFF;
    header[11] = (_bsn >> 0) & 0xFF;
    header[12] = (_fsn >> 24) & 0xFF;
    header[13] = (_fsn >> 16) & 0xFF;
    header[14] = (_fsn >> 8) & 0xFF;
    header[15] = (_fsn >> 0) & 0xFF;

    NSMutableData *sctpData = [[NSMutableData alloc]initWithBytes:&header length:sizeof(header)];
    [sctpData appendData:data];

    [_sctpLink dataFor:self
                 data:sctpData
             streamId:streamId
           protocolId:SCTP_PROTOCOL_IDENTIFIER_M2PA
           ackRequest:ackRequest];
    [_speedometer increase];
    [_dataLock unlock];
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
        [self sendData:mtp3_data
                stream:M2PA_STREAM_USERDATA
            ackRequest:task.ackRequest];
    }
}

- (void) resetSequenceNumbers
{
    [_seqNumLock lock];
    _fsn = 0x00FFFFFF; /* last sent FSN */
    _bsn = 0x00FFFFFF; /* last received FSN, next BSN to send. */
    _bsn2 = 0x00FFFFFF; /* last received bsn*/
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
    [self powerOff];
}

- (void)_startTask:(UMM2PATask_Start *)task
{
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"start"];
    }
    [self start];

}

- (void)_stopTask:(UMM2PATask_Stop *)task
{
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"stop"];
    }
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
	NSString *timerName = task.timerName;
	if([timerName isEqualToString:@"t1"])
	{
		[self _timerFires1];
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

#pragma mark -
#pragma mark Helpers

- (void)powerOn
{
    self.m2pa_status = M2PA_STATUS_OFF;
	self.alignmentsReceived = 0;
    _local_processor_outage = NO;
    _remote_processor_outage = NO;
    _emergency = NO;
    [self resetSequenceNumbers];
    _outstanding = 0;
    _ready_received = 0;
    _ready_sent = 0;

    [_speedometer clear];
    [_submission_speed clear];

	_lscState = [[UMM2PALinkStateControl_PowerOff alloc]initWithLink:self];
	_iacState = [[UMM2PAInitialAlignmentControl_Idle alloc]initWithLink:self];

   // self.m2pa_status = M2PA_STATUS_OOS; // this is being set once SCTP is established
    [_sctpLink openFor:self];

    /* we do additinoal stuff for power on in sctpReportsUp */
 }

- (void)powerOff
{
    if(self.m2pa_status != M2PA_STATUS_OFF)
    {
        [self stop];
    }
    self.m2pa_status = M2PA_STATUS_OFF;
    [_sctpLink closeFor:self];

    [self resetSequenceNumbers];
    _ready_received = NO;
    _ready_sent = NO;
    [_speedometer clear];
    [_submission_speed clear];
}

- (void)start
{
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"start"];
    }

    if(self.m2pa_status != M2PA_STATUS_OOS)
    {
        [self logMajorError:@"can not start if link is not in status OOS. Going to OFF state"];
        self.m2pa_status =M2PA_STATUS_OFF;
        return;
    }
    
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"Sending LINKSTATE_ALIGNMENT"];
    }
    [self sendLinkstatus:M2PA_LINKSTATE_ALIGNMENT];

    if(_t4.seconds == 0)
    {
        _t4.seconds = _t4n;
    }
    if(_emergency)
    {
        _t4.seconds = _t4e;
    }
    [_t2 start];
    [_t4 start];
    [_t4r start];
    self.m2pa_status = M2PA_STATUS_INITIAL_ALIGNMENT;
}

- (void)stop
{
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"stop"];
        [self logDebug:@"Sending M2PA_LINKSTATE_OUT_OF_SERVICE"];

    }
    [self sendLinkstatus:M2PA_LINKSTATE_OUT_OF_SERVICE];
    self.m2pa_status = M2PA_STATUS_OOS;
}

- (NSString *)linkStatusString:(M2PA_linkstate_message) linkstate
{
    switch(linkstate)
    {
        case M2PA_LINKSTATE_ALIGNMENT:
            return @"ALIGNMENT";
            break;
        case M2PA_LINKSTATE_PROVING_NORMAL:
            return @"PROVING_NORMAL";
            break;
        case M2PA_LINKSTATE_PROVING_EMERGENCY:
            return @"PROVING_EMERGENCY";
            break;
        case M2PA_LINKSTATE_READY:
            return @"READY";
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

- (NSString *)m2paStatusString:(M2PA_Status) linkstate
{
    switch(linkstate)
    {
        case M2PA_STATUS_UNUSED:
            return @"UNUSED";
            break;
        case M2PA_STATUS_OFF:
            return @"POWEROFF";
            break;
        case M2PA_STATUS_OOS:
            return @"OOS";
            break;
        case M2PA_STATUS_INITIAL_ALIGNMENT:
            return @"INITIAL_ALIGNMENT";
            break;
        case M2PA_STATUS_ALIGNED_NOT_READY:
            return @"ALIGNED_NOT_READY";
            break;
        case M2PA_STATUS_ALIGNED_READY:
            return @"ALIGNED_READY";
            break;
        case M2PA_STATUS_IS:
            return @"IS";
            break;
        default:
            return @"UNKNOWN";
            break;
    }
}
    
- (void)sendLinkstatus:(M2PA_linkstate_message)linkstate
{
    NSString *ls = [self linkStatusString:linkstate];

    switch(self.sctp_status)
    {
        case SCTP_STATUS_OFF:
            [self logDebug:[NSString stringWithFormat:@"Can not send %@ due to SCTP_STATUS_OFF",ls ]];
            return;
        case SCTP_STATUS_OOS:
            [self logDebug:[NSString stringWithFormat:@"Can not send %@ due to SCTP_STATUS_OOS",ls ]];
            return;
        case SCTP_STATUS_M_FOOS:
            [self logDebug:[NSString stringWithFormat:@"Can not send %@ due to SCTP_STATUS_M_FOOS",ls ]];
            return;
        default:
            break;
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
           ackRequest:NULL];
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

- (void)cancelEmergency
{
    self.emergency = NO;
}


-(void)txcStart
{
}

-(void)txcSendSIOS
{
    [self sendLinkstatus:M2PA_LINKSTATE_OUT_OF_SERVICE];
	[_t7 stop];
}

-(void)txcSendSIPO
{
    [self sendLinkstatus:M2PA_LINKSTATE_PROCESSOR_OUTAGE];
	[_t7 stop];
}

-(void)txcSendMSU:(NSData *)msu ackRequest:(NSDictionary *)ackRequest
{
    if(msu == NULL)
    {
        return;
    }
    [_submission_speed increase];
    [self checkSpeed];
    [self sendData:msu
            stream:M2PA_STREAM_USERDATA
        ackRequest:ackRequest];
}


-(void)txcSendSIO
{
    [self sendLinkstatus:M2PA_LINKSTATE_ALIGNMENT];
  
}

-(void)txcSendSIN
{
    [self sendLinkstatus:M2PA_LINKSTATE_PROVING_NORMAL];
}

-(void)txcSendSIE
{
    [self sendLinkstatus:M2PA_LINKSTATE_PROVING_EMERGENCY];
}

-(void)txcSendFISU
{
    [self sendLinkstatus:M2PA_LINKSTATE_READY];
}

-(void)txcFlushBuffers
{
}


-(void)iacEmergency
{
    _iacState =[_iacState eventEmergency:self];
}

-(void)iacEmergencyCeases
{
    _iacState=[_iacState eventEmergencyCeases:self];
}

-(void)iacStart
{
    _iacState=[_iacState eventStart:self];
}

-(void)iacStop
{
    _iacState=[_iacState eventStop:self];
}

-(void)iacAlignmentNotPossible
{
	_iacState=[_iacState eventAlignmentNotPossible:self];
}

-(void)lscAlignmentNotPossible
{
    _lscState=[_lscState eventAlignmentNotPossible:self];
}

-(void)lscAlignmentComplete
{
    _lscState=[_lscState eventAlignmentComplete:self];
}



-(void)suermStart
{
    
}

-(void)suermStop
{
    
}

-(void)aermStart
{
    
}

-(void)aermStop
{
    
}

- (void)aermSetTe
{
    
}

-(void)pocLocalProcessorOutage
{
	_local_processor_outage=YES;
}

-(void)pocRemoteProcessorOutage
{
	_remote_processor_outage=YES;
}

-(void)pocLocalProcessorRecovered
{
	_local_processor_outage=NO;
}

-(void)pocRemoteProcessorRecovered
{
	_remote_processor_outage=NO;
}

-(void)pocStop
{
}

-(void)pocStart
{
	/* cancel octet counting mode */
	/* start zero deletion */
	/* start flag detection */
	/* start bit counting */
	/* start octet counting */
	/* start detection of 7 consecutive ones */
	/* start check bit control */
	_pocStatus = PocStatus_inService;
}

-(void)lscNoProcessorOutage
{
	_lscState = [_lscState eventNoProcessorOutage:self];
}

-(void)rcRejectMsuFisu
{
    
}
- (void)rcAcceptMsuFisu
{
    
}

- (void)notifyMtp3OutOfService
{
    
}
- (void)notifyMtp3Stop
{
    
}

-(void)notifyMtp3RemoteProcessorOutage
{
    
}

-(void)notifyMtp3RemoteProcessorRecovered
{
    
}

-(void)notifyMtp3InService
{
    
}

-(void)markFurtherProving
{
	_furtherProving = YES;
}

-(void)cancelFurtherProving
{
	_furtherProving = NO;
}

#pragma mark -
#pragma mark Config Handling

- (NSDictionary *)config
{
    NSMutableDictionary *config = [[NSMutableDictionary alloc]init];
    [self addLayerConfig:config];
    config[@"attach-to"] = _sctpLink.layerName;
    config[@"autostart"] = _autostart ? @YES : @ NO;
    config[@"window-size"] = @(_window_size);
    config[@"speed"] = @(_speed);
    config[@"t1"] =@(_t1.seconds);
    config[@"t2"] =@(_t2.seconds);
    config[@"t3"] =@(_t3.seconds);
    config[@"t4e"] =@(_t4e);
    config[@"t4n"] =@(_t4n);
    config[@"t4r"] =@(_t4r.seconds);
    config[@"t5"] =@(_t5.seconds);
    config[@"t6"] =@(_t6.seconds);
    config[@"t7"] =@(_t7.seconds);
    return config;
}

- (void)setConfig:(NSDictionary *)cfg applicationContext:(id)appContext
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
    if(cfg[@"autostart"])
    {
        _autostart =  [cfg[@"autostart"] boolValue];
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
    [self adminAttachOrder:_sctpLink];
}

- (NSDictionary *)apiStatus
{
    NSMutableDictionary *d = [[NSMutableDictionary alloc]init];
    
    d[@"name"] = self.layerName;
    d[@"link-state-control"] = [_lscState description];
    d[@"initial-alignment-control-state"] = [_iacState description];
    d[@"attach-to"] = _sctpLink.layerName;
    d[@"local-processor-outage"] = _local_processor_outage ? @(YES) : @(NO);
    d[@"remote-processor-outage"] = _remote_processor_outage ? @(YES) : @(NO);
    d[@"level3-indication"] = _level3Indication ? @(YES) : @(NO);
    d[@"slc"] = @(_slc);
    d[@"network-indicator"] = @(_networkIndicator);
    d[@"bsn"] = @(_bsn);
    d[@"fsn"] = @(_fsn);
    d[@"bsn2"] = @(_bsn2);
    d[@"outstanding"] = @(_outstanding);

    switch(_m2pa_status)
    {
            
        case M2PA_STATUS_UNUSED:
            d[@"m2pa-status"] = @"unused";
            break;
        case M2PA_STATUS_OFF:
            d[@"m2pa-status"] = @"off";
            break;
        case M2PA_STATUS_OOS:
            d[@"m2pa-status"] = @"out-of-service";
            break;
        case M2PA_STATUS_INITIAL_ALIGNMENT:
            d[@"m2pa-status"] = @"initial-alignment";
            break;
        case M2PA_STATUS_ALIGNED_NOT_READY:
            d[@"m2pa-status"] = @"not-ready";
            break;
        case M2PA_STATUS_ALIGNED_READY :
            d[@"m2pa-status"] = @"ready";
            break;
        case M2PA_STATUS_IS:
            d[@"m2pa-status"] = @"in-service";
            break;
        default:
            d[@"m2pa-status"] = [NSString stringWithFormat:@"unknown(%d)",_m2pa_status];
    }
    d[@"congested"] = _congested ? @(YES) : @(NO);
    d[@"emergency"] = _emergency ? @(YES) : @(NO);
    d[@"autostart"] = _autostart ? @(YES) : @(NO);
    d[@"paused"] = _paused ? @(YES) : @(NO);
    d[@"link-restarts"] = _link_restarts ? @(YES) : @(NO);
    d[@"ready-received"] = @(_ready_received);
    d[@"ready-sent"] = @(_ready_sent);
    d[@"reception-enabled"] = _receptionEnabled ? @(YES) : @(NO);
    d[@"configured-speed"] = @(_speed);
    d[@"window-size"] = @(_window_size);
    d[@"current-speed"] =   [_speedometer getSpeedTripleJson];
    d[@"submission-speed"] =   [_submission_speed getSpeedTripleJson];


    static NSDateFormatter *dateFormatter = NULL;
    
    if(dateFormatter==NULL)
    {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
        [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
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

- (void)stopDetachAndDestroy
{
    /* FIXME: do something here */
}

@end
