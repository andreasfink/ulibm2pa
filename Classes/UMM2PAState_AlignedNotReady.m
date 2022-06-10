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

- (UMM2PAState *)initWithLink:(UMLayerM2PA *)link status:(M2PA_Status)statusCode
{
    self =[super initWithLink:link status:statusCode];
    {
        _link.linkstateProvingSent = 0;
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
        [_link.t4r start]; /* sending out status timer */
        _link.t4.seconds = t;   /* ending of proving period timer */
        [_link.t4 start];
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
    return self;
}

- (UMM2PAState *)eventSctpDown
{
    [self logStatemachineEvent:__func__];
    return [super eventSctpDown];
}

- (UMM2PAState *)eventLinkstatusOutOfService
{
    [self logStatemachineEvent:__func__];
    return [[UMM2PAState_InitialAlignment alloc]initWithLink:_link status:M2PA_STATUS_INITIAL_ALIGNMENT];
}

- (UMM2PAState *)eventEmergency
{
    [self logStatemachineEvent:__func__];
    _link.emergency = YES;
    return self;
}

- (UMM2PAState *)eventEmergencyCeases
{
    [self logStatemachineEvent:__func__];
    _link.emergency = NO;
    return self;
}

- (UMM2PAState *)eventLinkstatusAlignment
{
    [self logStatemachineEvent:__func__];
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
    _ready_received = YES;
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
    if(_t4_expired)
    {
        [_link.t1 stop];
        [_link.t2 stop];
        [_link.t4 stop];
        [_link.t4r stop];
        return [[UMM2PAState_AlignedReady alloc]initWithLink:_link status:M2PA_STATUS_ALIGNED_READY];
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
    [_link.t1 stop];
    [_link.t2 stop];
    [_link.t4r stop];
    [_link.t4 stop];
    return [[UMM2PAState_AlignedReady alloc]initWithLink:_link status:M2PA_STATUS_ALIGNED_READY];
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

- (UMM2PAState *)eventSendUserData:(NSData *)data
                        ackRequest:(NSDictionary *)ackRequest
                               dpc:(int)dpc
{
    [self logStatemachineEvent:__func__ forced:YES];
    [_link notifyMtp3:M2PA_STATUS_ALIGNED_NOT_READY async:YES];
    return self;
}


@end
