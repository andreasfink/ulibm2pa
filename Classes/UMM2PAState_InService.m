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

- (UMM2PAState *)initWithLink:(UMLayerM2PA *)link
{
    self = [super initWithLink:link];
    if(self)
    {
        _link.m2pa_status = M2PA_STATUS_IS;
    }
    return self;
}


- (NSString *)description
{
    return @"in-service";
}

- (M2PA_Status)statusCode
{
    return M2PA_STATUS_IS;
}

- (UMM2PAState *)eventStop
{
    [self logStatemachineEvent:__func__];
    return self;
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
    [self logStatemachineEvent:__func__];
    return [super eventSctpDown];
}

- (UMM2PAState *)eventLinkstatusOutOfService
{
    return [super eventLinkstatusOutOfService];
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

- (UMM2PAState *)eventTimer4r
{
    [self logStatemachineEvent:__func__];
    [_link.t4r stop];
    return self;
}

- (UMM2PAState *)eventLinkstatusAlignment
{
    [self logStatemachineEvent:__func__];
    [self sendLinkstateOutOfService:NO];
    [self sendLinkstateAlignment:NO];
    if([_link.t2 isRunning]==NO)
    {
        [_link.t2 start];
    }
    return [[UMM2PAState_InitialAlignment alloc]initWithLink:_link];
}

- (UMM2PAState *)eventLinkstatusProvingNormal
{
    [self logStatemachineEvent:__func__];
    [self sendLinkstateOutOfService:NO];
    [self sendLinkstateAlignment:NO];
    if([_link.t2 isRunning]==NO)
    {
        [_link.t2 start];
    }
    return [[UMM2PAState_InitialAlignment alloc]initWithLink:_link];
}

- (UMM2PAState *)eventLinkstatusProvingEmergency
{
    [self logStatemachineEvent:__func__];
    [self sendLinkstateOutOfService:NO];
    [self sendLinkstateAlignment:NO];
    if([_link.t2 isRunning]==NO)
    {
        [_link.t2 start];
    }
    return [[UMM2PAState_InitialAlignment alloc]initWithLink:_link];
}

- (UMM2PAState *)eventLinkstatusReady
{
    [self logStatemachineEvent:__func__];
    //[self sendLinkstateReady:NO]
    return self;
}

- (UMM2PAState *)eventLinkstatusBusy
{
    [self logStatemachineEvent:__func__];
    _link.congested = YES;
    [_link notifyMtp3Congestion];
    return self;
}

- (UMM2PAState *)eventLinkstatusBusyEnded
{
    [self logStatemachineEvent:__func__];
    _link.congested = NO;
    [_link notifyMtp3CongestionCleared];
    return self;
}

- (UMM2PAState *)eventLinkstatusProcessorOutage
{
    [self logStatemachineEvent:__func__];
    _link.remote_processor_outage = YES;
    [_link notifyMtp3RemoteProcessorOutage];
    return self;
}

- (UMM2PAState *)eventLinkstatusProcessorRecovered
{
    [self logStatemachineEvent:__func__];
    _link.remote_processor_outage = NO;
    [_link notifyMtp3RemoteProcessorRecovered];
    return self;
}

- (UMM2PAState *)eventError
{
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventReceiveUserData:(NSData *)userData
{
    [self logStatemachineEvent:__func__];
    [_link notifyMtp3UserData:userData];
    [_link.stateMachineLogFeed debugText:@"receive-data"];
    return self;
}


@end
