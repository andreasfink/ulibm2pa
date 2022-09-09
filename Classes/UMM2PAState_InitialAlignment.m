//
//  UMM2PAState_InitialAlignment.m
//  ulibm2pa
//
//  Created by Andreas Fink on 17.03.20.
//  Copyright © 2020 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMM2PAState_InitialAlignment.h"
#import "UMM2PAState_allStates.h"
#import "UMLayerM2PA.h"

@implementation UMM2PAState_InitialAlignment
- (UMM2PAState *)initWithLink:(UMLayerM2PA *)link status:(M2PA_Status)statusCode
{
    self =[super initWithLink:link  status:statusCode];
    {
        _statusCode = M2PA_STATUS_INITIAL_ALIGNMENT;
        [_link.t2 stop];
        [_link.t4 stop];
        [_link.t4r stop];
        // the timer will send it. we first have to return the correct state to the caller
        [self sendLinkstateAlignment:YES];
        [_link.t2 start];
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
    [self sendLinkstateOutOfService:YES];
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
    return [super eventSctpDown];
}

- (UMM2PAState *)eventLinkstatusOutOfService
{
    [self logStatemachineEvent:__func__];
    [self sendLinkstateAlignment:YES];
    [_link.t2 stop];
    [_link.t2 start];
    return self;
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
    return [[UMM2PAState_AlignedNotReady alloc]initWithLink:_link status:M2PA_STATUS_ALIGNED_NOT_READY];
}

- (UMM2PAState *)eventLinkstatusProvingNormal
{
    [self logStatemachineEvent:__func__];
    _link.emergency = NO;
    return [[UMM2PAState_AlignedNotReady alloc]initWithLink:_link status:M2PA_STATUS_ALIGNED_NOT_READY];
}

- (UMM2PAState *)eventLinkstatusProvingEmergency
{
    [self logStatemachineEvent:__func__];
    _link.emergency = YES;
    return [[UMM2PAState_AlignedNotReady alloc]initWithLink:_link status:M2PA_STATUS_ALIGNED_NOT_READY];
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


- (UMM2PAState *)eventTimer4
{
    [_link.t4 stop];
    return self;
}

- (UMM2PAState *)eventTimer4r
{
    [_link.t4r stop];
    return self;
}

- (UMM2PAState *)eventTimerOosRepeat
{
    [self logStatemachineEvent:__func__];
    [_link.oos_repeat_timer stop];
    return self;
}

- (UMM2PAState *)eventReceiveUserData:(NSData *)userData
{
    [self logStatemachineEvent:__func__ forced:YES];
    return self;
}

- (UMM2PAState *)eventTimer2
{
    [self logStatemachineEvent:__func__];
    _link.emergency = NO;
    _link.alignmentNotPossible = YES;
    [self sendLinkstateAlignment:YES];
    return self;
}

- (UMM2PAState *)eventSendUserData:(NSData *)data
                        ackRequest:(NSDictionary *)ackRequest
                               dpc:(int)dpc
{
    [self logStatemachineEvent:__func__ forced:YES];
    /* we dont expect data pdus in linkstate initial alignment */
    [_link notifyMtp3:M2PA_STATUS_INITIAL_ALIGNMENT async:YES];
    return self;
}

@end
