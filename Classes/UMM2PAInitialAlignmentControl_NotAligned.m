//
//  UMM2PAState_NotAligned.m
//  ulibm2pa
//
//  Created by Andreas Fink on 05/12/14.
//  Copyright (c) 2016 Andreas Fink
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import "UMM2PAInitialAlignmentControl_NotAligned.h"
#import "UMM2PAInitialAlignmentControl_AllStates.h"
#import "UMLayerM2PA.h"

@implementation UMM2PAInitialAlignmentControl_NotAligned


- (NSString *)description
{
    return @"UMM2PAInitialAlignmentControl_NotAligned";
}


- (UMM2PAInitialAlignmentControl_NotAligned *)initWithLink:(UMLayerM2PA *)link
{
    self = [super initWithLink:link];
    if(self)
    {
        [link.t2 start];        
    }
    return self;
}

- (UMM2PAInitialAlignmentControl_NotAligned *)init
{
    @throw([NSException exceptionWithName:@"API_ERROR"
                                   reason:@"don't call init. Call initWithLink: instead"
                                 userInfo:@{    @"backtrace":   UMBacktrace(NULL,0) }]);
}

- (UMM2PAInitialAlignmentControl_State *)eventStop:(UMLayerM2PA *)link
{
    [link.t2 stop];
    link.emergency=NO;
    return [[UMM2PAInitialAlignmentControl_Idle alloc]initWithLink:link];
}

- (UMM2PAInitialAlignmentControl_State *)eventTimer2:(UMLayerM2PA *)link
{
    link.emergency=NO;
    link.iacState = [[UMM2PAInitialAlignmentControl_Idle alloc]initWithLink:link];
    [link lscAlignmentNotPossible]; /* this call might change the state */
    return link.iacState;

}

- (UMM2PAInitialAlignmentControl_State *)eventSIX:(UMLayerM2PA *)link
{
    [[link t2]stop];
    if(link.emergency)
    {
        /* use emergency proving period */
        [[link t4] setDuration:link.t4e];
        [link.t4 start];
        [link txcSendSIE];
    }
    else
    {
        /* use normal proving period */
        [[link t4] setDuration:link.t4n];
        [link.t4 start];
        [link txcSendSIN];
    }
    [[link t3]start];
    return [[UMM2PAInitialAlignmentControl_Aligned alloc]initWithLink:link];
}

- (UMM2PAInitialAlignmentControl_State *)eventSIO:(UMLayerM2PA *)link
{
    return [self eventSIX:link];
}

- (UMM2PAInitialAlignmentControl_State *)eventSIN:(UMLayerM2PA *)link
{
    return [self eventSIX:link];
}

- (UMM2PAInitialAlignmentControl_State *)eventSIE:(UMLayerM2PA *)link
{
    return [self eventSIX:link];
}

- (UMM2PAInitialAlignmentControl_State *)eventEmergency:(UMLayerM2PA *)link
{
    link.emergency = YES;
    return self;
}

@end
