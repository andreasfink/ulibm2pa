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

 CS7 M2PA Timers for RFC
 
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
/* all timers are  in seconds */
#define	M2PA_DEFAULT_T1	45.000000 /* 45s */
/* T1:  alignment ready */
/*  highspeed: 25-350s */
/*  64k link: 40-50s	*/
/*  4.8k: 500-600s */

#define	M2PA_DEFAULT_T2	6.0 /* 6s */
/* T2: not aligned */
/* low: 5-50s */
/* high: 70-150s */

#define	M2PA_DEFAULT_T3	2.0 /* 2sec */
/* T2: aligned  */
/* 1-2s */

#define	M2PA_DEFAULT_T4_N	8.0		/* normal proving period  3-70s  8s */
#define	M2PA_DEFAULT_T4_E	0.5     /* emergency proving period  0.4s - 0.6s : 0.5s*/
#define	M2PA_DEFAULT_T4_R	0.150   /* resending timer of link status proving every 150ms */
/*T4: proving period normal */
/*  highspeed: 3-70s */
/*  64k:	7.5-9.5s, nominal 8.5s */
/*  4.8k: 100s-120s, nominal 110s */
/* proving period emergency */
/*  highspeed: 0.4-0.6s */
/*  64k:	0.4-0.5, nominal 0.5s */
/*  4.8k: 6s-8s, nominal 7s */
/* on cisco:   <500-1200>  t04 timer value (in ms) */


#define	M2PA_DEFAULT_T5	0.1 /* 100ms */
/* Timer sending SIB. 80-120ms */

#define	M2PA_DEFAULT_T6	3.5 /*3.5s */
/* Remote congestion */
/* 64k: 3-6s */
/* 4.8k 8-12s */

#define	M2PA_DEFAULT_T7	1.0 /* 1s */
/* excessive delay of acknowledgement */
/* 64k: 0.5-2s */
/* 4.8k 4-6s */

#define    M2PA_DEFAULT_START_TIMER    30.0 /* 30s */

#define    M2PA_DEFAULT_ACK_TIMER    0.250 /* 250ms */

/* how many outstanding unacknowledgedpackets are allowed */
#define    M2PA_DEFAULT_WINDOW_SIZE     128

// RFC4165

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

typedef enum PocStatus
{
	PocStatus_idle,
	PocStatus_inService,
} PocStatus;

@class UMM2PAState;

@interface UMLayerM2PA : UMLayer<UMLayerSctpUserProtocol>
{
    UMSynchronizedArray 				*_users;
    UMM2PAState                         *_state;
    UMLogFeed                           *_stateMachineLogFeed;
    UMMutex 							*_seqNumLock;
    UMMutex 							*_dataLock;
    UMMutex 							*_controlLock;
    UMMutex 							*_incomingDataBufferLock;
    int                                 _linkstateOutOfServiceReceived;
    int                                 _linkstateOutOfServiceSent;
    int                                 _linkstateAlignmentReceived;
    int                                 _linkstateAlignmentSent;
    int                                 _linkstateProvingReceived;
    int                                 _linkstateProvingSent;
    int                                 _linkstateProcessorOutageReceived;
    int                                 _linkstateProcessorOutageSent;
    int                                 _linkstateProcessorRecoveredReceived;
    int                                 _linkstateProcessorRecoveredSent;
    int                                 _linkstateBusyReceived;
    int                                 _linkstateBusySent;
    int                                 _linkstateBusyEndedReceived;
    int                                 _linkstateBusyEndedSent;
    int                                 _linkstateReadyReceived;
    int                                 _linkstateReadySent;
    int                                 _sctpUpReceived;
    int                                 _sctpDownReceived;
    int                                 _powerOnCounter;
    int                                 _powerOffCounter;
    int                                 _startCounter;
    int                                 _stopCounter;

    BOOL    							_local_processor_outage;
    BOOL    							_remote_processor_outage;
    BOOL    							_level3Indication;
    int     							_slc;
	BOOL								_linkstate_busy;
    BOOL                                _forcedOutOfService;
    u_int32_t							_bsn; /* backward sequence number. Last Sequence number received from the peer */
    u_int32_t							_fsn; /* forward sequence number. Last sequence number sent */
    u_int32_t							_bsn2; /* backward sequence number. Last FSN number acked from the peer for our transmission */

    u_int32_t                            _lastRxFsn;    /* last received FSN */
    u_int32_t                            _lastRxBsn;    /* last received BSN */

    u_int32_t                            _lastTxFsn;    /* last sent FSN */
    u_int32_t                            _lastTxBsn;    /* last sent BSN */

    u_int32_t							_outstanding;
    NSTimeInterval      				_t4n;
    NSTimeInterval      				_t4e;
    UMLayerSctp     					*_sctpLink;

	UMTimer    *_t1;	/* Timer "alignment ready" */
		/* Starts when entering PROVING state. Stops when AlignmentReady is received */
		/* recommended values: 			*/
		/* 64kbps:	 T1 = 40-50s		*/
		/* 4.8kbps: T1 = 500-600s		*/
		/* Following successful alignment and proving procedure, the signalling terminal enters Aligned Ready state and the aligned ready time-out T1 is stopped on entry in the In-service state and the duration of time-out T1 should be chosen such that the remote end can perform four additional proving attempts. */

    UMTimer    *_t2;	/* Timer "not aligned" */
		/* recommended values: 			*/
		/* 64kbps T2 = 5-150 s 			*/
		/* 4.8kbps: T2 = 5-50 s 		*/

    UMTimer    *_t3;	/* Timer "aligned" */
		/* recommended value: 1-2s 			*/

    UMTimer    *_t4;	/* Proving period timer = 2^16 or 2^32 octet transmission time */
		/*
		 	T4n (64) = 7.5-9.5 s Nominal value 8.2 s
		 	T4n (4.8) = 100-120 s Nominal value 110 s
		 	T4e (64) = 400-600 ms Nominal value 500 ms
		 	T4e (4.8) = 6-8 s Nominal value 7 s
		 	Expiry of timer T4 (see 12.3) indicates a successful proving period unless the proving
		 	period has been previously aborted up to four times.
		 */
    UMTimer    *_t4r;	/* intervall to send alignment messages */
    UMTimer    *_t5; /* Timer T5 "sending SIB" */
		/* recommended value: 80-120ms */

    UMTimer    *_t6;	/* Timer T6 "remote congestion" */
		/* Recommended Values:
		 	T6 (64) = 3-6 s
		 	T6 (4.8) = 8-12 s
	 	*/
    UMTimer    *_t7;	/* Timer T7 "excessive delay of acknowledgement" */
		/* Recommended Values:
		 	T7 (64) = 0.5-2 s	Bit rate of 64 kbit/s
		 	For PCR method		Values less than 0.8s should not be used
		 	T7 (4.8) = 4-6 s	Bit rate of 4.8 kbit/s
		 */
		/* A timing mechanism, timer T7, shall be provided which generates an indication of excessive delay of acknowledgement if, assuming that there is at least one outstanding MSU in the retransmission buffer, no new acknowledgement has been received within a time-out T7 (see 12.3). In the case of excessive delay in the reception of acknowledgements, a link failure indications is given to level 3. */

    UMTimer    *_ackTimer;    /* if no MSU is being sent and there is outstanding ACKs from the other side we have to send empty MSUs */
    UMTimer    *_startTimer;    /* time between SCTP power on retries in case SCTP doesnt come up */

    
    UMSocketStatus _sctp_status;
    
    BOOL    _congested;
    BOOL    _emergency;
    //BOOL    _autostart;
    int     _link_restarts;
    int     _ready_sent;
    BOOL    _paused;
	BOOL	_furtherProving;
    BOOL    _receptionEnabled;
    double  _speed;
    int     _window_size;
	PocStatus	        _pocStatus;

    UMThroughputCounter	*_submission_speed; /* how fast MTP3 sends us data */
    UMThroughputCounter *_inboundThroughputPackets;
    UMThroughputCounter *_outboundThroughputPackets;
    UMThroughputCounter *_inboundThroughputBytes;
    UMThroughputCounter *_outboundThroughputBytes;

    NSDate	*_link_up_time;
    NSDate	*_link_down_time;
    NSDate	*_link_congestion_time;
    NSDate	*_link_speed_excess_time;
    NSDate	*_link_congestion_cleared_time;
    NSDate	*_link_speed_excess_cleared_time;

    NSMutableData 	*_data_link_buffer;
    NSMutableData 	*_control_link_buffer;
    SpeedStatus 	_speed_status;
    UMQueueSingle   *_waitingMessages;
}

- (UMM2PAState *)state;
- (void)setState:(UMM2PAState *)state;
@property(readwrite,strong)     UMLogFeed *stateMachineLogFeed;

@property(readwrite,strong)     UMLayerSctp                         *sctpLink;
@property(readwrite,strong)     UMTimer    *startTimer;    /* time between SCTP power on retries in case SCTP doesnt come up */


@property(readwrite,assign)     int slc;
@property(readwrite,strong)     UMThroughputCounter *inboundThroughputPackets;
@property(readwrite,strong)     UMThroughputCounter *outboundThroughputPackets;
@property(readwrite,strong)     UMThroughputCounter *inboundThroughputBytes;
@property(readwrite,strong)     UMThroughputCounter *outboundThroughputBytes;
@property(readwrite,strong)     UMThroughputCounter *submission_speed;

@property(readwrite,assign)     BOOL    congested;
@property(readwrite,assign)     BOOL    local_processor_outage;
@property(readwrite,assign)     BOOL    remote_processor_outage;
@property(readwrite,assign)     BOOL    level3Indication;

@property(readwrite,assign)     BOOL    emergency;
@property(readwrite,assign)     int     link_restarts;
@property(readwrite,assign)     int     ready_sent;
@property(readwrite,assign)     BOOL    paused;
@property(readwrite,assign)     double  speed;
@property(readwrite,assign)     int     window_size;
@property(readwrite,assign)     BOOL    furtherProving;
@property(readwrite,assign)     u_int32_t outstanding;

@property(readwrite,strong)     UMTimer  *t1;       /* T1:  alignment ready */
@property(readwrite,strong)     UMTimer  *t2;      	/* T2: not aligned */
@property(readwrite,strong)     UMTimer  *t3;
@property(readwrite,strong)     UMTimer  *t4;
@property(readwrite,strong)     UMTimer  *t4r;
@property(readwrite,strong)     UMTimer  *t5;
@property(readwrite,strong)     UMTimer  *t6;
@property(readwrite,strong)     UMTimer  *t7;
@property(readwrite,strong)     UMTimer  *ackTimer;
@property(readwrite,assign)     NSTimeInterval      t4n;
@property(readwrite,assign)     NSTimeInterval      t4e;
//@property(readwrite,assign,atomic) M2PA_Status m2pa_status; // this one has proper getter and setter 
@property(readwrite,assign,atomic) UMSocketStatus sctp_status;
@property(readwrite,assign,atomic)  SpeedStatus speed_status;

@property(readwrite,assign,atomic)  int linkstateOutOfServiceReceived;
@property(readwrite,assign,atomic)  int linkstateOutOfServiceSent;
@property(readwrite,assign,atomic)  int linkstateAlignmentReceived;
@property(readwrite,assign,atomic)  int linkstateAlignmentSent;
@property(readwrite,assign,atomic)  int linkstateProvingReceived;
@property(readwrite,assign,atomic)  int linkstateProvingSent;
@property(readwrite,assign,atomic)  int linkstateProcessorOutageReceived;
@property(readwrite,assign,atomic)  int linkstateProcessorOutageSent;
@property(readwrite,assign,atomic)  int linkstateProcessorRecoveredReceived;
@property(readwrite,assign,atomic)  int linkstateProcessorRecoveredSent;
@property(readwrite,assign,atomic)  int linkstateBusyReceived;
@property(readwrite,assign,atomic)  int linkstateBusySent;
@property(readwrite,assign,atomic)  int linkstateBusyEndedReceived;
@property(readwrite,assign,atomic)  int linkstateBusyEndedSent;
@property(readwrite,assign,atomic)  int linkstateReadyReceived;
@property(readwrite,assign,atomic)  int linkstateReadySent;
@property(readwrite,assign,atomic)  int sctpUpReceived;
@property(readwrite,assign,atomic)  int sctpDownReceived;
@property(readwrite,assign,atomic)  int startCounter;
@property(readwrite,assign,atomic)  int stopCounter;
@property(readwrite,assign,atomic)  int powerOnCounter;
@property(readwrite,assign,atomic)  int powerOffCounter;
@property(readwrite,assign,atomic)  BOOL forcedOutOfService;
@property(readonly,strong,atomic)   UMMutex *dataLock;
@property(readonly,strong,atomic)   UMMutex *controlLock;


- (UMLayerM2PA *)initWithTaskQueueMulti:(UMTaskQueueMulti *)tq;
- (UMLayerM2PA *)initWithTaskQueueMulti:(UMTaskQueueMulti *)tq name:(NSString *)name;

#pragma mark -
#pragma mark SCTP Callbacks


- (void) sctpStatusIndication:(UMLayer *)caller
                       userId:(id)uid
                       status:(UMSocketStatus)s;

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

- (void)ackTimerFires;

#pragma mark -
#pragma mark Task Creators
- (void)adminInit;
- (void)adminSetConfig:(NSDictionary *)cfg applicationContext:(id<UMLayerM2PAApplicationContextProtocol>)appContext;

- (void)setConfig:(NSDictionary *)cfg applicationContext:(id)appContext;
- (NSDictionary *)config;

- (void)adminAttachFor:(id<UMLayerM2PAUserProtocol>)caller;
- (void)adminAttachFor:(id<UMLayerM2PAUserProtocol>)caller
               profile:(UMLayerM2PAUserProfile *)p
			  linkName:(NSString *)linkName
                   slc:(int)slc;

- (void)dataFor:(id<UMLayerM2PAUserProtocol>)caller
           data:(NSData *)sendingData
     ackRequest:(NSDictionary *)ack;


- (void)powerOnFor:(id<UMLayerM2PAUserProtocol>)caller;
- (void)powerOffFor:(id<UMLayerM2PAUserProtocol>)caller;
- (void)startFor:(id<UMLayerM2PAUserProtocol>)caller;
- (void)stopFor:(id<UMLayerM2PAUserProtocol>)caller;
- (void)powerOnFor:(id<UMLayerM2PAUserProtocol>)caller forced:(BOOL)forced;
- (void)powerOffFor:(id<UMLayerM2PAUserProtocol>)caller forced:(BOOL)forced;
- (void)startFor:(id<UMLayerM2PAUserProtocol>)caller forced:(BOOL)forced;
- (void)stopFor:(id<UMLayerM2PAUserProtocol>)caller forced:(BOOL)forced;

- (void)emergencyFor:(id<UMLayerM2PAUserProtocol>)caller;
- (void)emergencyCheasesFor:(id<UMLayerM2PAUserProtocol>)caller;

//- (void)stopFoosFor:(id<UMLayerM2PAUserProtocol>)caller;

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
+ (NSString *)linkStatusString:(M2PA_linkstate_message) linkstate;
+ (NSString *)m2paStatusString:(M2PA_Status) linkstate;
- (void) sendCongestionClearedIndication;
- (void) sendCongestionIndication;



-(void)cancelProcessorOutage;
-(void)cancelLocalProcessorOutage;

-(void)cancelEmergency;
-(void)markFurtherProving;
-(void)cancelFurtherProving;

- (void)notifyMtp3UserData:(NSData *)userData;
- (void)notifyMtp3OutOfService;
- (void)notifyMtp3RemoteProcessorOutage;
- (void)notifyMtp3RemoteProcessorRecovered;
- (void)notifyMtp3Congestion;
- (void)notifyMtp3CongestionCleared;
- (void)notifyMtp3InService;
- (void)notifyMtp3Stop;

-(void)protocolViolation:(NSString *)reason;
-(void)protocolViolation;
- (void)setM2pa_status:(M2PA_Status)status;
- (M2PA_Status)m2pa_status;
- (void)resetSequenceNumbers;
- (NSDictionary *)apiStatus;
- (void)stopDetachAndDestroy;
- (void)queueTimerEvent:(id)caller timerName:(NSString *)tname;
- (void)startupInitialisation;
- (void)sendData:(NSData *)data
          stream:(uint16_t)streamId
      ackRequest:(NSDictionary *)ackRequest;

@end
