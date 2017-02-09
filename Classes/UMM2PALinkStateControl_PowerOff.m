//
//  UMM2PALinkStateControl_PowerOff.m
//  ulibm2pa
//
//  Created by Andreas Fink on 05/12/14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import "UMM2PALinkStateControl_PowerOff.h"
#import "UMM2PALinkStateControl_AllStates.h"
#import "UMLayerM2PA.h"

@implementation UMM2PALinkStateControl_PowerOff

-(NSString *)description
{
    return @"UMM2PALinkStateControl_PowerOff";
}


- (UMM2PALinkStateControl_PowerOff *)initWithLink:(UMLayerM2PA *)link
{
    self =[super initWithLink:link];
    if(self)
    {
        [link.t2 start];
    }
    return self;
}

- (UMM2PALinkStateControl_PowerOff *)init
{
    @throw([NSException exceptionWithName:@"API_ERROR"
                                   reason:@"dont call init. Call initWithLink"
                                 userInfo:@{    @"backtrace":   UMBacktrace(NULL,0) }]);
}

- (UMM2PALinkStateControl_State *)eventPowerOn:(UMLayerM2PA *)link
{
    [link txcStart];
    [link txcSendSIOS];
    [link cancelProcessorOutage];
    [link cancelEmergency];
    return [[UMM2PALinkStateControl_OutOfService alloc]initWithLink:link];
}

@end
