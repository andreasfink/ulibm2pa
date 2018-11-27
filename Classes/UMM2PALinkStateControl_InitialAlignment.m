//
//  UMM2PALinkStateControl_InitialAlignment.m
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

@implementation UMM2PALinkStateControl_InitialAlignment

- (NSString *)stateName
{
    return @"LinkStateControl_InitialAlignment";
}

- (UMM2PALinkStateControl_InitialAlignment *)initWithLink:(UMLayerM2PA *)link
{
    self =[super initWithLink:link];
    if(self)
    {
    }
    return self;
}

- (UMM2PALinkStateControl_InitialAlignment *)init
{
    @throw([NSException exceptionWithName:@"API_ERROR"
                                   reason:@"dont call init. Call initWithLink"
                                 userInfo:@{    @"backtrace":   UMBacktrace(NULL,0) }]);
}


-(NSString *)description
{
    return @"initial-alignment";
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


- (UMM2PALinkStateControl_State *)eventEmergency:(UMLayerM2PA *)link
{
    link.emergency = YES;
    [link iacEmergency];
    return self;
}

- (UMM2PALinkStateControl_State *)eventAlignmentComplete:(UMLayerM2PA *)link
{
    [link suermStart];
    [link.t1 start];
    if(link.local_processor_outage)
    {
        [link pocLocalProcessorOutage];
        [link txcSendSIPO];
        [link rcRejectMsuFisu];
        return [[UMM2PALinkStateControl_AlignedNotReady alloc]initWithLink:link];
    }
    else
    {
        [link txcSendFISU]; /* sends READY */
        [link.t1 stop];
        [link.t4 stop];
        [link.t4r stop];
        [link setM2pa_status:M2PA_STATUS_IS];
        [link resetSequenceNumbers];
        return [[UMM2PALinkStateControl_InService alloc]initWithLink:link];
    }
}

- (UMM2PALinkStateControl_State *)_eventDown:(UMLayerM2PA *)link
{
    [link rcStop];
    [link txcSendSIOS];
    link.local_processor_outage = NO;
    link.emergency = NO;
    return [[UMM2PALinkStateControl_OutOfService alloc]initWithLink:link];
}

- (UMM2PALinkStateControl_State *)eventLinkFailure:(UMLayerM2PA *)link
{
    [link notifyMtp3OutOfService];
    [link iacStop];
    return [self _eventDown:link];
}

- (UMM2PALinkStateControl_State *)eventAlignmentNotPossible:(UMLayerM2PA *)link
{
    [link notifyMtp3OutOfService];
    return [self _eventDown:link];
}

- (UMM2PALinkStateControl_State *)eventStop:(UMLayerM2PA *)link
{
    [link iacStop];
    return [self _eventDown:link];
}

- (UMM2PALinkStateControl_State *)eventFisu:(UMLayerM2PA *)link
{
    return [self eventAlignmentComplete:link];
}

- (UMM2PALinkStateControl_State *)eventSIE:(UMLayerM2PA *)link
{
    return self;
}

- (UMM2PALinkStateControl_State *)eventSIN:(UMLayerM2PA *)link
{
    return self;
}

- (UMM2PALinkStateControl_State *)eventSIOS:(UMLayerM2PA *)link
{
    [link iacStop];
    return [[UMM2PALinkStateControl_OutOfService alloc]initWithLink:link];
}

@end
