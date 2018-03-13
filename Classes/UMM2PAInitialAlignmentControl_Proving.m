//
//  UMM2PAState_Proving.m
//  ulibm2pa
//
//  Created by Andreas Fink on 05/12/14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import "UMM2PAInitialAlignmentControl_Proving.h"
#import "UMM2PAInitialAlignmentControl_AllStates.h"
#import "UMLayerM2PA.h"

@implementation UMM2PAInitialAlignmentControl_Proving


- (NSString *)description
{
    return @"proving";
}

- (UMM2PAInitialAlignmentControl_Proving *)initWithLink:(UMLayerM2PA *)link
{
    self = [super initWithLink:link];
    if(self)
    {
        
    }
    return self;
}

- (UMM2PAInitialAlignmentControl_Proving *)init
{
    @throw([NSException exceptionWithName:@"API_ERROR"
                                   reason:@"don't call init. Call initWithLink: instead"
                                 userInfo:@{    @"backtrace":   UMBacktrace(NULL,0) }]);
}

- (UMM2PAInitialAlignmentControl_State *)eventSIO:(UMLayerM2PA *)link
{
    [[link t4]stop];
    [link aermStop];
    [[link t3]start];
    return [[UMM2PAInitialAlignmentControl_Aligned alloc]initWithLink:link];
}


- (UMM2PAInitialAlignmentControl_State *)eventTimer4:(UMLayerM2PA *)link
{
    /* alignment complete */
    [link lscAlignmentComplete];
    [link aermStop];
    [link cancelEmergency];
    return [[UMM2PAInitialAlignmentControl_Idle alloc]initWithLink:link];
}

- (UMM2PAInitialAlignmentControl_State *)eventSIE:(UMLayerM2PA *)link
{
    if(link.t4.duration != link.t4e)
    {
        [link.t4 stop];
        link.t4.duration = link.t4e;
        [link aermStop];
        [link aermSetTe]; /****/
        [link aermStart];
        /* cancel Further Proving */
        [link.t4 start];
    }
    link.emergency = YES;
    /* shorten the timer maybe ? */
    return self; /* we stay in proving */
}

- (UMM2PAInitialAlignmentControl_State *)eventEmergency:(UMLayerM2PA *)link
{
    link.emergency = YES;
    [link txcSendSIE];
    /* shorten the timer maybe ? */
    return self; /* we stay in proving */
}

- (UMM2PAInitialAlignmentControl_State *)eventStop:(UMLayerM2PA *)link
{
 
    return [[UMM2PAInitialAlignmentControl_Idle alloc]initWithLink:link];
}

- (UMM2PAInitialAlignmentControl_State *)eventSIOS:(UMLayerM2PA *)link
{
    /* alignment not possible */
    return [[UMM2PAInitialAlignmentControl_Idle alloc]initWithLink:link];
}

- (UMM2PAInitialAlignmentControl_State *)eventHighLinkErrorRate:(UMLayerM2PA *)link
{
    /* alignment not possible */
    return [[UMM2PAInitialAlignmentControl_Idle alloc]initWithLink:link];
}


@end

