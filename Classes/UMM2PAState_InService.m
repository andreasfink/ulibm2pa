//
//  UMM2PAState_InService.m
//  ulibm2pa
//
//  Created by Andreas Fink on 17.03.20.
//  Copyright © 2020 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMM2PAState_InService.h"
#import "UMM2PAState_allStates.h"
#import "UMLayerM2PA.h"


@implementation UMM2PAState_InService

- (UMM2PAState *)initWithLink:(UMLayerM2PA *)link status:(M2PA_Status)statusCode
{
    self = [super initWithLink:link status:statusCode];
    {
        [_link.t1 stop];
        [_link.t1r stop];
        [_link.t2 stop];
        [_link.t4 stop];
        [_link resetSequenceNumbers];
        _statusCode = M2PA_STATUS_IS;
    }
    return self;
}

- (NSString *)description
{
    return @"in-service";
}


#pragma mark -
#pragma mark event handlers

- (UMM2PAState *)eventPowerOn                   /* switch on the wire */
{
    [self logStatemachineEvent:__func__];
    [_link addToLayerHistoryLog:@"poweron in in-service is ignored"];
    return self;
}

- (UMM2PAState *)eventPowerOff                  /* switch off the wire */
{
    [self logStatemachineEvent:__func__];
    [_link addToLayerHistoryLog:@"poweroff in in-service is ignored"];
    return self;
}

- (UMM2PAState *)eventStart
{
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventStop
{
    [self logStatemachineEvent:__func__];
    [_link sendLinkstatus:M2PA_LINKSTATE_OUT_OF_SERVICE synchronous:YES];
    return [[UMM2PAState_OutOfService alloc]initWithLink:_link status:M2PA_STATUS_OOS];
}

- (UMM2PAState *)eventSctpUp:(NSNumber *)socketNumber              /* SCTP reports the 'wire' has come up*/
{
    [self logStatemachineEvent:__func__ socketNumber:socketNumber];
    return [super eventSctpUp:socketNumber];
}


- (UMM2PAState *)eventSctpDown:(NSNumber *)socketNumber
{
    [self logStatemachineEvent:__func__ socketNumber:socketNumber];
    return [super eventSctpDown:socketNumber];
}

- (UMM2PAState *)eventEmergency
{
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventEmergencyCeases
{
    [self logStatemachineEvent:__func__];
    return self;
}



#pragma mark -
#pragma mark eventLinkstatus handlers

- (UMM2PAState *)eventLinkstatusOutOfService:(NSNumber *)socketNumber            /* other side sent us linkstatus out of service SIOS */
{
    [self logStatemachineEvent:__func__ socketNumber:socketNumber];
    [self sendLinkstateOutOfService:NO];
    return [[UMM2PAState_OutOfService alloc]initWithLink:_link status:M2PA_STATUS_OOS];
}

- (UMM2PAState *)eventLinkstatusAlignment:(NSNumber *)socketNumber               /* other side sent us linkstatus alignment SIO */
{
    [self logStatemachineEvent:__func__ socketNumber:socketNumber];
    [self sendLinkstateOutOfService:NO];
    return [[UMM2PAState_OutOfService alloc]initWithLink:_link status:M2PA_STATUS_OOS];
}

- (UMM2PAState *)eventLinkstatusProvingNormal:(NSNumber *)socketNumber            /* other side sent us linkstatus proving normal SIN */
{
    [self logStatemachineEvent:__func__ socketNumber:socketNumber];
    [self sendLinkstateOutOfService:NO];
    return [[UMM2PAState_OutOfService alloc]initWithLink:_link status:M2PA_STATUS_OOS];
}

- (UMM2PAState *)eventLinkstatusProvingEmergency:(NSNumber *)socketNumber        /* other side sent us linkstatus emergency SIE */
{
    [self logStatemachineEvent:__func__ socketNumber:socketNumber];
    [self sendLinkstateOutOfService:NO];
    return [[UMM2PAState_OutOfService alloc]initWithLink:_link status:M2PA_STATUS_OOS];
}

- (UMM2PAState *)eventLinkstatusReady:(NSNumber *)socketNumber                   /* other side sent us linkstatus ready FISU */
{
    [self logStatemachineEvent:__func__ socketNumber:socketNumber];
    [_link.t1 stop];
    [_link.t2 stop];
    [_link.t4 stop];
    [_link notifyMtp3InService];
    return self;
}

- (UMM2PAState *)eventLinkstatusBusy:(NSNumber *)socketNumber                   /* other side sent us linkstatus ready FISU */
{
    [self logStatemachineEvent:__func__ socketNumber:socketNumber];
    _link.congested = YES;
    [_link notifyMtp3Congestion];
    return self;
}

- (UMM2PAState *)eventLinkstatusBusyEnded:(NSNumber *)socketNumber
{
    [self logStatemachineEvent:__func__ socketNumber:socketNumber];
    _link.congested = NO;
    [_link notifyMtp3CongestionCleared];
    return self;
}

- (UMM2PAState *)eventLinkstatusProcessorOutage:(NSNumber *)socketNumber                   /* other side sent us linkstatus processor outage SIPO */
{
    [self logStatemachineEvent:__func__ socketNumber:socketNumber];
    [_link notifyMtp3RemoteProcessorOutage];
    [_link sendLinkstatus:M2PA_LINKSTATE_READY synchronous:YES];
    _link.remote_processor_outage = YES;
    return  [[UMM2PAState_ProcessorOutage alloc]initWithLink:_link status:M2PA_STATUS_PROCESSOR_OUTAGE];
}

- (UMM2PAState *)eventLinkstatusProcessorRecovered:(NSNumber *)socketNumber                   /* other side sent us linkstatus processor recovered */
{
    [self logStatemachineEvent:__func__ socketNumber:socketNumber];
    _link.remote_processor_outage = NO;
    [_link notifyMtp3RemoteProcessorRecovered];
    return self;
}



#pragma mark -
#pragma mark timers

- (UMM2PAState *)eventTimer1
{
    [self logStatemachineEvent:__func__];
    [_link.t1 stop];
    return self;
}

- (UMM2PAState *)eventTimer1r
{
    [self logStatemachineEvent:__func__];
    [_link.t1r stop];
    return self;
}


- (UMM2PAState *)eventTimer4
{
    [self logStatemachineEvent:__func__];
    [_link.t4 stop];
    return self;
}

- (UMM2PAState *)eventRepeatTimer
{
    [self logStatemachineEvent:__func__];
    [_link.repeatTimer stop];
    return self;
}


- (UMM2PAState *)eventReceiveUserData:(NSData *)userData socketNumber:(NSNumber *)socketNumber
{
    /* we dont want to fill up the statemachine log with entries for every packet received. So we only log the first 3 */
    /* the passing of the data to MTP3 happens outside this event machine  in UMLayerM2PA */
    if(_userDataReceived<3)
    {
        [self logStatemachineEvent:__func__ socketNumber:socketNumber];
        _userDataReceived++;
    }
    else if(_userDataReceived==3)
    {
        [_link.stateMachineLogFeed debugText:@"..."];
    }
    return self;
}

- (void) sendLinkstateOutOfService:(BOOL)sync
{
    [self logStatemachineEvent:__func__ forced:YES];
    [_link sendLinkstatus:M2PA_LINKSTATE_OUT_OF_SERVICE synchronous:sync];
    _link.linkstateOutOfServiceSent++;
    [self logStatemachineEventString:@"sendLinkstateOutOfService"];
    [_link notifyMtp3OutOfService];
}

- (UMM2PAState *)eventSendUserData:(NSData *)data
                        ackRequest:(NSDictionary *)ackRequest
                               dpc:(int)dpc
{
    [_link sendData:data
             stream:M2PA_STREAM_USERDATA
         ackRequest:ackRequest
                dpc:dpc];
    return self;
}

- (UMM2PAState *) eventLocalProcessorOutage
{
    [self logStatemachineEvent:__func__ forced:YES];
    [_link sendLinkstatus:M2PA_LINKSTATE_PROCESSOR_OUTAGE synchronous:YES];
    return [[UMM2PAState_ProcessorOutage alloc] initWithLink:_link status:M2PA_STATUS_PROCESSOR_OUTAGE];
}

- (UMM2PAState *) eventLocalProcessorRecovery
{
    [self logStatemachineEvent:__func__ forced:YES];
    return self;
}


@end
