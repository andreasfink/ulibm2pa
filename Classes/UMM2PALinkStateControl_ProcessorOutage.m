//
//  UMM2PALinkStateControl_ProcessorOutage.m
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

@implementation UMM2PALinkStateControl_ProcessorOutage

- (NSString *)stateName
{
    return @"LinkStateControl_ProcessorOutage";
}

- (UMM2PALinkStateControl_ProcessorOutage *)initWithLink:(UMLayerM2PA *)link
{
    self =[super initWithLink:link];
    if(self)
    {
    }
    return self;
}

- (UMM2PALinkStateControl_ProcessorOutage *)init
{
    @throw([NSException exceptionWithName:@"API_ERROR"
                                   reason:@"dont call init. Call initWithLink"
                                 userInfo:@{    @"backtrace":   UMBacktrace(NULL,0) }]);
}

-(NSString *)description
{
    return @"processor-outage";
}


- (UMM2PALinkStateControl_State *)eventFisu:(UMLayerM2PA *)link
{
    [link pocRemoteProcessorRecovered];
    [link notifyMtp3RemoteProcessorRecovered];
    return self;
}


- (UMM2PALinkStateControl_State *)eventLocalProcessorOutage:(UMLayerM2PA *)link
{
    [link pocLocalProcessorOutage];
    [link txcSendSIPO];
    return self;
}


- (UMM2PALinkStateControl_State *)eventSIPO:(UMLayerM2PA *)link
{
    [link notifyMtp3RemoteProcessorOutage];
    [link pocRemoteProcessorOutage];
    return self;
}

- (UMM2PALinkStateControl_State *)eventLocalProcessorRecovered:(UMLayerM2PA *)link
{
    [link pocLocalProcessorRecovered];
    [link txcSendFISU];
    return self;
}

- (UMM2PALinkStateControl_State *)eventFlushBuffers:(UMLayerM2PA *)link
{
    [link txcFlushBuffers];
    link.level3Indication=YES;
    if((link.local_processor_outage==NO)&&(link.remote_processor_outage==NO))
    {
        link.level3Indication=NO;
        [link txcSendFISU];
        [link cancelProcessorOutage];
        [link rcAcceptMsuFisu];
        [link.t1 stop];
        [link.t4 stop];
        [link.t4r stop];
        return [[UMM2PALinkStateControl_InService alloc]initWithLink:link];
    }
    else
    {
        return self;
    }
}

- (UMM2PALinkStateControl_State *)eventNoProcessorOutage:(UMLayerM2PA *)link
{
    [link cancelProcessorOutage];
    if(link.level3Indication)
    {
        link.level3Indication=NO;
        [link txcSendFISU];
        [link cancelProcessorOutage];
        [link rcAcceptMsuFisu];
        [link.t1 stop];
        [link.t4 stop];
        [link.t4r stop];
        return [[UMM2PALinkStateControl_InService alloc]initWithLink:link];
    }
    else
    {
        return self;
    }
}

- (UMM2PALinkStateControl_State *)eventSIO:(UMLayerM2PA *)link
{
    return [self eventLinkFailure:link];
}

- (UMM2PALinkStateControl_State *)eventSIE:(UMLayerM2PA *)link
{
    return [self eventLinkFailure:link];
}
- (UMM2PALinkStateControl_State *)eventSIN:(UMLayerM2PA *)link
{
    return [self eventLinkFailure:link];
}

- (UMM2PALinkStateControl_State *)eventSIOS:(UMLayerM2PA *)link
{
    return [self eventLinkFailure:link];
}


- (UMM2PALinkStateControl_State *)eventLinkFailure:(UMLayerM2PA *)link
{
    [link notifyMtp3OutOfService];
    return [self eventStop:link];
}

- (UMM2PALinkStateControl_State *)eventStop:(UMLayerM2PA *)link
{
    [link suermStop];
    [link rcStop];
    [link pocStop];
    [link txcSendSIOS];
    [link cancelEmergency];
    [link cancelProcessorOutage];
    return [[UMM2PALinkStateControl_OutOfService alloc]initWithLink:link];
}


@end
