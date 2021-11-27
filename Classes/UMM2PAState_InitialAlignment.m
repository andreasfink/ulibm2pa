//
//  UMM2PAState_AlignedNotReady.m
//  ulibm2pa
//
//  Created by Andreas Fink on 17.03.20.
//  Copyright © 2020 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMM2PAState_InitialAlignment.h"
#import "UMM2PAState_allStates.h"
#import "UMLayerM2PA.h"

@implementation UMM2PAState_InitialAlignment

- (UMM2PAState *)initWithLink:(UMLayerM2PA *)link;
{
    self =[super initWithLink:link];
    {
        _statusCode = M2PA_STATUS_INITIAL_ALIGNMENT;
    }
    return self;
}

- (NSString *)description
{
    return @"initial-alignment";
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
    [_link.t2 stop];
    [_link.t4 stop];
    [_link.t4r stop];
    if(_link.t4r.seconds < 0.09)
    {
        _link.t4r.seconds = M2PA_DEFAULT_T4_R;
    }
    if(_link.emergency)
    {
        _link.t4.seconds = _link.t4e;
        [self sendLinkstateProvingEmergency:YES];
    }
    else
    {
        if(_link.t4n < 0.3)
        {
            _link.t4n = M2PA_DEFAULT_T4_N;
        }
        [self sendLinkstateProvingNormal:YES];
        _link.t4.seconds = _link.t4n;
    }
    [_link.t4 start];
    [_link.t4r start];
    return [[UMM2PAState_AlignedNotReady alloc]initWithLink:_link];
}

- (UMM2PAState *)eventLinkstatusProvingNormal
{
    [self logStatemachineEvent:__func__];
    if(_link.t4r.isRunning== NO)
    {
        M2TIMER_VALIDATE(_link.t4r.seconds,M2PA_DEFAULT_T4_R,M2PA_DEFAULT_T4_R_MIN,M2PA_DEFAULT_T4_R_MAX);
        if(_link.emergency)
        {
            double t = _link.t4e;
            M2TIMER_VALIDATE(t,M2PA_DEFAULT_T4_E,M2PA_DEFAULT_T4_E_MIN,M2PA_DEFAULT_T4_E_MAX);
            _link.t4e = t;
            _link.t4.seconds = t;
            [self sendLinkstateProvingEmergency:YES];
        }
        else
        {
            double t = _link.t4n;
            M2TIMER_VALIDATE(t,M2PA_DEFAULT_T4_N,M2PA_DEFAULT_T4_N_MIN,M2PA_DEFAULT_T4_N_MAX);
            _link.t4n = t;
            _link.t4.seconds = t;
            [self sendLinkstateProvingNormal:YES];
        }
        [_link.t4r start];
    }
    return [[UMM2PAState_AlignedNotReady alloc]initWithLink:_link];
}

- (UMM2PAState *)eventLinkstatusProvingEmergency
{
    [self logStatemachineEvent:__func__];
    if(_link.t4r.isRunning== NO)
    {
        M2TIMER_VALIDATE(_link.t4r.seconds,M2PA_DEFAULT_T4_R,M2PA_DEFAULT_T4_R_MIN,M2PA_DEFAULT_T4_R_MAX);
        if(_link.emergency)
        {
            double t = _link.t4e;
            M2TIMER_VALIDATE(t,M2PA_DEFAULT_T4_E,M2PA_DEFAULT_T4_E_MIN,M2PA_DEFAULT_T4_E_MAX);
            _link.t4e = t;
            _link.t4.seconds = t;
            [self sendLinkstateProvingEmergency:YES];
        }
        else
        {
            double t = _link.t4n;
            M2TIMER_VALIDATE(t,M2PA_DEFAULT_T4_N,M2PA_DEFAULT_T4_N_MIN,M2PA_DEFAULT_T4_N_MAX);
            _link.t4n = t;
            _link.t4.seconds = t;
            [self sendLinkstateProvingNormal:YES];
        }
        [_link.t4r start];
    }
    return [[UMM2PAState_AlignedNotReady alloc]initWithLink:_link];
}

- (UMM2PAState *)eventLinkstatusReady
{
    [self logStatemachineEvent:__func__];
    return self;
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
    [_link.t4 stop];
    return self;
}

- (void) sendLinkstateOutOfService:(BOOL)sync
{
#if 0
    {
        [self logStatemachineEvent:__func__ forced:YES];
        [_link sendLinkstatus:M2PA_LINKSTATE_OUT_OF_SERVICE synchronous:sync];
        _link.linkstateOutOfServiceSent++;
        [_link.stateMachineLogFeed debugText:@"sendLinkstateOutOfService"];
    }
#else
    {
        _link.linkstateAlignmentSent++;
        [_link sendLinkstatus:M2PA_LINKSTATE_ALIGNMENT synchronous:sync];
    }
#endif
}

- (UMM2PAState *)eventReceiveUserData:(NSData *)userData
{
    [self logStatemachineEvent:__func__ forced:YES];
    [_link notifyMtp3UserData:userData];
    [_link.stateMachineLogFeed debugText:@"receive-data"];
    return self;
}

- (UMM2PAState *)eventTimer2
{
    [self logStatemachineEvent:__func__];
    [self sendLinkstateAlignment:YES];
    return self;
}

@end
