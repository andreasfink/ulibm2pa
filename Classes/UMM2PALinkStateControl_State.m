//
//  UMM2PALinkStateControl_State.m
//  ulibm2pa
//
//  Created by Andreas Fink on 05/12/14.
//  Copyright (c) 2016 Andreas Fink
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import "UMM2PALinkStateControl_AllStates.h"
#import "UMLayerM2PA.h"

@implementation UMM2PALinkStateControl_State


-(NSString *)description
{
    return @"UMM2PALinkStateControl_State";
}

- (UMM2PALinkStateControl_State *)eventAlignmentNotPossible:(UMLayerM2PA *)link
{
    [link logDebug:@"Unexpected eventAlignmentNotPossible"];
    return self;
}

- (UMM2PALinkStateControl_State *)eventAlignmentComplete:(UMLayerM2PA *)link
{
    [link logDebug:@"Unexpected eventAlignmentComplete"];
    return self;
}

- (UMM2PALinkStateControl_State *)eventEmergency:(UMLayerM2PA *)link
{
    [link logDebug:@"Unexpected eventEmergency"];
    return self;
}
- (UMM2PALinkStateControl_State *)eventEmergencyCeases:(UMLayerM2PA *)link
{
    [link logDebug:@"Unexpected eventEmergencyCeases"];
    return self;
}
- (UMM2PALinkStateControl_State *)eventFisu:(UMLayerM2PA *)link
{
    [link logDebug:@"Unexpected eventFisu"];
    return self;
}
- (UMM2PALinkStateControl_State *)eventLinkFailure:(UMLayerM2PA *)link
{
    [link logDebug:@"Unexpected eventLinkFailure"];
    return self;
}
- (UMM2PALinkStateControl_State *)eventLocalProcessorOutage:(UMLayerM2PA *)link
{
    [link logDebug:@"Unexpected eventLocalProcessorOutage"];
    return self;
}
- (UMM2PALinkStateControl_State *)eventLocalProcessorRecovered:(UMLayerM2PA *)link
{
    [link logDebug:@"Unexpected eventLocalProcessorRecovered"];
    return self;
}
- (UMM2PALinkStateControl_State *)eventMsu:(UMLayerM2PA *)link
{
    [link logDebug:@"Unexpected eventMsu"];
    return self;
}
- (UMM2PALinkStateControl_State *)eventPowerOn:(UMLayerM2PA *)link
{
    [link logDebug:@"Unexpected eventPowerOn"];
    return self;
}
- (UMM2PALinkStateControl_State *)eventSIE:(UMLayerM2PA *)link
{
    [link logDebug:@"Unexpected eventSIE"];
    return self;
}
- (UMM2PALinkStateControl_State *)eventSIN:(UMLayerM2PA *)link
{
    [link logDebug:@"Unexpected eventSIN"];
    return self;
}
- (UMM2PALinkStateControl_State *)eventSIO:(UMLayerM2PA *)link
{
    [link logDebug:@"Unexpected eventSIO"];
    return self;
}
- (UMM2PALinkStateControl_State *)eventSIOS:(UMLayerM2PA *)link
{
    [link logDebug:@"Unexpected eventSIOS"];
    return self;
}
- (UMM2PALinkStateControl_State *)eventSIPO:(UMLayerM2PA *)link
{
    [link logDebug:@"Unexpected eventSIPO"];
    return self;
}
- (UMM2PALinkStateControl_State *)eventStart:(UMLayerM2PA *)link
{
    [link logDebug:@"Unexpected eventStart"];
    return self;
}
- (UMM2PALinkStateControl_State *)eventStop:(UMLayerM2PA *)link
{
    [link logDebug:@"Unexpected eventStop"];
    return self;
}
- (UMM2PALinkStateControl_State *)eventTimer1:(UMLayerM2PA *)link
{
    [link logDebug:@"Unexpected eventTimer1"];
    return self;
}

- (UMM2PALinkStateControl_State *)eventFlushBuffers:(UMLayerM2PA *)link
{
    [link logDebug:@"Unexpected eventFlushBuffers"];
    return self;
    
}

- (UMM2PALinkStateControl_State *)eventContinue:(UMLayerM2PA *)link
{
    [link logDebug:@"Unexpected eventContinue"];
    return self;
    
}

- (UMM2PALinkStateControl_State *)eventNoProcessorOutage:(UMLayerM2PA *)link
{
    [link logDebug:@"Unexpected eventNoProcessorOutage"];
    return self;
}

- (UMM2PALinkStateControl_State *)eventSIB:(UMLayerM2PA *)link
{
    [link logDebug:@"Unexpected eventSIB"];
    return self;
}

- (UMM2PALinkStateControl_State *)eventPowerOff:(UMLayerM2PA *)link
{
    [link logDebug:@"Event PowerOff"];
    return [[UMM2PALinkStateControl_PowerOff alloc]initWithLink:link];
}

- (UMM2PALinkStateControl_State *)initWithLink:(UMLayerM2PA *)link
{
    self =[super init];
    if(self)
    {
        _link = link;
    }
    return self;
}


@end
