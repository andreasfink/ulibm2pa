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


@implementation UMLayerM2PA

@synthesize name;
@synthesize lscState;
@synthesize iacState;

@synthesize slc;

@synthesize speedometer;

@synthesize congested;
@synthesize local_processor_outage;
@synthesize remote_processor_outage;
@synthesize level3Indication;

@synthesize emergency;
@synthesize autostart;
@synthesize link_restarts;
@synthesize ready_received;
@synthesize ready_sent;
@synthesize paused;
@synthesize speed;
@synthesize window_size;

@synthesize t1;
@synthesize t2;
@synthesize t3;
@synthesize t4;
@synthesize t4r;
@synthesize t5;
@synthesize t6;
@synthesize t7;
@synthesize t4n;
@synthesize t4e;
@synthesize speed_status;

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
        link_restarts++;
        link_down_time = 0;
        link_up_time = time(NULL);
    }

    if((old_status == M2PA_STATUS_IS)
       && (status != M2PA_STATUS_IS))
    {
        link_up_time = 0;
        link_down_time = time(NULL);
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
                                 slc:slc
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

        lscState = [[UMM2PALinkStateControl_PowerOff alloc]initWithLink:self];
        iacState = [[UMM2PAInitialAlignmentControl_Idle alloc] initWithLink:self];
        slc = 0;
        emergency = NO;
        congested = NO;
        local_processor_outage = NO;
        remote_processor_outage = NO;
        _sctp_status = SCTP_STATUS_OOS;
        _m2pa_status = M2PA_STATUS_OFF;

        autostart = NO;
        link_restarts = NO;
        ready_received = 0;
        ready_sent = 0;
        paused = NO;
        speed = 100.0;
        window_size = 128;
        
        t1 = [[UMTimer alloc]initWithTarget:self selector:@selector(timerFires1) object:NULL duration:M2PA_DEFAULT_T1 name:@"t1" repeats:NO];
        t2 = [[UMTimer alloc]initWithTarget:self selector:@selector(timerFires2) object:NULL duration:M2PA_DEFAULT_T2 name:@"t2" repeats:NO];
        t3 = [[UMTimer alloc]initWithTarget:self selector:@selector(timerFires3) object:NULL duration:M2PA_DEFAULT_T3 name:@"t3" repeats:NO];
        t4 = [[UMTimer alloc]initWithTarget:self selector:@selector(timerFires4) object:NULL duration:M2PA_DEFAULT_T4_N name:@"t4" repeats:NO];
        t4r = [[UMTimer alloc]initWithTarget:self selector:@selector(timerFires4r) object:NULL duration:M2PA_DEFAULT_T4_R name:@"t4t" repeats:NO];
        t5 = [[UMTimer alloc]initWithTarget:self selector:@selector(timerFires5) object:NULL duration:M2PA_DEFAULT_T5 name:@"t5" repeats:NO];
        t6 = [[UMTimer alloc]initWithTarget:self selector:@selector(timerFires6) object:NULL duration:M2PA_DEFAULT_T6 name:@"t6" repeats:NO];
        t7 = [[UMTimer alloc]initWithTarget:self selector:@selector(timerFires7) object:NULL duration:M2PA_DEFAULT_T7 name:@"t7" repeats:NO];
        
        t1.duration = M2PA_DEFAULT_T1;
        t2.duration = M2PA_DEFAULT_T2;
        t3.duration = M2PA_DEFAULT_T3;
        t4.duration = M2PA_DEFAULT_T4_N;
        t4n = M2PA_DEFAULT_T4_N;
        t4e = M2PA_DEFAULT_T4_E;
        t4r.duration = M2PA_DEFAULT_T4_R;
        speedometer = [[UMThroughputCounter alloc]initWithResolutionInSeconds: 1.0 maxDuration: 1260.0];
        control_link_buffer = [[NSMutableData alloc] init];
        data_link_buffer = [[NSMutableData alloc] init];
        waitingMessages = [[UMQueue alloc]init];

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

    [self logInfo:@"sctpReportsUp"];
    /* send link status out of service to the other side */
    /* this is done in m2pa_start! */
    [self txcSendSIOS];
    /* cancel local processor outage */
    local_processor_outage = NO;
    remote_processor_outage = NO;
    /* cancel emergency */
    emergency = NO;
    /* status is now OOS */
    self.m2pa_status = M2PA_STATUS_OOS;
    /* FIXME: we should probably inform MTP3 ? */
    /* we now wait for MTP3 to tell us to start the link */
    [self resetSequenceNumbers];
    outstanding = 0;
    ready_received = 0;
    ready_sent = 0;
    [speedometer clear];
    [submission_speed clear];
    lscState  = [lscState eventPowerOn:self];
}

- (void)sctpReportsDown
{
    [self logInfo:@"sctpReportsDown"];
    self.m2pa_status = M2PA_STATUS_OFF;
    /* we now wait for MTP3 to tell us to start the link again */
    lscState  = [lscState eventPowerOff:self];
    iacState  = [iacState eventPowerOff:self];
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
                                             slc:slc
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
        [sctpLink openFor:self];
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
        [data_link_buffer appendData:data];
        while([data_link_buffer length] >= 16)
        {
            dptr = data_link_buffer.bytes;
            len = ntohl(*(u_int32_t *)&dptr[4]);
        
            if(data_link_buffer.length < len)
            {
                if(self.logLevel <=UMLOG_DEBUG)
                {
                    [self logDebug:[NSString stringWithFormat:@"not enough data received yet %lu bytes in buffer, expecting %u",
                                    data_link_buffer.length,
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
            bsn = ntohl(*(u_int32_t *)&dptr[12]) & FSN_BSN_MASK;
            bsn2 = ntohl(*(u_int32_t *)&dptr[8]) & FSN_BSN_MASK;
        
            if((fsn >= FSN_BSN_MASK) || (bsn2 >= FSN_BSN_MASK))
            {
                outstanding = 0;
                bsn2 =  fsn;
            }
            else
            {
                outstanding = ((long)fsn - (long)bsn2 ) % FSN_BSN_SIZE;
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
                                         slc:slc
                                      userId:uid
                                        data:userData];

                }
            }
            [data_link_buffer replaceBytesInRange: NSMakeRange(0,len) withBytes:"" length:0];
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
        [control_link_buffer appendData:data];
        if(control_link_buffer.length < 20)
        {
            [self logDebug:@"not enough data received yet"];
            return;
        }
 
        dptr = control_link_buffer.bytes;
        len = ntohl(*(u_int32_t *)&dptr[4]);
        linkstatus = ntohl(*(u_int32_t *)&dptr[16]);
    
        NSString *ls = [self linkStatusString:linkstatus];
        NSString *ms = [self m2paStatusString:self.m2pa_status];
        if(self.logLevel <= UMLOG_DEBUG)
        {
            [self logDebug:[NSString stringWithFormat:@" %d (%@) event -> %d (%@) status",
                            linkstatus,ls,self.m2pa_status,ms]];
        }

        if(self.logLevel <= UMLOG_DEBUG)
        {
            [self logDebug:[NSString stringWithFormat:@"Received %@",[self linkStatusString:linkstatus]]];
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
        [control_link_buffer replaceBytesInRange: NSMakeRange(0,len) withBytes:"" length:0];
    }
    @finally
    {
        [_controlLock unlock];
    }
}

- (void) _oos_received
{
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"Received M2PA_LINKSTATE_OUT_OF_SERVICE"];
    }
    lscState  = [lscState eventSIOS:self];
    iacState  = [iacState eventSIOS:self];
}

- (void) _alignment_received
{
    lscState  = [lscState eventSIO:self];
    iacState  = [iacState eventSIO:self];
}

- (void) _proving_normal_received
{
    lscState  = [lscState eventSIN:self];
    iacState  = [iacState eventSIN:self];
}

- (void) _proving_emergency_received
{
    lscState  = [lscState eventSIE:self];
    iacState  = [iacState eventSIE:self];
}


- (void) _linkstate_ready_received
{
    lscState  = [lscState eventFisu:self];
    iacState  = [iacState eventProvingEnds:self];
}

- (void) _linkstate_processor_outage_received
{

    lscState  = [lscState eventLocalProcessorOutage:self];
    iacState  = [iacState eventProvingEnds:self];
}

- (void) _linkstate_processor_recovered_received
{
    lscState  = [lscState eventLocalProcessorRecovered:self];
    iacState  = [iacState eventProvingEnds:self];
}

- (void) _linkstate_busy_received
{
    lscState  = [lscState eventSIB:self];
}

- (void) _linkstate_busy_ended_received
{
    link_congestion_cleared_time = time(NULL);
    congested = NO;
    [t6 stop];
    [self sendCongestionClearedIndication];
    if([waitingMessages count]>0)
    {
        [t7 start];
    }
}

- (void)startDequingMessages
{
    UMLayerTask *task = [waitingMessages getFirst];
    while(task)
    {
        [self queueFromUpperWithPriority:task];
        task = [waitingMessages getFirst];
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
                               slc:slc
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
                               slc:slc
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
    sctpLink = (UMLayerSctp *)attachedLayer;
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
    sctpLink = NULL;
    
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
    [t1 stop];
    [self timerEvent:NULL timerNr:1];

}
- (void)timerFires2
{
    [t2 stop];
    [self timerEvent:NULL timerNr:2];
}
- (void)timerFires3
{
    [t3 stop];
    [self timerEvent:NULL timerNr:3];
}
- (void)timerFires4
{
    [t4 stop];
    [self timerEvent:NULL timerNr:4];
}
- (void)timerFires4r
{
    [t4r stop];
    [self timerEvent:NULL timerNr:-4];
}
- (void)timerFires5
{
    [t5 stop];
    [self timerEvent:NULL timerNr:5];
}
- (void)timerFires6
{
    [t6 stop];
    [self timerEvent:NULL timerNr:6];
}
- (void)timerFires7
{
    [t7 stop];
    [self timerEvent:NULL timerNr:7];
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
    [t4 stop];
    [t4r stop];
    if(self.m2pa_status == M2PA_LINKSTATE_READY)
    {
        /* we are in service already so this is a old timer which got forgotton to stop */
        [t1 stop];
        [t4 stop];
        [t4r stop];
    }
    else
    {
        [t1 start];
        [self sendLinkstatus:M2PA_LINKSTATE_READY];
        [t4r start];
        self.m2pa_status = M2PA_STATUS_ALIGNED_READY;
    }
}

- (void)_timerFires4r
{
    if(self.m2pa_status == M2PA_STATUS_ALIGNED_NOT_READY)
    {
        if(emergency==NO)
        {
            [self sendLinkstatus:M2PA_LINKSTATE_PROVING_NORMAL];
        }
        else
        {
            [self sendLinkstatus:M2PA_LINKSTATE_PROVING_EMERGENCY];
        }
        [t4r start];
    }
    else if(self.m2pa_status == M2PA_STATUS_ALIGNED_READY)
    {
        [self sendLinkstatus:M2PA_LINKSTATE_READY];
        [t3 stop];
        [t4 stop];
        [t4r stop];
    }
}

- (void)_timerFires5
{
}

- (void)_timerFires6
{
    if((self.m2pa_status == M2PA_STATUS_IS) && (congested==1))
    {
        [self sendLinkstatus:M2PA_LINKSTATE_OUT_OF_SERVICE];
        self.m2pa_status = M2PA_STATUS_OOS;
    }
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

- (void)timerEvent:(id<UMLayerM2PAUserProtocol>)caller timerNr:(int)tnr
{
    UMLayerTask *task = [[UMM2PATask_TimerEvent alloc]initWithReceiver:self sender:caller timerNumber:tnr];
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
    sctpLink = sctp;
    UMLayerSctpUserProfile *profile = [[UMLayerSctpUserProfile alloc]initWithDefaultProfile];
    [sctp adminAttachFor:self profile:profile userId:self.layerName];
}

- (void) _adminDetachOrderTask:(UMM2PATask_AdminDetachOrder *)task
{
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"adminAttachOrder"];
    }
    [sctpLink adminDetachFor:self userId:self.layerName];
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
    slc = task.slc;
    networkIndicator = task.ni;

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
    outstanding = ((long)fsn - (long)bsn2) % FSN_BSN_SIZE;
    if((fsn == 0) || (bsn2== 0) || (fsn >=FSN_BSN_MASK) || (bsn2 >=FSN_BSN_MASK))
    {
        outstanding = 0;
    }
    [_seqNumLock unlock];

    last_speed_status = speed_status;

    //	error(0,"fsn: %u, bsn: %u, outstanding %u",link->fsn,link->bsn2,link->outstanding);

    if (outstanding > window_size)
    {
        speed_status = SPEED_EXCEEDED;
    }
    else
    {
        speed_status = SPEED_WITHIN_LIMIT;
        current_speed = [speedometer getSpeedForSeconds:3];
        if (current_speed > speed)
        {
            speed_status = SPEED_EXCEEDED;
        }
        else
        {
            speed_status = SPEED_WITHIN_LIMIT;
        }
    }
    if((last_speed_status == SPEED_WITHIN_LIMIT)
       && (speed_status == SPEED_EXCEEDED))
    {
        [self notifySpeedExceeded];
    }
    else if((last_speed_status == SPEED_EXCEEDED)
            && (speed_status == SPEED_WITHIN_LIMIT)
            && (congested == 0))
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
    [t1 stop]; /* alignment ready	*/
    [t6 stop]; /* Remote congestion	*/

    size_t headerlen = 16;
    size_t totallen =  headerlen + data.length;

    unsigned char *m2pa_header = malloc(totallen);
    memset(m2pa_header,0x00,totallen);

    m2pa_header[0] = M2PA_VERSION1; /* version field */
    m2pa_header[1] = 0; /* spare field */
    m2pa_header[2] = M2PA_CLASS_RFC4165; /* m2pa_message_class = draft13;*/
    m2pa_header[3] = M2PA_TYPE_USER_DATA; /*m2pa_message_type;*/
    *((unsigned long *)&m2pa_header[4]) = htonl(totallen);

    [_seqNumLock lock];
    fsn = (fsn+1) % FSN_BSN_SIZE;
    /* The FSN and BSN values range from 0 to 16,777,215 */
    if((fsn == FSN_BSN_MASK) || (bsn2 == FSN_BSN_MASK))
    {
        outstanding = 0;
        bsn2 = fsn;
        //mm_layer_log_debug((mm_generic_layer *)link,PLACE_M2PA_GENERAL,"TX Outstanding set to 0");
    }
    else
    {
        outstanding = ((long)fsn - (long)bsn2 ) % FSN_BSN_SIZE;
        //mm_layer_log_debug((mm_generic_layer *)link,PLACE_M2PA_GENERAL,"TX Outstanding=%u",link->outstanding);
    }
    [_seqNumLock unlock];

    *((uint32_t *)&m2pa_header[8]) = htonl(bsn);
    *((uint32_t *)&m2pa_header[12]) = htonl(fsn);
    memcpy(&m2pa_header[16],data.bytes,data.length);
    NSData *sctpData = [NSData dataWithBytes:m2pa_header length:totallen];
    free(m2pa_header);

    [sctpLink dataFor:self
                 data:sctpData
             streamId:streamId
           protocolId:SCTP_PROTOCOL_IDENTIFIER_M2PA
           ackRequest:ackRequest];
    [speedometer increase];
    [_dataLock unlock];
}

- (void)_dataTask:(UMM2PATask_Data *)task
{
    NSData *mtp3_data = task.data;
    if(mtp3_data == NULL)
    {
        return;
    }
    [submission_speed increase];
    [self checkSpeed];

    if(congested)
    {
        [waitingMessages append:task];
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
    fsn = 0x00FFFFFF; /* last sent FSN */
    bsn = 0x00FFFFFF; /* last received FSN, next BSN to send. */
    bsn2 = 0x00FFFFFF; /* last received bsn*/
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
    emergency = YES;
}
- (void)_emergencyCheasesTask:(UMM2PATask_EmergencyCheases *)task
{
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"emergencyCheases"];
    }
    emergency = NO;
}

- (void)_setSlcTask:(UMM2PATask_SetSlc *)task
{
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:[NSString stringWithFormat:@"settingSLC to %d",task.slc]];
    }

    slc = task.slc;
}

- (void)_timerEventTask:(UMM2PATask_TimerEvent *)task
{
    switch(task.timerNumber)
    {
        case 1:
            [self _timerFires1];
            break;
        case 2:
            [self _timerFires2];
            break;
        case 3:
            [self _timerFires3];
            break;
        case 4:
            [self _timerFires4];
            break;
        case -4:
            [self _timerFires4r];
            break;
        case 5:
            [self _timerFires5];
            break;
        case 6:
            [self _timerFires6];
            break;
        case 7:
            [self _timerFires7];
            break;
    }
}

#pragma mark -
#pragma mark Helpers

- (void)powerOn
{
    self.m2pa_status = M2PA_STATUS_OFF;
    
    local_processor_outage = NO;
    remote_processor_outage = NO;
    emergency = NO;
    [self resetSequenceNumbers];
    outstanding = 0;
    ready_received = 0;
    ready_sent = 0;

    [speedometer clear];
    [submission_speed clear];

   // self.m2pa_status = M2PA_STATUS_OOS; // this is being set once SCTP is established
    [sctpLink openFor:self];

    /* we do additinoal stuff for power on in sctpReportsUp */
 }

- (void)powerOff
{
    if(self.m2pa_status != M2PA_STATUS_OFF)
    {
        [self stop];
    }
    self.m2pa_status = M2PA_STATUS_OFF;
    [sctpLink closeFor:self];

    [self resetSequenceNumbers];
    ready_received = NO;
    ready_sent = NO;
    [speedometer clear];
    [submission_speed clear];
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

    [t2 start];
    [t4 start];
    [t4r start];
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
        ready_sent++;
    }
    unsigned char m2pa_header[M2PA_LINKSTATE_PACKETLEN];
    
    
    m2pa_header[0] = M2PA_VERSION1; /* version field */
    m2pa_header[1] = 0; /* spare field */
    m2pa_header[2] = M2PA_CLASS_RFC4165; /* m2pa_message_class;*/
    m2pa_header[3] = M2PA_TYPE_LINK_STATUS; /*m2pa_message_type;*/
        
    *((uint32_t *)&m2pa_header[4])  = htonl(M2PA_LINKSTATE_PACKETLEN);
    *((uint32_t *)&m2pa_header[8])  = htonl(0x00FFFFFF);
    *((uint32_t *)&m2pa_header[12]) = htonl(0x00FFFFFF);
    *((uint32_t *)&m2pa_header[16]) = htonl(linkstate);
        
    NSData *data = [NSData dataWithBytes:m2pa_header length:M2PA_LINKSTATE_PACKETLEN];
    
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:[NSString stringWithFormat:@"Sending %@",ls]];
        //mm_m2pa_header_dump13(link,data);
    }

    [sctpLink dataFor:self
                 data:data
             streamId:M2PA_STREAM_LINKSTATE
           protocolId:SCTP_PROTOCOL_IDENTIFIER_M2PA
           ackRequest:NULL];
}

#pragma mark -
#pragma mark Config Handling


-(void)rcStart
{
    receptionEnabled=YES;
}

- (void)rcStop
{
    receptionEnabled=NO;

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
}

-(void)txcSendSIPO
{
    [self sendLinkstatus:M2PA_LINKSTATE_PROCESSOR_OUTAGE];
}

-(void)txcSendMSU:(NSData *)msu ackRequest:(NSDictionary *)ackRequest
{
    if(msu == NULL)
    {
        return;
    }
    [submission_speed increase];
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
    iacState =[iacState eventEmergency:self];
}

-(void)iacEmergencyCeases
{
    iacState=[iacState eventEmergencyCeases:self];
}

-(void)iacStart
{
    iacState=[iacState eventStart:self];
}

-(void)iacStop
{
    iacState=[iacState eventStop:self];
}

-(void)lscAlignmentNotPossible
{
    lscState=[lscState eventAlignmentNotPossible:self];
}

-(void)lscAlignmentComplete
{
    lscState=[lscState eventAlignmentComplete:self];
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
}

-(void)pocRemoteProcessorOutage
{
}

-(void)pocLocalProcessorRecovered
{
}

-(void)pocRemoteProcessorRecovered
{
}

-(void)pocStop
{
    
}
-(void)pocStart
{
    
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

#pragma mark -
#pragma mark Config Handling

- (NSDictionary *)config
{
    NSMutableDictionary *config = [[NSMutableDictionary alloc]init];
    [self addLayerConfig:config];
    config[@"attach-to"] = sctpLink.layerName;
    config[@"autostart"] = autostart ? @YES : @ NO;
    config[@"window-size"] = @(window_size);
    config[@"speed"] = @(speed);
    config[@"t1"] =@(t1.duration/1000000.0);
    config[@"t2"] =@(t2.duration/1000000.0);
    config[@"t3"] =@(t3.duration/1000.0);
    config[@"t4e"] =@(t4e/1000000.0);
    config[@"t4n"] =@(t4n/1000000.0);
    config[@"t4r"] =@(t4r.duration/1000000.0);
    config[@"t5"] =@(t5.duration/1000000.0);
    config[@"t6"] =@(t6.duration/1000000.0);
    config[@"t7"] =@(t7.duration/1000000.0);
    return config;
}

- (void)setConfig:(NSDictionary *)cfg applicationContext:(id)appContext
{
    name = NULL;
    [self readLayerConfig:cfg];

    if(cfg[@"name"])
    {
        self.name = [cfg[@"name"] stringValue];
    }
    if(cfg[@"attach-to"])
    {
        NSString *attachTo =  [cfg[@"attach-to"] stringValue];
        sctpLink = [appContext getSCTP:attachTo];
        if(sctpLink == NULL)
        {
            NSString *s = [NSString stringWithFormat:@"Can not find sctp layer '%@' referred from m2pa layer '%@'",attachTo,self.name];
            @throw([NSException exceptionWithName:[NSString stringWithFormat:@"CONFIG_ERROR FILE %s line:%ld",__FILE__,(long)__LINE__]
                                           reason:s
                                         userInfo:NULL]);
        }
    }
    if(cfg[@"autostart"])
    {
        autostart =  [cfg[@"autostart"] boolValue];
    }
    if(cfg[@"window-size"])
    {
        window_size = [cfg[@"window-size"] intValue];
    }
    if (cfg[@"speed"])
    {
        speed = [cfg[@"speed"] doubleValue];
    }
    if (cfg[@"t1"])
    {
        t1.duration = [cfg[@"t1"] doubleValue] * 1000000.0;
    }
    if (cfg[@"t2"])
    {
        t2.duration = [cfg[@"t2"] doubleValue] * 1000000.0;
    }
    if (cfg[@"t3"])
    {
        t3.duration = [cfg[@"t3"] doubleValue] * 1000000.0;
    }
    if (cfg[@"t4e"])
    {
        t4e = [cfg[@"t4e"] doubleValue] * 1000000.0;
    }
    if (cfg[@"t4n"])
    {
        t4n = [cfg[@"t4n"] doubleValue] * 1000000.0;
    }
    if (cfg[@"t4r"])
    {
        t4r.duration = [cfg[@"t4r"] doubleValue] * 1000000.0;
    }
    if (cfg[@"t5"])
    {
        t5.duration = [cfg[@"t5"] doubleValue] *1000000.0;
    }
    if (cfg[@"t6"])
    {
        t6.duration = [cfg[@"t6"] doubleValue] *1000000.0;
    }
    if (cfg[@"t7"])
    {
        t7.duration = [cfg[@"t7"] doubleValue]*1000000.0;
    }
    [self adminAttachOrder:sctpLink];
}

- (NSDictionary *)apiStatus
{
    NSMutableDictionary *d = [[NSMutableDictionary alloc]init];
    
    d[@"name"] = self.layerName;
    d[@"link-state-control"] = [lscState description];
    d[@"initial-alignment-control-state"] = [iacState description];
    d[@"attach-to"] = sctpLink.layerName;
    d[@"local-processor-outage"] = local_processor_outage ? @(YES) : @(NO);
    d[@"remote-processor-outage"] = remote_processor_outage ? @(YES) : @(NO);
    d[@"level3-indication"] = level3Indication ? @(YES) : @(NO);
    d[@"slc"] = @(slc);
    d[@"network-indicator"] = @(networkIndicator);
    d[@"bsn"] = @(bsn);
    d[@"fsn"] = @(fsn);
    d[@"bsn2"] = @(bsn2);
    d[@"outstanding"] = @(outstanding);
    
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
    d[@"congested"] = congested ? @(YES) : @(NO);
    d[@"emergency"] = emergency ? @(YES) : @(NO);
    d[@"autostart"] = autostart ? @(YES) : @(NO);
    d[@"paused"] = paused ? @(YES) : @(NO);
    d[@"link-restarts"] = link_restarts ? @(YES) : @(NO);
    d[@"ready-received"] = @(ready_received);
    d[@"ready-sent"] = @(ready_sent);
    d[@"reception-enabled"] = receptionEnabled ? @(YES) : @(NO);
    d[@"configured-speed"] = @(speed);
    d[@"window-size"] = @(window_size);
    d[@"current-speed"] =   [speedometer getSpeedTripleJson];
    d[@"submission-speed"] =   [submission_speed getSpeedTripleJson];


    static NSDateFormatter *dateFormatter = NULL;
    
    if(dateFormatter==NULL)
    {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
        [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
    }
    if(link_up_time)
    {
        d[@"link-up-time"] =  [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:link_up_time]];
    }
    if(link_down_time)
    {
        d[@"link-down-time"] =  [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:link_down_time]];
    }
    if(link_congestion_time)
    {
        d[@"link-congestion-time"] =  [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:link_congestion_time]];
    }
    if(link_congestion_cleared_time)
    {
        d[@"link-congestion-cleared-time"] =  [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:link_congestion_cleared_time]];
    }
    if(link_speed_excess_time)
    {
        d[@"link-speed-excess-time"] =  [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:link_speed_excess_time]];
    }
    if(link_speed_excess_cleared_time)
    {
        d[@"link-speed-excess-cleared-time"] =  [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:link_speed_excess_cleared_time]];
    }
    if(speed_status == SPEED_WITHIN_LIMIT)
    {
        d[@"speed-status"] = @"within-limit";
    }
    else
    {
        d[@"speed-status"] = @"speed-exceeded";
    }
    d[@"waiting-messages-count"] = @(waitingMessages.count);

    return d;
}

- (void)stopDetachAndDestroy
{
    /* FIXME: do something here */
}

@end
