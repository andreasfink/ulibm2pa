//
//  UMM2PAState_AlignedReady.m
//  ulibm2pa
//
//  Created by Andreas Fink on 17.03.20.
//  Copyright © 2020 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMM2PAState_AlignedReady.h"
#import "UMM2PAState_allStates.h"
#import "UMLayerM2PA.h"

@implementation UMM2PAState_AlignedReady

- (UMM2PAState *)initWithLink:(UMLayerM2PA *)link status:(M2PA_Status)statusCode
{
    self = [super initWithLink:link status:statusCode];
    {
        [_link.t1 stop];
        [_link.t2 stop];
        [_link.t4r stop];
        [_link.t4 stop];
        [self sendLinkstateReady:YES];
        _statusCode = M2PA_STATUS_ALIGNED_READY;
        /* we now send a READY signal every second
           until the other side sends READY as well or sends traffic
           Then we go int In service state
        */
        [_link.t1r start];
        [_link.t1 start];
        _readySent = 0;
    }
    return self;
}

- (NSString *)description
{
    return @"aligned-ready";
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
    return [super eventLinkstatusOutOfService];
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
        return [[UMM2PAState_OutOfService alloc]initWithLink:_link status:M2PA_STATUS_OOS];
    }
    else
    {
        return [[UMM2PAState_NotAligned alloc]initWithLink:_link status:M2PA_STATUS_NOT_ALIGNED];
    }
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
    [_link.t1 stop];
    [_link.t2 stop];
    [_link.t4r stop];
    [_link.t4 stop];
    [_link notifyMtp3InService];
    if(_readySent==0)
    {
        [self sendLinkstateReady:YES];
        _readySent = YES;
    }
    return  [[UMM2PAState_InService alloc]initWithLink:_link status:M2PA_STATUS_IS];
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
    _link.remote_processor_outage = YES;
    return  [[UMM2PAState_ProcessorOutage alloc]initWithLink:_link status:M2PA_STATUS_PROCESSOR_OUTAGE];
    return self;
}

- (UMM2PAState *)eventLinkstatusProcessorRecovered
{
    [self logStatemachineEvent:__func__];
    _link.remote_processor_outage = NO;
    return self;
}

- (UMM2PAState *)eventError
{
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventTimer1
{
    [self logStatemachineEvent:__func__];
    _readySent++;
    [self sendLinkstateReady:YES];
    [_link.t1 stop];
    [_link.t2 stop];
    [_link.t4r stop];
    [_link.t4 stop];
    [self logStatemachineEventString:@"t1 expired. going IS"];
    return [[UMM2PAState_InService alloc]initWithLink:_link status:M2PA_STATUS_IS];
}

- (UMM2PAState *)eventTimer1r
{
    [self logStatemachineEvent:__func__];
    _readySent++;
    [self sendLinkstateReady:YES];
    return self;
}


- (UMM2PAState *)eventReceiveUserData:(NSData *)userData
{
    [self logStatemachineEvent:__func__ forced:YES];
    [_link.t1 stop];
    [_link.t1r stop];
    [_link.t2 stop];
    [_link.t4r stop];
    [_link.t4 stop];
    [self logStatemachineEventString:@"receiveUserData going IS"];
    [_link notifyMtp3InService];
    return [[UMM2PAState_InService alloc]initWithLink:_link status:M2PA_STATUS_IS];
}

- (UMM2PAState *)eventSendUserData:(NSData *)data
                        ackRequest:(NSDictionary *)ackRequest
                               dpc:(int)dpc
{
    [_link sendData:data
             stream:M2PA_STREAM_USERDATA
         ackRequest:ackRequest
                dpc:dpc];
    return [[UMM2PAState_InService alloc]initWithLink:_link status:M2PA_STATUS_IS];
}

- (UMM2PAState *) eventLocalProcessorOutage
{
    [self logStatemachineEvent:__func__ forced:YES];
    [_link sendLinkstatus:M2PA_LINKSTATE_PROCESSOR_OUTAGE synchronous:YES];
    _link.linkstateProcessorOutageSent++;
    [self logStatemachineEventString:@"sendProcessorOutage"];
    [_link addToLayerHistoryLog:@"sendProcessorOutage"];
    return [[UMM2PAState_AlignedNotReady alloc] initWithLink:_link status:M2PA_STATUS_ALIGNED_NOT_READY];
}


@end
