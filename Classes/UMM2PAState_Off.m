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
    [self sendLinkstateOutOfService:YES];
    UMM2PAState *s = [[UMM2PAState_OutOfService alloc]initWithLink:_link];
    return [s eventStart];
}

- (UMM2PAState *)eventSctpUp
{
    [self logStatemachineEvent:__func__];
    [_link.startTimer stop];
    [_link startupInitialisation];
    [self sendLinkstateOutOfService:YES];
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
    [self sendLinkstateOutOfService:YES];
    [self logStatemachineEvent:__func__];
    _link.emergency = YES;
    return self;
}

- (UMM2PAState *)eventEmergencyCeases
{
    [self sendLinkstateOutOfService:YES];
    [self logStatemachineEvent:__func__];
    _link.emergency = NO;
    return self;
}

- (UMM2PAState *)eventLinkstatusAlignment
{
    [self sendLinkstateOutOfService:YES];
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventLinkstatusProvingNormal
{
    [self sendLinkstateOutOfService:YES];
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventLinkstatusProvingEmergency
{
    [self sendLinkstateOutOfService:YES];
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventLinkstatusReady
{
    [self sendLinkstateOutOfService:YES];
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventLinkstatusBusy
{
    [self sendLinkstateOutOfService:YES];
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventLinkstatusBusyEnded
{
    [self sendLinkstateOutOfService:YES];
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventLinkstatusProcessorOutage
{
    [self sendLinkstateOutOfService:YES];
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventLinkstatusProcessorRecovered
{
    [self sendLinkstateOutOfService:YES];
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventError
{
    [self sendLinkstateOutOfService:YES];
    [self logStatemachineEvent:__func__];
    return self;
}



@end
