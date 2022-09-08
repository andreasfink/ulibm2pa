//
//  UMM2PAState_Off.m
//  ulibm2pa
//
//  Created by Andreas Fink on 17.03.20.
//  Copyright © 2020 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMM2PAState_Off.h"
#import "UMM2PAState_allStates.h"
#import "UMLayerM2PA.h"


@implementation UMM2PAState_Off

- (UMM2PAState *)initWithLink:(UMLayerM2PA *)link status:(M2PA_Status)statusCode
{
    self =[super initWithLink:link status:M2PA_STATUS_OFF];
    {
        _statusCode = M2PA_STATUS_OFF;
        if(_link.sctpLink.status != UMSOCKET_STATUS_OFF)
        {
            [self eventPowerOff];
        }
    }
    return self;
}


- (NSString *)description
{
    return @"off";
}

#pragma mark -
#pragma mark event handlers

- (UMM2PAState *)eventPowerOn               /* switch on the wire */
{
    [self logStatemachineEvent:__func__];
    [_link startupInitialisation];
    [_link.startTimer start];
    [_link.sctpLink openFor:_link sendAbortFirst:YES reason:@"eventPowerOn"];
    [_link notifyMtp3Off];
    return self;
}

- (UMM2PAState *)eventPowerOff          /* switch off the wire */
{
    [self logStatemachineEvent:__func__];
    [_link.sctpLink closeFor:_link reason:@"eventPowerOff"];
    [_link notifyMtp3Disconnected];
    return self;
}

- (UMM2PAState *)eventStart             /* start the alignment process */
{
    [self logStatemachineEvent:__func__];
    /* this shoud only occur in status OOS not in status OFF*/
    return self;
}

- (UMM2PAState *)eventStop                  /* stop the link */
{
    [self logStatemachineEvent:__func__];
    [_link.sctpLink closeFor:_link reason:@"eventStop"];
    return self;
}

- (UMM2PAState *)eventSctpUp                /* SCTP reports the 'wire' has come up*/
{
    [self logStatemachineEvent:__func__];
    [_link.startTimer stop];
    [_link startupInitialisation];
    [self sendLinkstateOutOfService:YES];
    return [[UMM2PAState_OutOfService alloc]initWithLink:_link status:M2PA_STATUS_OOS];
}

- (UMM2PAState *)eventSctpDown                  /* SCTP reports the conncetion is lost */
{
    [self logStatemachineEvent:__func__];
    [_link.startTimer stop];
    [_link notifyMtp3Stop];
    return self;
}

- (UMM2PAState *)eventEmergency                     /* MTP3 tells his is an emergency link */
{
    [self logStatemachineEvent:__func__];
    _link.emergency = YES;
    return self;
}
    
- (UMM2PAState *)eventEmergencyCeases                /* MTP3 tells his is not an emergency link */
{
    [self logStatemachineEvent:__func__];
    _link.emergency = NO;
    return self;
}


- (UMM2PAState *)eventLocalProcessorOutage            /* MTP3 tells processor is out */
{
    [self logStatemachineEvent:__func__];
    _link.local_processor_outage = YES;
    return self;
}

- (UMM2PAState *)eventLocalProcessorRecovery       /* MTP3 tells processor is back */
{
    [self logStatemachineEvent:__func__];
    _link.local_processor_outage = NO;
    return self;
}

#pragma mark -
#pragma mark eventLinkstatus handlers

- (UMM2PAState *)eventLinkstatusOutOfService    /* other side sent us linkstatus out of service SIOS */
{
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventLinkstatusAlignment       /* other side sent us linkstatus alignment SIO */
{
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventLinkstatusProvingNormal   /* other side sent us linkstatus proving normal SIN */
{
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventLinkstatusProvingEmergency    /* other side sent us linkstatus emergency normal SIE */
{
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventLinkstatusReady               /* other side sent us linkstatus ready FISU */
{
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventLinkstatusBusy                /* other side sent us linkstatus busy */
{
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventLinkstatusBusyEnded           /* other side sent us linkstatus busy ended */
{
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventLinkstatusProcessorOutage         /* other side sent us linkstatus processor outage SIPO */
{
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventLinkstatusProcessorRecovered      /* other side sent us linkstatus processor recovered */
{
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventReceiveUserData:(NSData *)userData
{
    [self logStatemachineEvent:__func__ forced:YES];
    return self;
}

- (UMM2PAState *)eventSendUserData:(NSData *)data
                        ackRequest:(NSDictionary *)ackRequest
                               dpc:(int)dpc
{
    [self logStatemachineEvent:__func__ forced:YES];
    return self;
}

#pragma mark -
#pragma mark timers

- (UMM2PAState *)eventTimer1    /* timer 1 fired (alignment ready timer) */
{
    [self logStatemachineEvent:__func__ forced:YES];
    return self;
}
- (UMM2PAState *)eventTimer1r                      /* timer 1r fired (time to send alignment ready) */
{
    [self logStatemachineEvent:__func__ forced:YES];
    return self;
}
- (UMM2PAState *)eventTimer2                       /* timer 2 fired (not aligned timer) */
{
    [self logStatemachineEvent:__func__ forced:YES];
    return self;
}
- (UMM2PAState *)eventTimer3                       /* timer 3 fired (waiting for first proving. alignment timer) */
{
    [self logStatemachineEvent:__func__ forced:YES];
    return self;
}
- (UMM2PAState *)eventTimer4                       /* timer 4 fired (proving period) */
{
    [self logStatemachineEvent:__func__ forced:YES];
    return self;
}
- (UMM2PAState *)eventTimer4r                      /* timer 4r fired (time between proving packets being sent) */
{
    [self logStatemachineEvent:__func__ forced:YES];
    return self;
}
- (UMM2PAState *)eventTimer5                       /* timer 5 fired */
{
    [self logStatemachineEvent:__func__ forced:YES];
    return self;
}
- (UMM2PAState *)eventTimer6                       /* timer 6 fired (remote congestion timer) */
{
    [self logStatemachineEvent:__func__ forced:YES];
    return self;
}
- (UMM2PAState *)eventTimer7                       /* timer 7 fired ((excessive delay of acknowledgement) */
{
    [self logStatemachineEvent:__func__ forced:YES];
    return self;
}
- (UMM2PAState *)eventTimerOosRepeat               /* timer OOS repeat fired */
{
    [self logStatemachineEvent:__func__ forced:YES];
    return self;
}
@end
