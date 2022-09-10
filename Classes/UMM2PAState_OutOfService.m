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


- (UMM2PAState *)initWithLink:(UMLayerM2PA *)link status:(M2PA_Status)statusCode
{
    self = [super initWithLink:link status:statusCode];
    if(self)
    {
        _statusCode = M2PA_STATUS_OOS;
        [_link.t2 stop];
        // we can not do this at this moment as we might still be in status UMMP2PAState off. so we let the timer send the first OOS */
        [_link.repeatTimer stop];
        [_link.repeatTimer start]; /* heartbeat sending out OOS */
    }
    return self;
}


- (NSString *)description
{
    return @"out-of-service";
}

#pragma mark -
#pragma mark event handlers

- (UMM2PAState *)eventPowerOn;                      /* switch on the wire */
{
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventPowerOff;                     /* switch off the wire */
{
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventStart
{
    [self logStatemachineEvent:__func__];
    if(_link.forcedOutOfService==YES)
    {
        [self sendLinkstateOutOfService:YES];
        return self;
    }
    [_link.repeatTimer stop];
    [self sendLinkstateAlignment:YES];
    return [[UMM2PAState_InitialAlignment alloc]initWithLink:_link status:M2PA_STATUS_INITIAL_ALIGNMENT];
}


- (UMM2PAState *)eventStop
{
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventSctpUp
{
    [self logStatemachineEvent:__func__];
    [self sendLinkstateOutOfService:YES];
    [_link notifyMtp3OutOfService];
    return self;
}

- (UMM2PAState *)eventSctpDown
{
    return [super eventSctpDown];
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
    if(_link.forcedOutOfService==YES)
    {
        [self sendLinkstateOutOfService:YES];
        return self;
    }
    [self sendLinkstateAlignment:YES];
    [_link.repeatTimer stop];
    return [[UMM2PAState_InitialAlignment alloc]initWithLink:_link status:M2PA_STATUS_INITIAL_ALIGNMENT];
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

- (UMM2PAState *)eventTimer2
{
    [self logStatemachineEvent:__func__];
    return self;
}


- (UMM2PAState *)eventRepeatTimer
{
    [self logStatemachineEvent:__func__];
    [self sendLinkstateOutOfService:YES];
    return self;
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
    return self;
}

@end
