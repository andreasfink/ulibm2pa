//
//  UMM2PAState_OutOfService.m
//  ulibm2pa
//
//  Created by Andreas Fink on 17.03.20.
//  Copyright © 2020 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMM2PAState_OutOfService.h"
#import "UMM2PAState_allStates.h"
#import "UMLayerM2PA.h"

@implementation UMM2PAState_OutOfService


- (UMM2PAState *)initWithLink:(UMLayerM2PA *)link
{
    self = [super initWithLink:link];
    if(self)
    {
        [self sendLinkstateOutOfService:NO];
        _statusCode = M2PA_STATUS_OOS;
    }
    return self;
}


- (NSString *)description
{
    return @"out-of-service";
}


- (UMM2PAState *)eventStop
{
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventStart
{
    [self logStatemachineEvent:__func__];
    if([_link.t2 isRunning]==NO)
    {
        [_link.t2 start];
    }
    _i_am_starting = YES;
    if(_link.forcedOutOfService)
    {
        [self sendLinkstateOutOfService:NO];
        return self;
    }
    else
    {
       [self sendLinkstateAlignment:NO];
        return [[UMM2PAState_InitialAlignment alloc]initWithLink:_link];
    }
}

- (UMM2PAState *)eventSctpUp
{
    [self logStatemachineEvent:__func__];
    [self sendLinkstateOutOfService:NO];
    return self;
}

- (UMM2PAState *)eventSctpDown
{
    [self logStatemachineEvent:__func__];
    return [[UMM2PAState_Off alloc]initWithLink:_link];
}

- (UMM2PAState *)eventLinkstatusOutOfService
{
    /*
      we are already in this state. we have to do nothing here as
      otherwise we will do start playing ping-pong. The proper
      action is MTP3 to send us start now (if not already done)
    */
    [self logStatemachineEvent:__func__];
    return self;
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
    if(_link.forcedOutOfService)
    {
        [self sendLinkstateOutOfService:NO];
        return self;
    }

    [self sendLinkstateAlignment:NO];
    [_link.t2 stop];
    [_link.t4 stop];
    [_link.t4r stop];

    UMM2PAState *newState = [[UMM2PAState_AlignedNotReady alloc]initWithLink:_link];
    _link.state = newState;
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
    _link.t4r.repeats = YES;
    [_link.t4 start];
    [_link.t4r start];
    return newState;
}

- (UMM2PAState *)eventLinkstatusProvingNormal
{
    [self logStatemachineEvent:__func__];
    [self sendLinkstateOutOfService:NO];
    if(_link.forcedOutOfService==NO)
    {
        [self sendLinkstateAlignment:NO];
    }
    if([_link.t2 isRunning]==NO)
    {
        [_link.t2 start];
    }
    return self;
}

- (UMM2PAState *)eventLinkstatusProvingEmergency
{
    [self logStatemachineEvent:__func__];
    [self sendLinkstateOutOfService:NO];
    if(_link.forcedOutOfService==NO)
    {
        [self sendLinkstateAlignment:NO];
    }
    if([_link.t2 isRunning]==NO)
    {
        [_link.t2 start];
    }
    return self;
}

- (UMM2PAState *)eventLinkstatusReady
{
    [self logStatemachineEvent:__func__];
    [self sendLinkstateOutOfService:NO];
    return self;
}

- (UMM2PAState *)eventLinkstatusBusy
{
    [self logStatemachineEvent:__func__];
    [self sendLinkstateOutOfService:NO];
    return self;
}

- (UMM2PAState *)eventLinkstatusBusyEnded
{
    [self logStatemachineEvent:__func__];
    [self sendLinkstateOutOfService:NO];
    return self;
}

- (UMM2PAState *)eventLinkstatusProcessorOutage
{
    [self logStatemachineEvent:__func__];
    [self sendLinkstateOutOfService:NO];
    return self;
}

- (UMM2PAState *)eventLinkstatusProcessorRecovered
{
    [self logStatemachineEvent:__func__];
    [self sendLinkstateOutOfService:NO];
    return self;
}

- (UMM2PAState *)eventError
{
    [self logStatemachineEvent:__func__];
    [self sendLinkstateOutOfService:NO];
    return self;
}

- (UMM2PAState *)eventTimer2
{
    [self logStatemachineEvent:__func__];
    if(_link.forcedOutOfService)
    {
        [self sendLinkstateOutOfService:NO];
    }
    else
    {
        [self sendLinkstateAlignment:NO];
        return [[UMM2PAState_InitialAlignment alloc]initWithLink:_link];
    }
    if([_link.t2 isRunning]==NO)
    {
        [_link.t2 start];
    }
    return self;
}
@end
