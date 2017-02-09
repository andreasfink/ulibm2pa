//
//  UMM2PALinkStateControl_AlignedReady.m
//  ulibm2pa
//
//  Created by Andreas Fink on 05/12/14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import "UMM2PALinkStateControl_AllStates.h"
#import "UMLayerM2PA.h"

@implementation UMM2PALinkStateControl_AlignedReady

- (UMM2PALinkStateControl_AlignedReady *)initWithLink:(UMLayerM2PA *)link
{
    self =[super initWithLink:link];
    if(self)
    {
    }
    return self;
}

- (UMM2PALinkStateControl_AlignedReady *)init
{
    @throw([NSException exceptionWithName:@"API_ERROR"
                                   reason:@"dont call init. Call initWithLink"
                                 userInfo:@{    @"backtrace":   UMBacktrace(NULL,0) }]);
}

-(NSString *)description
{
    return @"UMM2PALinkStateControl_AlignedReady";
}

- (UMM2PALinkStateControl_State *)eventSIPO:(UMLayerM2PA *)link
{
    [[link t1]stop];
    [link notifyMtp3RemoteProcessorOutage];
    [link pocRemoteProcessorOutage];
    return [[UMM2PALinkStateControl_ProcessorOutage alloc]initWithLink:link];
}

- (UMM2PALinkStateControl_State *)eventFISU:(UMLayerM2PA *)link
{
    return [self eventMSU:link];
}

- (UMM2PALinkStateControl_State *)eventMSU:(UMLayerM2PA *)link
{
    [link txcSendFISU];
    [link.t1 stop];
    [link.t4 stop];
    [link.t4r stop];
    [link setM2pa_status:M2PA_STATUS_IS];
    
    [link resetSequenceNumbers];
    return [[UMM2PALinkStateControl_InService alloc]initWithLink:link];
}

- (UMM2PALinkStateControl_State *)eventLocalProcessorOutage:(UMLayerM2PA *)link
{
    [link pocLocalProcessorOutage];
    [link txcSendSIPO];
    [link rcRejectMsuFisu];
    return [[UMM2PALinkStateControl_AlignedNotReady alloc]initWithLink:link];
}


- (UMM2PALinkStateControl_State *)eventSIO:(UMLayerM2PA *)link
{
    return [self eventLinkFailure:link];
}

- (UMM2PALinkStateControl_State *)eventSIOS:(UMLayerM2PA *)link
{
    return [self eventLinkFailure:link];
}

- (UMM2PALinkStateControl_State *)eventLinkFailure:(UMLayerM2PA *)link
{
    [[link t1]stop];
    [link notifyMtp3OutOfService];
    [link rcStop];
    [link suermStop];
    [link txcSendSIOS];
    [link cancelEmergency];
    return [[UMM2PALinkStateControl_OutOfService alloc]initWithLink:link];
}

- (UMM2PALinkStateControl_State *)eventStop:(UMLayerM2PA *)link
{
    [[link t1]stop];
    [link rcStop];
    [link suermStop];
    [link txcSendSIOS];
    [link cancelEmergency];
    return [[UMM2PALinkStateControl_OutOfService alloc]initWithLink:link];
}

- (UMM2PALinkStateControl_State *)eventTimer1:(UMLayerM2PA *)link
{
    [link notifyMtp3OutOfService];
    [link rcStop];
    [link suermStop];
    [link txcSendSIOS];
    [link cancelEmergency];
    return [[UMM2PALinkStateControl_OutOfService alloc]initWithLink:link];
}

- (UMM2PALinkStateControl_State *)eventFisu:(UMLayerM2PA *)link
{
    link.ready_received++;
    return self;
}


@end
