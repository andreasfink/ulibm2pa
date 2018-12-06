//
//  UMM2PALinkStateControl_InService.m
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

@implementation UMM2PALinkStateControl_InService

-(NSString *)description
{
    return @"in-service";
}

- (UMM2PALinkStateControl_InService *)initWithLink:(UMLayerM2PA *)link
{
    self =[super initWithLink:link];
    if(self)
    {
        [link resetSequenceNumbers];
    }
    return self;
}

- (UMM2PALinkStateControl_InService *)init
{
    @throw([NSException exceptionWithName:@"API_ERROR"
                                   reason:@"dont call init. Call initWithLink"
                                 userInfo:@{    @"backtrace":   UMBacktrace(NULL,0) }]);
}




- (UMM2PALinkStateControl_State *)eventLocalProcessorOutage:(UMLayerM2PA *)link
{
    [link pocLocalProcessorOutage];
    [link txcSendSIOS];
    [link rcRejectMsuFisu];
    link.local_processor_outage=YES;
    return [[UMM2PALinkStateControl_ProcessorOutage alloc]initWithLink:link];
}

- (UMM2PALinkStateControl_State *)eventFisu:(UMLayerM2PA *)link
{
    return self;
}

- (UMM2PALinkStateControl_State *)eventSIPO:(UMLayerM2PA *)link
{
    [link txcSendFISU];
    [link notifyMtp3RemoteProcessorOutage];
    [link pocRemoteProcessorOutage];
    link.local_processor_outage=YES;
    return [[UMM2PALinkStateControl_ProcessorOutage alloc]initWithLink:link];
}


- (UMM2PALinkStateControl_State *)eventStop:(UMLayerM2PA *)link
{
    [link suermStop];
    [link rcStop];
    [link txcSendSIOS];
    [link cancelEmergency];
    
    return [[UMM2PALinkStateControl_OutOfService alloc]initWithLink:link];
}

- (UMM2PALinkStateControl_State *)eventLinkFailure:(UMLayerM2PA *)link
{
    [link notifyMtp3OutOfService];
    return [self eventStop:link];
}

- (UMM2PALinkStateControl_State *)eventSIO:(UMLayerM2PA *)link
{
    return [self eventLinkFailure:link];
}

- (UMM2PALinkStateControl_State *)eventSIN:(UMLayerM2PA *)link
{
    return self; //[self eventLinkFailure:link];
}

- (UMM2PALinkStateControl_State *)eventSIE:(UMLayerM2PA *)link
{
    return self; //[self eventLinkFailure:link];
}

- (UMM2PALinkStateControl_State *)eventSIOS:(UMLayerM2PA *)link
{
    return [self eventLinkFailure:link];
}


@end
