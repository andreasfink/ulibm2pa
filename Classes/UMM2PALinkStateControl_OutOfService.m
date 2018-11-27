//
//  UMM2PALinkStateControl_OutOfService.m
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


@implementation UMM2PALinkStateControl_OutOfService

- (NSString *)stateName
{
    return @"LinkStateControl_OutOfService";
}

- (UMM2PALinkStateControl_OutOfService *)initWithLink:(UMLayerM2PA *)link
{
    self =[super initWithLink:link];
    if(self)
    {
        [link.t2 start];
    }
    return self;
}

- (UMM2PALinkStateControl_OutOfService *)init
{
    @throw([NSException exceptionWithName:@"API_ERROR"
                                   reason:@"dont call init. Call initWithLink"
                                 userInfo:@{    @"backtrace":   UMBacktrace(NULL,0) }]);
}

-(NSString *)description
{
    return @"oos";
}

- (UMM2PALinkStateControl_State *)eventSIO:(UMLayerM2PA *)link
{
    [link rcStart];
    [link txcStart];
    if(link.emergency)
    {
        [link iacEmergency];
    }
    [link iacStart];
    
    return [[UMM2PALinkStateControl_InitialAlignment alloc]initWithLink:link];
}

- (UMM2PALinkStateControl_State *)eventStart:(UMLayerM2PA *)link
{
    [link rcStart];
    [link txcStart];
    if(link.emergency)
    {
        [link iacEmergency];
    }
    [link iacStart];

    return [[UMM2PALinkStateControl_InitialAlignment alloc]initWithLink:link];
}

- (UMM2PALinkStateControl_State *)eventEmergency:(UMLayerM2PA *)link
{
    link.emergency = YES;
    return self;
}

- (UMM2PALinkStateControl_State *)eventEmergencyCeases:(UMLayerM2PA *)link
{
    link.emergency = NO;
    return self;
}


- (UMM2PALinkStateControl_State *)eventLocalProcessorOutage:(UMLayerM2PA *)link
{
    link.local_processor_outage = YES;
    return self;
}

- (UMM2PALinkStateControl_State *)eventLocalProcessorRecovered:(UMLayerM2PA *)link
{
    link.local_processor_outage = NO;
    return self;
}


- (UMM2PALinkStateControl_State *)eventSIE:(UMLayerM2PA *)link
{
    [link logDebug:@"OOS: eventSIE"];
    UMM2PALinkStateControl_State *state =[[UMM2PALinkStateControl_InitialAlignment alloc]initWithLink:link];
    return [state eventSIE:link];
}

- (UMM2PALinkStateControl_State *)eventSIN:(UMLayerM2PA *)link
{
    [link logDebug:@"OOS: eventSIN"];
    UMM2PALinkStateControl_State *state =[[UMM2PALinkStateControl_InitialAlignment alloc]initWithLink:link];
    return [state eventSIN:link];
}

- (UMM2PALinkStateControl_State *)eventSIOS:(UMLayerM2PA *)link
{
    [link logDebug:@"eventSIOS (we are already OOS)"];
    return self;
}

@end
