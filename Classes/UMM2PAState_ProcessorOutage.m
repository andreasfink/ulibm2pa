//
//  UMM2PAState_ProcessorOutage.m
//  ulibm2pa
//
//  Created by Andreas Fink on 06.09.22.
//  Copyright © 2022 Andreas Fink (andreas@fink.org). All rights reserved.
//

#include "UMM2PAState_ProcessorOutage.h"
#import "UMM2PAState_allStates.h"
#import "UMLayerM2PA.h"


@implementation UMM2PAState_ProcessorOutage

- (UMM2PAState *)initWithLink:(UMLayerM2PA *)link status:(M2PA_Status)statusCode
{
    self = [super initWithLink:link status:M2PA_STATUS_PROCESSOR_OUTAGE];
    {
        _statusCode = M2PA_STATUS_PROCESSOR_OUTAGE;
    }
    return self;
}

- (NSString *)description
{
    return @"processor-outage";
}

- (UMM2PAState *)eventStop
{
    [self logStatemachineEvent:__func__];
    return [[UMM2PAState_OutOfService alloc]initWithLink:_link status:M2PA_STATUS_OOS];
}

- (UMM2PAState *)eventStart
{
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventSctpUp
{
    [self logStatemachineEvent:__func__];
    return [super eventSctpUp];
}

- (UMM2PAState *)eventSctpDown
{
    return [super eventSctpDown];
}

- (UMM2PAState *)eventLinkstatusOutOfService:(NSNumber *)socketNumber
{
    [self logStatemachineEvent:__func__ socketNumber:socketNumber];
    return [super eventLinkstatusOutOfService:(NSNumber *)socketNumber];
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

- (UMM2PAState *)eventLinkstatusAlignment:(NSNumber *)socketNumber
{
    [self logStatemachineEvent:__func__ socketNumber:socketNumber];
    if(_link.forcedOutOfService==YES)
    {
        return [[UMM2PAState_OutOfService alloc]initWithLink:_link status:M2PA_STATUS_OOS];
    }
    return [[UMM2PAState_InitialAlignment alloc]initWithLink:_link status:M2PA_STATUS_INITIAL_ALIGNMENT];
}

- (UMM2PAState *)eventLinkstatusProvingNormal:(NSNumber *)socketNumber
{
    [self logStatemachineEvent:__func__ socketNumber:socketNumber];
    [self sendLinkstateReady:YES];
    return self;
}

- (UMM2PAState *)eventLinkstatusProvingEmergency:(NSNumber *)socketNumber
{
    [self logStatemachineEvent:__func__ socketNumber:socketNumber];
    [self sendLinkstateReady:YES];
    return self;
}

- (UMM2PAState *)eventLinkstatusReady:(NSNumber *)socketNumber
{
    [self logStatemachineEvent:__func__ socketNumber:socketNumber];
    [_link.t1 stop];
    [_link.t2 stop];
    [_link.t4 stop];
    [_link notifyMtp3InService];
    return self;
}

- (UMM2PAState *)eventLinkstatusBusy:(NSNumber *)socketNumber
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


- (UMM2PAState *)eventError
{
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventReceiveUserData:(NSData *)userData socketNumber:(NSNumber *)socketNumber
{
    [self logStatemachineEvent:__func__ socketNumber:socketNumber];
    return self;
}

- (UMM2PAState *)eventSendUserData:(NSData *)data
                        ackRequest:(NSDictionary *)ackRequest
                               dpc:(int)dpc
{
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
    [_link sendLinkstatus:M2PA_LINKSTATE_READY synchronous:YES];
    return self;
}

- (UMM2PAState *)eventLinkstatusProcessorOutage:(NSNumber *)socketNumber
{
    [self logStatemachineEvent:__func__ socketNumber:socketNumber];
    _link.remote_processor_outage = YES;
    [_link notifyMtp3RemoteProcessorOutage];
    [_link sendLinkstatus:M2PA_LINKSTATE_READY synchronous:YES];
    return [[UMM2PAState_ProcessorOutage alloc] initWithLink:_link status:M2PA_STATUS_PROCESSOR_OUTAGE];
}

- (UMM2PAState *)eventLinkstatusProcessorRecovered:(NSNumber *)socketNumber
{
    [self logStatemachineEvent:__func__ socketNumber:socketNumber];
    _link.remote_processor_outage = NO;
    [_link notifyMtp3RemoteProcessorRecovered];
    [_link sendLinkstatus:M2PA_LINKSTATE_READY synchronous:YES];
    return [[UMM2PAState_InService alloc] initWithLink:_link status:M2PA_STATUS_IS];
}

@end
