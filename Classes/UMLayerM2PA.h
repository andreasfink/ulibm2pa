//
//  UMLayerM2PA.h
//  ulibm2pa
//
//  Created by Andreas Fink on 01.12.14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import <ulib/ulib.h>
#import <ulibsctp/ulibsctp.h>
#import "UMLayerM2PAUserProtocol.h"
#import "UMLayerM2PAApplicationContextProtocol.h"

@class UMM2PATask_sctpStatusIndication;
@class UMM2PATask_sctpDataIndication;
@class UMM2PATask_sctpMonitorIndication;

@class UMM2PATask_AdminInit;
@class UMM2PATask_AdminSetConfig;
@class UMM2PATask_AdminAttach;
@class UMM2PATask_Data;
@class UMM2PATask_PowerOn;
@class UMM2PATask_PowerOff;
@class UMM2PATask_Start;
@class UMM2PATask_Stop;
@class UMM2PATask_Emergency;
@class UMM2PATask_EmergencyCheases;
@class UMM2PATask_SetSlc;
@class UMM2PATask_TimerEvent;
@class UMM2PATask_AdminAttachOrder;
@class UMM2PATask_AdminDetachOrder;
@class UMM2PALinkStateControl_State;
@class UMM2PAInitialAlignmentControl_State;
@class UMLayerM2PAUserProfile;

/* on Cisco ITP  the following values are default:
 
 zurich3#show cs7 m2pa timers XG5
 
 CS7 M2PA Timers for RFC    (85.195.192.42 : 3000)
 
 T1   (alignment ready)   : 45000    ms
 T2   (not aligned)       : 60000    ms
 T3   (aligned)           : 2000     ms
 T4   (emergency proving) : 500      ms
 T4   (normal proving)    : 8000     ms
 T6   (remote congestion) : 4000     ms
 T7   (excess ack delay)  : 0        ms
 Lssu (lssu interval)     : 4000     ms
 
 */

/* default timer values */
/* all timers are  in microseconds */
#define	M2PA_DEFAULT_T1	45000000LL /* 45s */
/* T1:  alignment ready */
/*  highspeed: 25-350s */
/*  64k link: 40-50s	*/
/*  4.8k: 500-600s */

#define	M2PA_DEFAULT_T2	60000000LL /* 6s */
/* T2: not aligned */
/* low: 5-50s */
/* high: 70-150s */

#define	M2PA_DEFAULT_T3	2000000LL /* 2sec */
/* T2: aligned  */
/* 1-2s */

#define	M2PA_DEFAULT_T4_N	8000000LL		/* normal proving period  3-70s  8s */
#define	M2PA_DEFAULT_T4_E	500000LL        /* emergency proving period  0.4s - 0.6s : 0.5s*/
#define	M2PA_DEFAULT_T4_R	2000000LL		/* resending timer of link status proving every 2 seconds */
/*T4: proving period normal */
/*  highspeed: 3-70s */
/*  64k:	7.5-9.5s, nominal 8.5s */
/*  4.8k: 100s-120s, nominal 110s */
/* proving period emergency */
/*  highspeed: 0.4-0.6s */
/*  64k:	0.4-0.5, nominal 0.5s */
/*  4.8k: 6s-8s, nominal 7s */
/* on cisco:   <500-1200>  t04 timer value (in ms) */


#define	M2PA_DEFAULT_T5	100000LL /* 100ms */
/* Timer sending SIB. 80-120ms */

#define	M2PA_DEFAULT_T6	3500000LL /*3.5s */
/* Remote congestion */
/* 64k: 3-6s */
/* 4.8k 8-12s */

#define	M2PA_DEFAULT_T7	1000000LL /* 1s */
/* excessive delay of acknowledgement */
/* 64k: 0.5-2s */
/* 4.8k 4-6s */


//Request for Comments: 4165                                B. Bidulock

#define	SCTP_PROTOCOL_IDENTIFIER_M2PA	5

#define M2PA_VERSION1                   1
#define M2PA_CLASS_RFC4165              11
#define	M2PA_TYPE_USER_DATA             1
#define	M2PA_TYPE_LINK_STATUS           2

#define	M2PA_STREAM_USERDATA				1
#define	M2PA_STREAM_LINKSTATE				0


#define	FSN_BSN_MASK	0x00FFFFFF
#define	FSN_BSN_SIZE	0x01000000



typedef enum SpeedStatus
{
    SPEED_WITHIN_LIMIT	= 0,
    SPEED_EXCEEDED		= 1,
} SpeedStatus;

@interface UMLayerM2PA : UMLayer<UMLayerSctpUserProtocol>
{
    //NSString *name;
    UMSynchronizedArray *_users;
    NSString *attachTo;
    UMM2PALinkStateControl_State        *lscState;
    UMM2PAInitialAlignmentControl_State *iacState;
    UMMutex *_seqNumLock;
    UMMutex *_dataLock;
    UMMutex *_controlLock;
    UMMutex *_incomingDataBufferLock;

    BOOL    local_processor_outage;
    BOOL    remote_processor_outage;
    BOOL    level3Indication;
    int     slc;
    int     networkIndicator;

    u_int32_t		bsn; /* backward sequence number. Last Sequence number received from the peer */
    u_int32_t		fsn; /* forward sequence number. Last sequence number sent */
    u_int32_t		bsn2; /* backward sequence number. Last FSN number acked from the peer for our transmission */
    u_int32_t		outstanding;
    UMMicroSec      t4n;
    UMMicroSec      t4e;
    UMLayerSctp     *sctpLink;

    UMTimer    *t1;
    UMTimer    *t2;
    UMTimer    *t3;
    UMTimer    *t4;
    UMTimer    *t4r;
    UMTimer    *t5;
    UMTimer    *t6;
    UMTimer    *t7;
    
    SCTP_Status _sctp_status;
    M2PA_Status _m2pa_status;

    BOOL    congested;
    BOOL    emergency;
    BOOL    autostart;
    BOOL    link_restarts;
    int     ready_received;
    int     ready_sent;
    BOOL    paused;
    
    BOOL    receptionEnabled;
    double  speed;
    int     window_size;
    UMThroughputCounter	*speedometer;
    UMThroughputCounter	*submission_speed;

    UMThroughputCounter *_inboundThroughputPackets;
    UMThroughputCounter *_outboundThroughputPackets;
    UMThroughputCounter *_inboundThroughputBytes;
    UMThroughputCounter *_outboundThroughputBytes;

    time_t  link_up_time;
    time_t  link_down_time;
    time_t  link_congestion_time;
    time_t  link_speed_excess_time;
    time_t  link_congestion_cleared_time;
    time_t  link_speed_excess_cleared_time;

    NSMutableData *data_link_buffer;
    NSMutableData *control_link_buffer;
    SpeedStatus speed_status;
    UMQueue *waitingMessages;
}

@property(readwrite,strong)     NSString *name;
@property(readwrite,strong)     UMM2PALinkStateControl_State        *lscState;
@property(readwrite,strong)     UMM2PAInitialAlignmentControl_State *iacState;

@property(readwrite,assign)     int slc;
@property(readwrite,assign)     BOOL inEmergencyMode;
@property(readwrite,strong)     UMThroughputCounter *speedometer;

@property(readwrite,assign)     BOOL    congested;
@property(readwrite,assign)     BOOL    local_processor_outage;
@property(readwrite,assign)     BOOL    remote_processor_outage;
@property(readwrite,assign)     BOOL    level3Indication;

@property(readwrite,assign)     BOOL    emergency;
@property(readwrite,assign)     BOOL    autostart;
@property(readwrite,assign)     BOOL    link_restarts;
@property(readwrite,assign)     int     ready_received;
@property(readwrite,assign)     int     ready_sent;
@property(readwrite,assign)     BOOL    paused;
@property(readwrite,assign)     double  speed;
@property(readwrite,assign)     int     window_size;

@property(readwrite,strong)     UMTimer  *t1;       /* T1:  alignment ready */
@property(readwrite,strong)     UMTimer  *t2;      	/* T2: not aligned */
@property(readwrite,strong)     UMTimer  *t3;
@property(readwrite,strong)     UMTimer  *t4;
@property(readwrite,strong)     UMTimer  *t4r;
@property(readwrite,strong)     UMTimer  *t5;
@property(readwrite,strong)     UMTimer  *t6;
@property(readwrite,strong)     UMTimer  *t7;
@property(readwrite,assign)     UMMicroSec      t4n;
@property(readwrite,assign)     UMMicroSec      t4e;
@property(readwrite,assign,atomic) M2PA_Status m2pa_status;
@property(readwrite,assign,atomic) SCTP_Status sctp_status;
@property(readwrite,strong,atomic)  UMThroughputCounter *inboundThroughputPackets;
@property(readwrite,strong,atomic)  UMThroughputCounter *outboundThroughputPackets;
@property(readwrite,strong,atomic)  UMThroughputCounter *inboundThroughputBytes;
@property(readwrite,strong,atomic)  UMThroughputCounter *outboundThroughputBytes;
@property(readwrite,assign,atomic)  SpeedStatus speed_status;

- (UMLayerM2PA *)initWithTaskQueueMulti:(UMTaskQueueMulti *)tq;
- (UMLayerM2PA *)initWithTaskQueueMulti:(UMTaskQueueMulti *)tq name:(NSString *)name;

#pragma mark -
#pragma mark SCTP Callbacks


- (void) sctpStatusIndication:(UMLayer *)caller
                       userId:(id)uid
                       status:(SCTP_Status)s;

- (void) sctpDataIndication:(UMLayer *)caller
                     userId:(id)uid
                   streamId:(uint16_t)sid
                 protocolId:(uint32_t)pid
                       data:(NSData *)d;


- (void) sctpMonitorIndication:(UMLayer *)caller
                        userId:(id)uid
                      streamId:(uint16_t)sid
                    protocolId:(uint32_t)pid
                          data:(NSData *)d
                      incoming:(BOOL)in;


#pragma mark -
#pragma mark SCTP Callback Tasks

- (void) _sctpStatusIndicationTask:(UMM2PATask_sctpStatusIndication *)task;
- (void) _sctpDataIndicationTask:(UMM2PATask_sctpDataIndication *)task;
- (void) _sctpMonitorIndicationTask:(UMM2PATask_sctpMonitorIndication *)task;

#pragma mark -
#pragma mark Admin Callbacks called from SCTP

- (void) adminAttachConfirm:(UMLayer *)attachedLayer
                     userId:(id)uid;

- (void) adminAttachFail:(UMLayer *)attachedLayer
                  userId:(id)uid
                  reason:(NSString *)reason;

- (void) adminDetachConfirm:(UMLayer *)attachedLayer
                     userId:(id)uid;

- (void) adminDetachFail:(UMLayer *)attachedLayer
                  userId:(id)uid
                  reason:(NSString *)reason;

- (void)sentAckConfirmFrom:(UMLayer *)sender
                  userInfo:(NSDictionary *)userInfo;
- (void)sentAckFailureFrom:(UMLayer *)sender
                  userInfo:(NSDictionary *)userInfo
                     error:(NSString *)err
                    reason:(NSString *)reason
                 errorInfo:(NSDictionary *)ei;

- (void)adminAttachOrder:(UMLayerSctp *)sctp_layer;


#pragma mark -
#pragma mark Timer Callbacks
- (void)timerFires1;
- (void)timerFires2;
- (void)timerFires3;
- (void)timerFires4;
- (void)timerFires4r;
- (void)timerFires5;
- (void)timerFires6;
- (void)timerFires7;
- (void)_timerFires1;
- (void)_timerFires2;
- (void)_timerFires3;
- (void)_timerFires4;
- (void)_timerFires4r;
- (void)_timerFires5;
- (void)_timerFires6;
- (void)_timerFires7;

#pragma mark -
#pragma mark Task Creators
- (void)adminInit;
- (void)adminSetConfig:(NSDictionary *)cfg applicationContext:(id<UMLayerM2PAApplicationContextProtocol>)appContext;

- (void)setConfig:(NSDictionary *)cfg applicationContext:(id)appContext;
- (NSDictionary *)config;

- (void)adminAttachFor:(id<UMLayerM2PAUserProtocol>)caller;
- (void)adminAttachFor:(id<UMLayerM2PAUserProtocol>)caller
               profile:(UMLayerM2PAUserProfile *)p
                userId:(id)uid
                    ni:(int)ni
                   slc:(int)slc;

- (void)dataFor:(id<UMLayerM2PAUserProtocol>)caller
           data:(NSData *)sendingData
     ackRequest:(NSDictionary *)ack;

- (void)timerEvent:(id<UMLayerM2PAUserProtocol>)caller timerNr:(int)tnr;

- (void)powerOnFor:(id<UMLayerM2PAUserProtocol>)caller;
- (void)powerOffFor:(id<UMLayerM2PAUserProtocol>)caller;
- (void)emergencyFor:(id<UMLayerM2PAUserProtocol>)caller;
- (void)emergencyCheasesFor:(id<UMLayerM2PAUserProtocol>)caller;
- (void)startFor:(id<UMLayerM2PAUserProtocol>)caller;
- (void)stopFor:(id<UMLayerM2PAUserProtocol>)caller;

/* LAYER API. The following methods are called by queued tasks */
#pragma mark -
#pragma mark Task Executors

- (void)_adminInitTask:(UMM2PATask_AdminInit *)task;
- (void)_adminSetConfigTask:(UMM2PATask_AdminSetConfig *)task;
- (void)_adminAttachTask:(UMM2PATask_AdminAttach *)task;
- (void)_adminAttachOrderTask:(UMM2PATask_AdminAttachOrder *)task;
- (void)_adminDetachOrderTask:(UMM2PATask_AdminDetachOrder *)task;
- (void)_powerOnTask:(UMM2PATask_PowerOn *)task;
- (void)_powerOffTask:(UMM2PATask_PowerOff *)task;
- (void)_startTask:(UMM2PATask_Start *)task;
- (void)_stopTask:(UMM2PATask_Stop *)task;
- (void)_emergencyTask:(UMM2PATask_Emergency *)task;
- (void)_emergencyCheasesTask:(UMM2PATask_EmergencyCheases *)task;
- (void)_setSlcTask:(UMM2PATask_SetSlc *)task;
- (void)_timerEventTask:(UMM2PATask_TimerEvent *)task;
- (void)_dataTask:(UMM2PATask_Data *)task;

- (void)checkSpeed;
- (void) sendLinkstatus:(M2PA_linkstate_message)linkstate;
- (void) sctpIncomingDataMessage:(NSData *)data;
- (void) sctpIncomingLinkstateMessage:(NSData *)data;
- (NSString *)linkStatusString:(M2PA_linkstate_message) linkstate;
- (NSString *)m2paStatusString:(M2PA_Status) linkstate;
- (void) sendCongestionClearedIndication;
- (void) sendCongestionIndication;



-(void)cancelProcessorOutage;
-(void)cancelLocalProcessorOutage;

-(void)cancelEmergency;
-(void)rcStart;
-(void)rcStop;

-(void)txcStart;
-(void)txcSendSIOS;
-(void)txcSendSIPO;
-(void)txcSendFISU;
-(void)txcSendMSU:(NSData *)msu ackRequest:(NSDictionary *)ackRequest;
-(void)txcSendSIO;
-(void)txcSendSIN;
-(void)txcSendSIE;
-(void)txcFlushBuffers;

-(void)iacEmergency;
-(void)iacEmergencyCeases;
-(void)iacStart;
-(void)iacStop;
-(void)suermStart;
-(void)suermStop;

-(void)aermStop;
-(void)aermStart;
-(void)aermSetTe;

-(void)pocLocalProcessorOutage;
-(void)pocRemoteProcessorOutage;
-(void)pocLocalProcessorRecovered;
-(void)pocRemoteProcessorRecovered;
-(void)pocStop;

-(void)rcRejectMsuFisu;
-(void)rcAcceptMsuFisu;
-(void)notifyMtp3OutOfService;
-(void)notifyMtp3RemoteProcessorOutage;
-(void)notifyMtp3RemoteProcessorRecovered;
-(void)notifyMtp3InService;
-(void)notifyMtp3Stop;

-(void)lscAlignmentNotPossible;
-(void)lscAlignmentComplete;

-(void)protocolViolation;
-(void)setM2pa_status:(M2PA_Status)status;
- (void)resetSequenceNumbers;
- (NSDictionary *)apiStatus;
- (void)stopDetachAndDestroy;

@end
