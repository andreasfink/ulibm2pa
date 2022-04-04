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

- (UMM2PAState *)initWithLink:(UMLayerM2PA *)link;
{
    self =[super initWithLink:link];
    {
        _statusCode = M2PA_STATUS_OFF;
    }
    return self;
}

- (NSString *)description
{
    return @"off";
}

- (UMM2PAState *)eventPowerOff
{
    [self logStatemachineEvent:__func__];
    [_link.sctpLink closeFor:_link];
    return self;
}

- (UMM2PAState *)eventPowerOn
{
    [self logStatemachineEvent:__func__];
    [_link startupInitialisation];
    [_link.startTimer start];
    [_link.sctpLink openFor:_link];
    return self;
}

- (UMM2PAState *)eventStop
{
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventStart
{
    [self logStatemachineEvent:__func__];
    if(_link.forcedOutOfService == NO)
    {
        [self sendLinkstateAlignment:YES];
    }
    else
    {
        [self sendLinkstateOutOfService:YES];
    }
    UMM2PAState *s = [[UMM2PAState_OutOfService alloc]initWithLink:_link];
    return [s eventStart];
}

- (void) sendLinkstateOutOfService:(BOOL)sync
{
    [self logStatemachineEvent:__func__];
    [_link sendLinkstatus:M2PA_LINKSTATE_OUT_OF_SERVICE synchronous:sync];
    _link.linkstateOutOfServiceSent++;
    [self logStatemachineEventString:@"sendLinkstateOutOfService"];
}

- (UMM2PAState *)eventSctpUp
{
    [self logStatemachineEvent:__func__];
    [_link.startTimer stop];
    [_link startupInitialisation];
    if(_link.forcedOutOfService == NO)
    {
        [self sendLinkstateAlignment:YES];
    }
    else
    {
        [self sendLinkstateOutOfService:YES];
        [_link.t2 start];
    }
    UMM2PAState *newState = [[UMM2PAState_OutOfService alloc]initWithLink:_link];
    [_link setState:newState];
    return [newState eventStart];
}

- (UMM2PAState *)eventSctpDown
{
    [self logStatemachineEvent:__func__];
    [_link.startTimer stop];
    [_link notifyMtp3Stop];
    return self;
}

- (UMM2PAState *)eventLinkstatusOutOfService
{
    return [super eventLinkstatusOutOfService];
}


- (UMM2PAState *)eventEmergency
{
    if(_link.forcedOutOfService == NO)
    {
        [self sendLinkstateAlignment:YES];
    }
    else
    {
        [self sendLinkstateOutOfService:YES];
        [_link.t2 start];
    }
    [self logStatemachineEvent:__func__];
    _link.emergency = YES;
    return self;
}

- (UMM2PAState *)eventEmergencyCeases
{
    if(_link.forcedOutOfService == NO)
    {
        [self sendLinkstateAlignment:YES];
    }
    else
    {
        [self sendLinkstateOutOfService:YES];
        [_link.t2 start];
    }
    [self logStatemachineEvent:__func__];
    _link.emergency = NO;
    return self;
}

- (UMM2PAState *)eventLinkstatusAlignment
{
    if(_link.forcedOutOfService == NO)
    {
        [self sendLinkstateAlignment:YES];
    }
    else
    {
        [self sendLinkstateOutOfService:YES];
        [_link.t2 start];
    }
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventLinkstatusProvingNormal
{
    if(_link.forcedOutOfService == NO)
    {
        [self sendLinkstateAlignment:YES];
    }
    else
    {
        [self sendLinkstateOutOfService:YES];
        [_link.t2 start];
    }
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventLinkstatusProvingEmergency
{
    if(_link.forcedOutOfService == NO)
    {
        [self sendLinkstateAlignment:YES];
    }
    else
    {
        [self sendLinkstateOutOfService:YES];
        [_link.t2 start];
    }
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventLinkstatusReady
{
    if(_link.forcedOutOfService == NO)
    {
        [self sendLinkstateAlignment:YES];
    }
    else
    {
        [self sendLinkstateOutOfService:YES];
        [_link.t2 start];
    }
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventLinkstatusBusy
{
    if(_link.forcedOutOfService == NO)
    {
        [self sendLinkstateAlignment:YES];
    }
    else
    {
        [self sendLinkstateOutOfService:YES];
        [_link.t2 start];
    }
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventLinkstatusBusyEnded
{
    if(_link.forcedOutOfService == NO)
    {
        [self sendLinkstateAlignment:YES];
    }
    else
    {
        [self sendLinkstateOutOfService:YES];
        [_link.t2 start];
    }
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventLinkstatusProcessorOutage
{
    if(_link.forcedOutOfService == NO)
    {
        [self sendLinkstateAlignment:YES];
    }
    else
    {
        [self sendLinkstateOutOfService:YES];
        [_link.t2 start];
    }
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventLinkstatusProcessorRecovered
{
    if(_link.forcedOutOfService == NO)
    {
        [self sendLinkstateAlignment:YES];
    }
    else
    {
        [self sendLinkstateOutOfService:YES];
        [_link.t2 start];
    }
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventError
{
    if(_link.forcedOutOfService == NO)
    {
        [self sendLinkstateAlignment:YES];
    }
    else
    {
        [self sendLinkstateOutOfService:YES];
        [_link.t2 start];
    }
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventReceiveUserData:(NSData *)userData
{
    [self logStatemachineEvent:__func__ forced:YES];
    return self;
}


@end
