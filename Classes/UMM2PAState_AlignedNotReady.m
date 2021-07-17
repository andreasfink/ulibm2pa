//
//  UMM2PAState_AlignedNotReady.m
//  ulibm2pa
//
//  Created by Andreas Fink on 17.03.20.
//  Copyright © 2020 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMM2PAState_AlignedNotReady.h"
#import "UMM2PAState_allStates.h"
#import "UMLayerM2PA.h"

@implementation UMM2PAState_AlignedNotReady

- (UMM2PAState *)initWithLink:(UMLayerM2PA *)link;
{
    self =[super initWithLink:link];
    {
        _statusCode = M2PA_STATUS_ALIGNED_NOT_READY;
    }
    return self;
}


- (NSString *)description
{
    return @"aligned-not-ready";
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
    [self logStatemachineEvent:__func__];
    return  self;
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
    [_link.t2 stop];
    if(_link.emergency)
    {
        [self sendLinkstateProvingEmergency:NO];
        _link.t4.seconds = _link.t4e;
    }
    else
    {
        [self sendLinkstateProvingNormal:NO];
        _link.t4.seconds = _link.t4n;
    }
    if([_link.t4 isRunning]==NO)
    {
        [_link.t4 start];
    }
    [_link.t4r start];
    return self;
}

- (UMM2PAState *)eventLinkstatusProvingNormal
{
    [self logStatemachineEvent:__func__];
    _link.linkstateProvingReceived++;
    return self;
}

- (UMM2PAState *)eventLinkstatusProvingEmergency
{
    [self logStatemachineEvent:__func__];
    _link.linkstateProvingReceived++;
    return self;
}

- (UMM2PAState *)eventLinkstatusReady
{
    [self logStatemachineEvent:__func__];
    [self sendLinkstateReady:NO];
    [_link.t1 stop];
    [_link.t2 stop];
    [_link.t4r stop];
    [_link.t4 stop];
    UMM2PAState *newState = [[UMM2PAState_InService alloc]initWithLink:_link];
    _switching_to_is = YES;
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

- (UMM2PAState *)eventTimer4r
{
    [self logStatemachineEvent:__func__];
    if((_t4_expired) && (_link.linkstateProvingSent > 5))
    {
        [self sendLinkstateReady:NO];
        return [[UMM2PAState_AlignedReady alloc]initWithLink:_link];
    }

    if(_link.emergency)
    {
        [self sendLinkstateProvingEmergency:NO];
    }
    else
    {
        [self sendLinkstateProvingNormal:NO];
    }
    return self;
}

- (UMM2PAState *)eventTimer4
{
    [self logStatemachineEvent:__func__];
    if(    _link.linkstateProvingSent > 5)
    {
        [self sendLinkstateReady:NO];
        return [[UMM2PAState_AlignedReady alloc]initWithLink:_link];
    }
    else
    {
        _t4_expired = YES;
    }
    return self;
}

@end
