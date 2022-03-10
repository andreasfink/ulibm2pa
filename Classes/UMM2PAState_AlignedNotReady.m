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
        [_link.t2 stop];
        [_link.t4 stop];
        _t4_expired = NO;
        [_link.t4r stop];
        double t;
        M2TIMER_VALIDATE(_link.t4r.seconds,M2PA_DEFAULT_T4_R,M2PA_DEFAULT_T4_R_MIN,M2PA_DEFAULT_T4_R_MAX);
        if(_link.emergency)
        {
            t = _link.t4e;
            M2TIMER_VALIDATE(t,M2PA_DEFAULT_T4_E,M2PA_DEFAULT_T4_E_MIN,M2PA_DEFAULT_T4_E_MAX);
            _link.t4e = t;
            [self sendLinkstateProvingEmergency:YES];
        }
        else
        {
            t = _link.t4n;
            M2TIMER_VALIDATE(t,M2PA_DEFAULT_T4_N,M2PA_DEFAULT_T4_N_MIN,M2PA_DEFAULT_T4_N_MAX);
            _link.t4n = t;
            [self sendLinkstateProvingEmergency:YES];
        }
        
        M2TIMER_VALIDATE(_link.t4r.seconds,M2PA_DEFAULT_T4_R,M2PA_DEFAULT_T4_R_MIN,M2PA_DEFAULT_T4_R_MAX);
        [_link.t4r start]; /* tume u*/
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
    if(_link.forcedOutOfService==YES)
    {
        return [[UMM2PAState_OutOfService alloc]initWithLink:_link];
    }
    if(_link.emergency)
    {
        [self sendLinkstateProvingEmergency:YES];
    }
    else
    {
        [self sendLinkstateProvingNormal:YES];
    }
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
    /* other side is ready. we are ready when we are ready. */
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
    [self logStatemachineEvent:__func__];
    if((_t4_expired) && (_link.linkstateProvingSent > 5))
    {
        [self sendLinkstateReady:YES];
        [_link.t1 stop];
        [_link.t2 stop];
        [_link.t4r stop];
        [_link.t4 stop];
        _t4_expired = NO;
        return [[UMM2PAState_AlignedReady alloc]initWithLink:_link];
    }
    if(_link.emergency)
    {
        [self sendLinkstateProvingEmergency:YES];
    }
    else
    {
        [self sendLinkstateProvingNormal:YES];
    }
    return self;
}

- (UMM2PAState *)eventTimer4
{
    [self logStatemachineEvent:__func__];
    if(_link.linkstateProvingSent > 5)
    {
        [self sendLinkstateReady:YES];
        return [[UMM2PAState_AlignedReady alloc]initWithLink:_link];
    }
    else
    {
        _t4_expired = YES;
    }
    return self;
}

- (void) sendLinkstateOutOfService:(BOOL)sync
{
    [self logStatemachineEvent:__func__ forced:YES];
    [_link sendLinkstatus:M2PA_LINKSTATE_OUT_OF_SERVICE synchronous:sync];
    _link.linkstateOutOfServiceSent++;
    [self logStatemachineEventString:@"sendLinkstateOutOfService"];
}

- (UMM2PAState *)eventReceiveUserData:(NSData *)userData
{
    [self logStatemachineEvent:__func__ forced:YES];
    return self;
}

@end
