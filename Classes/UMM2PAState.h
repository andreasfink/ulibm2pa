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
- (void) logStatemachineEventString:(NSString *)str;
- (void) logStatemachineEventString:(NSString *)str forced:(BOOL)forced;
- (UMM2PAState *)eventPowerOn;                      /* switch on the wire */
- (UMM2PAState *)eventPowerOff;                     /* switch off the wire */
- (UMM2PAState *)eventStart;                        /* start the alignment process */
- (UMM2PAState *)eventStop;                         /* stop the link */
- (UMM2PAState *)eventSctpUp;                       /* SCTP reports the 'wire' has come up*/
- (UMM2PAState *)eventSctpDown;                     /* SCTP reports the conncetion is lost */
- (UMM2PAState *)eventSctpError;                    /* SCTP reports an error */
- (UMM2PAState *)eventEmergency;                    /* MTP3 tells his is an emergency link */
- (UMM2PAState *)eventEmergencyCeases;              /* MTP3 tells his is not an emergency link */
- (UMM2PAState *)eventLinkstatusOutOfService;       /* other side sent us linkstatus out of service */
- (UMM2PAState *)eventLinkstatusAlignment;          /* other side sent us linkstatus alignment */
- (UMM2PAState *)eventLinkstatusProvingNormal;      /* other side sent us linkstatus proving normal */
- (UMM2PAState *)eventLinkstatusProvingEmergency;   /* other side sent us linkstatus emergency normal */
- (UMM2PAState *)eventLinkstatusReady;              /* other side sent us linkstatus ready */
- (UMM2PAState *)eventLinkstatusBusy;               /* other side sent us linkstatus busy */
- (UMM2PAState *)eventLinkstatusBusyEnded;          /* other side sent us linkstatus busy ended */
- (UMM2PAState *)eventLinkstatusProcessorOutage;    /* other side sent us linkstatus processor outage */
- (UMM2PAState *)eventLinkstatusProcessorRecovered; /* other side sent us linkstatus processor recovered */
- (UMM2PAState *)eventSendUserData:(NSData *)data ackRequest:(NSDictionary *)ackRequest dpc:(int)dpc;
- (UMM2PAState *)eventReceiveUserData:(NSData *)userData;


- (UMM2PAState *)eventTimer1;                       /* timer 1 fired (alignment ready timer) */
- (UMM2PAState *)eventTimer1r;                      /* timer 1r fired (time to send alignment ready) */
- (UMM2PAState *)eventTimer2;                       /* timer 2 fired (not aligned timer) */
- (UMM2PAState *)eventTimer3;                       /* timer 3 fired (waiting for first proving. alignment timer) */
- (UMM2PAState *)eventTimer4;                       /* timer 4 fired (proving period) */
- (UMM2PAState *)eventTimer4r;                      /* timer 4r fired (time between proving packets being sent) */
- (UMM2PAState *)eventTimer5;                       /* timer 5 fired */
- (UMM2PAState *)eventTimer6;                       /* timer 6 fired (remote congestion timer.
                                                            if remote stays longer than this, we go OOS) */
- (UMM2PAState *)eventTimer7;                       /* timer 7 fired ((excessive delay of acknowledgement) */

/* actions */
- (void) sendLinkstateAlignment:(BOOL)sync;
- (void) sendLinkstateProvingNormal:(BOOL)sync;
- (void) sendLinkstateProvingEmergency:(BOOL)sync;
- (void) sendLinkstateReady:(BOOL)sync;
- (void) sendLinkstateProcessorOutage:(BOOL)sync;
- (void) sendLinkstateProcessorRecovered:(BOOL)sync;
- (void) sendLinkstateBusy:(BOOL)sync;
- (void) sendLinkstateBusyEnded:(BOOL)sync;
- (void) sendLinkstateOutOfService:(BOOL)sync;
@end

