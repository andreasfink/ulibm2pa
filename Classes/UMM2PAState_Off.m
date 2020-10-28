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

- (NSString *)description
{
    return @"off";
}

- (M2PA_Status)statusCode
{
    return M2PA_STATUS_OFF;
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
    [self sendLinkstateAlignment];
    [_link.t2 start];
    return [[UMM2PAState_OutOfService alloc]initWithLink:_link];
}

- (UMM2PAState *)eventSctpUp
{
    [self logStatemachineEvent:__func__];
    [_link.startTimer stop];
    [_link startupInitialisation];
    [self sendLinkstateOutOfService];
    [_link notifyMtp3OutOfService];
    return self;
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
    [self logStatemachineEvent:__func__];
    [_link.startTimer stop];
    [_link startupInitialisation];
    [_link notifyMtp3OutOfService];
    [self sendLinkstateAlignment];
    if([_link.t2 isRunning]==NO)
    {
        [_link.t2 start];
    }
    return  [[UMM2PAState_InitialAlignment alloc]initWithLink:_link];
}


- (UMM2PAState *)eventEmergency
{
    [self sendLinkstateOutOfService];
    [self logStatemachineEvent:__func__];
    _link.emergency = YES;
    return self;
}

- (UMM2PAState *)eventEmergencyCeases
{
    [self sendLinkstateOutOfService];
    [self logStatemachineEvent:__func__];
    _link.emergency = NO;
    return self;
}

- (UMM2PAState *)eventLinkstatusAlignment
{
    [self sendLinkstateOutOfService];
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventLinkstatusProvingNormal
{
    [self sendLinkstateOutOfService];
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventLinkstatusProvingEmergency
{
    [self sendLinkstateOutOfService];
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventLinkstatusReady
{
    [self sendLinkstateOutOfService];
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventLinkstatusBusy
{
    [self sendLinkstateOutOfService];
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventLinkstatusBusyEnded
{
    [self sendLinkstateOutOfService];
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventLinkstatusProcessorOutage
{
    [self sendLinkstateOutOfService];
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventLinkstatusProcessorRecovered
{
    [self sendLinkstateOutOfService];
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventError
{
    [self sendLinkstateOutOfService];
    [self logStatemachineEvent:__func__];
    return self;
}



@end
