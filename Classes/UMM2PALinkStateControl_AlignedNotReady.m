//
//  UMM2PALinkStateControl_AlignedNotReady.m
//  ulibm2pa
//
//  Created by Andreas Fink on 05/12/14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#if defined(OLD_IMPLEMENTATION)

#import "UMM2PALinkStateControl_AllStates.h"
#import "UMLayerM2PA.h"

@implementation UMM2PALinkStateControl_AlignedNotReady

-(NSString *)description
{
    return @"aligned-not-ready";
}

- (UMM2PALinkStateControl_AlignedNotReady *)initWithLink:(UMLayerM2PA *)link
{
    self =[super initWithLink:link];
    if(self)
    {
    }
    return self;
}

- (UMM2PALinkStateControl_AlignedNotReady *)init
{
    @throw([NSException exceptionWithName:@"API_ERROR"
                                   reason:@"dont call init. Call initWithLink"
                                 userInfo:@{    @"backtrace":   UMBacktrace(NULL,0) }]);
}


- (UMM2PALinkStateControl_State *)eventLocalProcessorRecovered:(UMLayerM2PA *)link
{
    [link pocLocalProcessorRecovered];
    link.local_processor_outage = NO;
    [link txcSendFISU];
    [link rcAcceptMsuFisu];
    return [[UMM2PALinkStateControl_AlignedReady alloc]initWithLink:link];
}

- (UMM2PALinkStateControl_State *)eventFisu:(UMLayerM2PA *)link
{
    [link sendLinkstatus:M2PA_LINKSTATE_READY];
    return [self eventMsu:link];
}

- (UMM2PALinkStateControl_State *)eventMsu:(UMLayerM2PA *)link
{
    [link notifyMtp3InService];
    [[link t1]stop];
    return [[UMM2PALinkStateControl_InService alloc]initWithLink:link];
}

- (UMM2PALinkStateControl_State *)eventSIPO:(UMLayerM2PA *)link
{
    [link notifyMtp3RemoteProcessorOutage];
    [link pocRemoteProcessorOutage];
    [[link t1]stop];
    return [[UMM2PALinkStateControl_ProcessorOutage alloc]initWithLink:link];
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
    [link notifyMtp3Stop];
// should that be   [link rcStop] maybe?;
    [link suermStop];
    [link txcSendSIOS];
    [link pocStop];
    [link cancelEmergency];
    [link cancelLocalProcessorOutage];
    return [[UMM2PALinkStateControl_OutOfService alloc]initWithLink:link];
}

- (UMM2PALinkStateControl_State *)eventStop:(UMLayerM2PA *)link
{
    [[link t1]stop];
    
    [link notifyMtp3Stop];
    // should that be   [link rcStop] maybe?;
    [link suermStop];
    [link txcSendSIOS];
    [link pocStop];
    [link cancelEmergency];
    [link cancelLocalProcessorOutage];
    return [[UMM2PALinkStateControl_OutOfService alloc]initWithLink:link];
}

- (UMM2PALinkStateControl_State *)eventTimer1:(UMLayerM2PA *)link
{
    [link notifyMtp3Stop];
    // should that be   [link rcStop] maybe?;
    [link suermStop];
    [link txcSendSIOS];
    [link pocStop];
    [link cancelEmergency];
    [link cancelLocalProcessorOutage];
    return [[UMM2PALinkStateControl_OutOfService alloc]initWithLink:link];
}


@end
#endif
