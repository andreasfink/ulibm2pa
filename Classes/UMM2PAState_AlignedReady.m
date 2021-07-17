//
//  UMM2PAState_AlignedReady.m
//  ulibm2pa
//
//  Created by Andreas Fink on 17.03.20.
//  Copyright © 2020 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMM2PAState_AlignedReady.h"
#import "UMM2PAState_allStates.h"
#import "UMLayerM2PA.h"

@implementation UMM2PAState_AlignedReady

- (UMM2PAState *)initWithLink:(UMLayerM2PA *)link;
{
    self =[super initWithLink:link];
    {
        _statusCode = M2PA_STATUS_ALIGNED_READY;
    }
    return self;
}

- (NSString *)description
{
    return @"aligned-ready";
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

- (UMM2PAState *)eventLinkstatusAlignment
{
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventLinkstatusProvingNormal
{
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventLinkstatusProvingEmergency
{
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventLinkstatusReady
{
    [self logStatemachineEvent:__func__];
    [_link.t1 stop];
    [_link.t2 stop];
    [_link.t4r stop];
    [_link.t4 stop];
    _switching_to_is = YES;
    UMM2PAState *newState = [[UMM2PAState_InService alloc]initWithLink:_link];
    _link.state = newState;
    [_link notifyMtp3InService];
    return newState;
}

- (UMM2PAState *)eventLinkstatusBusy
{
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventLinkstatusBusyEnded
{
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventLinkstatusProcessorOutage
{
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventLinkstatusProcessorRecovered
{
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventError
{
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventTimer4
{
    [self logStatemachineEvent:__func__];
    [self sendLinkstateReady:NO];
    [_link.t4r stop];
    return [[UMM2PAState_AlignedReady alloc]initWithLink:_link];
}

- (UMM2PAState *)eventTimer4r
{
    [self logStatemachineEvent:__func__];
    [self sendLinkstateReady:NO];
    [_link.t4r stop];
    return self;
}


- (UMM2PAState *)eventReceiveUserData:(NSData *)userData
{
    [self logStatemachineEvent:__func__];
    [_link.t1 stop];
    [_link.t2 stop];
    [_link.t4r stop];
    [_link.t4 stop];
    [_link.stateMachineLogFeed debugText:@"receive-data-going IS"];
    _switching_to_is = YES;
    _link.state =  [[UMM2PAState_InService alloc]initWithLink:_link];
    [_link notifyMtp3InService];
    return [_link.state  eventReceiveUserData:userData];
}


@end
