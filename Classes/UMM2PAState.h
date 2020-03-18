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
}

@property(readwrite,strong) UMLayerM2PA *link;

- (NSString *)description;
- (M2PA_Status)statusCode;

- (UMM2PAState *)initWithLink:(UMLayerM2PA *)link;
- (void)logStatemachineEvent:(const char *)func;

- (UMM2PAState *)eventStop;
- (UMM2PAState *)eventStart;
- (UMM2PAState *)eventSctpUp;
- (UMM2PAState *)eventSctpDown;
- (UMM2PAState *)eventLinkstatusOutOfService;
- (UMM2PAState *)eventEmergency;
- (UMM2PAState *)eventEmergencyCeases;
- (UMM2PAState *)eventLinkstatusAlignment;
- (UMM2PAState *)eventLinkstatusProvingNormal;
- (UMM2PAState *)eventLinkstatusProvingEmergency;
- (UMM2PAState *)eventLinkstatusReady;
- (UMM2PAState *)eventLinkstatusBusy;
- (UMM2PAState *)eventLinkstatusBusyEnded;
- (UMM2PAState *)eventLinkstatusProcessorOutage;
- (UMM2PAState *)eventLinkstatusProcessorRecovered;
- (UMM2PAState *)eventUserData:(NSData *)data;
- (UMM2PAState *)eventSctpError;

- (UMM2PAState *)eventTimer1;
- (UMM2PAState *)eventTimer2;
- (UMM2PAState *)eventTimer3;
- (UMM2PAState *)eventTimer4;
- (UMM2PAState *)eventTimer4r;
- (UMM2PAState *)eventTimer5;
- (UMM2PAState *)eventTimer6;
- (UMM2PAState *)eventTimer7;


- (void) sendLinkstateAlignment;
- (void) sendLinkstateProvingNormal;
- (void) sendLinkstateProvingEmergency;
- (void) sendLinkstateReady;
- (void) sendLinkstateProcessorOutage;
- (void) sendLinkstateProcessorRecovered;
- (void) sendLinkstateBusy;
- (void) sendLinkstateBusyEnded;
- (void) sendLinkstateOutOfService;

@end

