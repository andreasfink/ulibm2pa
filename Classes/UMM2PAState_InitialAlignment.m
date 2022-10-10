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
    [_link.repeatTimer stop];
    self =[super initWithLink:link  status:statusCode];
    {
        _statusCode = M2PA_STATUS_INITIAL_ALIGNMENT;
        [_link.t2 stop];
        [_link.t4 stop];
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

- (UMM2PAState *)eventSctpUp:(NSNumber *)socketNumber              /* SCTP reports the 'wire' has come up*/
{
    [self logStatemachineEvent:__func__ socketNumber:socketNumber];
    return self;
}

- (UMM2PAState *)eventSctpDown:(NSNumber *)socketNumber             /* SCTP reports the conncetion is lost */
{
    return [super eventSctpDown:socketNumber];
}

- (UMM2PAState *)eventLinkstatusOutOfService:(NSNumber *)socketNumber
{
    [self logStatemachineEvent:__func__ socketNumber:socketNumber];
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

- (UMM2PAState *)eventLinkstatusAlignment:(NSNumber *)socketNumber
{
    [self logStatemachineEvent:__func__ socketNumber:socketNumber];
    _alignmentReceived++;
    if(_alignmentReceived<=1)
    {
        [self sendLinkstateAlignment:YES];
        return self;
    }
    if(_link.emergency)
    {
        [self sendLinkstateProvingEmergency:YES];
    }
    else
    {
        [self sendLinkstateProvingNormal:YES];
    }
    return [[UMM2PAState_AlignedNotReady alloc]initWithLink:_link status:M2PA_STATUS_ALIGNED_NOT_READY];
}

- (UMM2PAState *)eventLinkstatusProvingNormal:(NSNumber *)socketNumber
{
    [self logStatemachineEvent:__func__ socketNumber:socketNumber];
    _link.emergency = NO;
    return [[UMM2PAState_AlignedNotReady alloc]initWithLink:_link status:M2PA_STATUS_ALIGNED_NOT_READY];
}

- (UMM2PAState *)eventLinkstatusProvingEmergency:(NSNumber *)socketNumber
{
    [self logStatemachineEvent:__func__ socketNumber:socketNumber];
    _link.emergency = YES;
    return [[UMM2PAState_AlignedNotReady alloc]initWithLink:_link status:M2PA_STATUS_ALIGNED_NOT_READY];
}

- (UMM2PAState *)eventLinkstatusReady:(NSNumber *)socketNumber
{
    [self logStatemachineEvent:__func__ socketNumber:socketNumber];
    return self;
}

- (UMM2PAState *)eventLinkstatusBusy:(NSNumber *)socketNumber
{
    [self logStatemachineEvent:__func__ socketNumber:socketNumber];
    return self;
}

- (UMM2PAState *)eventLinkstatusBusyEnded:(NSNumber *)socketNumber
{
    [self logStatemachineEvent:__func__ socketNumber:socketNumber];
    return self;
}

- (UMM2PAState *)eventLinkstatusProcessorOutage:(NSNumber *)socketNumber
{
    [self logStatemachineEvent:__func__ socketNumber:socketNumber];
    return self;
}

- (UMM2PAState *)eventLinkstatusProcessorRecovered:(NSNumber *)socketNumber
{
    [self logStatemachineEvent:__func__ socketNumber:socketNumber];
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


- (UMM2PAState *)eventRepeatTimer
{
    [self logStatemachineEvent:__func__];
    [_link.repeatTimer stop];
    return self;
}

- (UMM2PAState *)eventReceiveUserData:(NSData *)userData socketNumber:(NSNumber *)socketNumber
{
    [self logStatemachineEvent:__func__ forced:YES socketNumber:socketNumber];
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

- (UMM2PAState *)eventTimer2r
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
    [_link notifyMtp3InitialAlignment];
    return self;
}

- (UMM2PAState *)eventTimer3
{
    [self logStatemachineEvent:__func__];
    [self sendLinkstateOutOfService:YES];
    [_link notifyMtp3OutOfService];
    [_link.sctpLink closeFor:_link reason:@"t3"];
    [_link notifyMtp3Disconnected];
    return [[UMM2PAState_Disconnected alloc]initWithLink:_link status:M2PA_STATUS_DISCONNECTED];
}

@end
