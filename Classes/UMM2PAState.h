//
//  UMM2PAState.h
//  ulibm2pa
//
//  Created by Andreas Fink on 17.03.20.
//  Copyright © 2020 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/ulib.h>

#import "UMLayerM2PAStatus.h"

@class UMLayerM2PA;

@interface UMM2PAState : UMObject
{
    UMLayerM2PA *_link;
    M2PA_Status _statusCode;
}

@property(readwrite,strong) UMLayerM2PA *link;
@property(readonly)         M2PA_Status statusCode;


- (NSString *)description;

- (UMM2PAState *)initWithLink:(UMLayerM2PA *)link status:(M2PA_Status)statusCode;
- (void) logStatemachineEvent:(const char *)func;
- (void) logStatemachineEvent:(const char *)func forced:(BOOL)forced;
- (void) logStatemachineEvent:(const char *)func socketNumber:(NSNumber *)socketNumber;
- (void) logStatemachineEvent:(const char *)func forced:(BOOL)forced socketNumber:(NSNumber *)socketNumber;
- (void) logStatemachineEventString:(NSString *)str;
- (void) logStatemachineEventString:(NSString *)str forced:(BOOL)forced;

#pragma mark -
#pragma mark event handlers
- (UMM2PAState *)eventPowerOn;                      /* switch on the wire */
- (UMM2PAState *)eventPowerOff;                     /* switch off the wire */
- (UMM2PAState *)eventStart;                        /* start the alignment process */
- (UMM2PAState *)eventStop;                         /* stop the link */
- (UMM2PAState *)eventSctpUp:(NSNumber*)socketNumber;   /* SCTP reports the 'wire' has come up*/
- (UMM2PAState *)eventSctpDown:(NSNumber*)socketNumber; /* SCTP reports the conncetion is lost */
- (UMM2PAState *)eventEmergency;                    /* MTP3 tells his is an emergency link */
- (UMM2PAState *)eventEmergencyCeases;              /* MTP3 tells his is not an emergency link */
- (UMM2PAState *)eventLocalProcessorOutage;         /* MTP3 tells processor is out */
- (UMM2PAState *)eventLocalProcessorRecovery;       /* MTP3 tells processor is back */

#pragma mark -
#pragma mark eventLinkstatus handlers
- (UMM2PAState *)eventLinkstatusOutOfService:(NSNumber *)socketNumber;       /* other side sent us linkstatus out of service SIOS */
- (UMM2PAState *)eventLinkstatusAlignment:(NSNumber *)socketNumber;          /* other side sent us linkstatus alignment SIO */
- (UMM2PAState *)eventLinkstatusProvingNormal:(NSNumber *)socketNumber;      /* other side sent us linkstatus proving normal SIN */
- (UMM2PAState *)eventLinkstatusProvingEmergency:(NSNumber *)socketNumber;   /* other side sent us linkstatus emergency normal SIE */
- (UMM2PAState *)eventLinkstatusReady:(NSNumber *)socketNumber;              /* other side sent us linkstatus ready FISU */
- (UMM2PAState *)eventLinkstatusBusy:(NSNumber *)socketNumber;               /* other side sent us linkstatus busy */
- (UMM2PAState *)eventLinkstatusBusyEnded:(NSNumber *)socketNumber;          /* other side sent us linkstatus busy ended */
- (UMM2PAState *)eventLinkstatusProcessorOutage:(NSNumber *)socketNumber;    /* other side sent us linkstatus processor outage SIPO */
- (UMM2PAState *)eventLinkstatusProcessorRecovered:(NSNumber *)socketNumber; /* other side sent us linkstatus processor recovered */
- (UMM2PAState *)eventSendUserData:(NSData *)data ackRequest:(NSDictionary *)ackRequest dpc:(int)dpc;
- (UMM2PAState *)eventReceiveUserData:(NSData *)userData socketNumber:(NSNumber *)socketNumber;   /* if data is NULL; its FISU, if not its MSU . FISU AT END OF ALIGNMENT IS LINKSTATE READY*/

#pragma mark -
#pragma mark timers
- (UMM2PAState *)eventTimer1;                       /* timer 1 fired (alignment ready timer) */
- (UMM2PAState *)eventTimer1r;                      /* timer 1r fired (time to send alignment ready) */
- (UMM2PAState *)eventTimer2;                       /* timer 2 fired (not aligned timer) */
- (UMM2PAState *)eventTimer3;                       /* timer 3 fired (waiting for first proving. alignment timer) */
- (UMM2PAState *)eventTimer4;                       /* timer 4 fired (proving period) */
- (UMM2PAState *)eventTimer5;                       /* timer 5 fired */
- (UMM2PAState *)eventTimer6;                       /* timer 6 fired (remote congestion timer.
                                                            if remote stays longer than this, we go OOS) */
- (UMM2PAState *)eventTimer7;                       /* timer 7 fired ((excessive delay of acknowledgement) */
- (UMM2PAState *)eventTimer16;                      /* timer 16 fired  */
- (UMM2PAState *)eventTimer17;                      /* timer 17 fired  */
- (UMM2PAState *)eventTimer18;                      /* timer 18 fired  */
- (UMM2PAState *)eventRepeatTimer;                  /* timer OOS repeat fired */


#pragma mark -
#pragma mark actions

- (void) sendLinkstateAlignment:(BOOL)sync;             /* SIO */
- (void) sendLinkstateProvingNormal:(BOOL)sync;         /* SIN */
- (void) sendLinkstateProvingEmergency:(BOOL)sync;      /* SIE */
- (void) sendLinkstateReady:(BOOL)sync;                 /* FISU at end of Alignment */
- (void) sendLinkstateProcessorOutage:(BOOL)sync;       /* SIPO */
- (void) sendLinkstateProcessorRecovered:(BOOL)sync;    /* SIPR */
- (void) sendLinkstateBusy:(BOOL)sync;                  /* BUSY */
- (void) sendLinkstateBusyEnded:(BOOL)sync;
- (void) sendLinkstateOutOfService:(BOOL)sync;          /* SIOS */
@end

