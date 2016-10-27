//
//  UMM2PAState_Aligned.m
//  ulibm2pa
//
//  Created by Andreas Fink on 05/12/14.
//  Copyright (c) 2016 Andreas Fink
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import "UMM2PAInitialAlignmentControl_Aligned.h"
#import "UMM2PAInitialAlignmentControl_AllStates.h"
#import "UMLayerM2PA.h"
@implementation UMM2PAInitialAlignmentControl_Aligned


- (NSString *)description
{
    return @"UMM2PAInitialAlignmentControl_Aligned";
}


- (UMM2PAInitialAlignmentControl_Aligned *)initWithLink:(UMLayerM2PA *)link
{
    self = [super initWithLink:link];
    if(self)
    {
        
    }
    return self;
}

- (UMM2PAInitialAlignmentControl_Aligned *)init
{
    @throw([NSException exceptionWithName:@"API_ERROR"
                                   reason:@"don't call init. Call initWithLink: instead"
                                 userInfo:@{    @"backtrace":   UMBacktrace(NULL,0) }]);
}

- (void)dealloc
{
    [_link.t3 stop];
    /*
     Q.703 page 17:
     – State "aligned": The signalling link is aligned and the terminal is sending status indication "N" or "E", status indications "N", "E" or "OS" are not received. Time-out T3 entry to State and stopped when State is left.
    */
}

- (UMM2PAInitialAlignmentControl_State *)eventStop:(UMLayerM2PA *)link
{
    [link.t3 stop];
    [link cancelEmergency];
    return [[UMM2PAInitialAlignmentControl_Idle alloc]initWithLink:link];
}

- (UMM2PAInitialAlignmentControl_State *)eventTimer3:(UMLayerM2PA *)link
{
    [link.t3 stop];
    [link cancelEmergency];
    link.iacState = [[UMM2PAInitialAlignmentControl_Idle alloc]initWithLink:link];
    [link lscAlignmentNotPossible];
    return link.iacState;
}

- (UMM2PAInitialAlignmentControl_State *)eventSIOS:(UMLayerM2PA *)link
{
    [link.t3 stop];
    [link cancelEmergency];
    link.iacState = [[UMM2PAInitialAlignmentControl_Idle alloc]initWithLink:link];
    [link lscAlignmentNotPossible];
    return link.iacState;
}

- (UMM2PAInitialAlignmentControl_State *)eventSIN:(UMLayerM2PA *)link
{
    [link.t3 stop];
    if([[link t4]duration] == link.t4e)
    {
        /* ?? set i to ie aerm */
    }
    [link.t4 start];
    /* Cp :=0 */
    /* cancel further proving */
    
   return  [[UMM2PAInitialAlignmentControl_Proving alloc]initWithLink:link];
}

- (UMM2PAInitialAlignmentControl_State *)eventSIE:(UMLayerM2PA *)link
{
    [link.t4 setDuration:link.t4e];
    return [self eventSIN:link];
}

- (UMM2PAInitialAlignmentControl_State *)eventEmergency:(UMLayerM2PA *)link
{
    [link txcSendSIE];
    [link.t4 setDuration:link.t4e];
    return self;
}


@end
