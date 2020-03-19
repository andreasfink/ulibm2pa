//
//  UMM2PAState_Aligned.m
//  ulibm2pa
//
//  Created by Andreas Fink on 05/12/14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#if defined(OLD_IMPLEMENTATION)

#import "UMM2PAInitialAlignmentControl_Aligned.h"
#import "UMM2PAInitialAlignmentControl_AllStates.h"
#import "UMLayerM2PA.h"
@implementation UMM2PAInitialAlignmentControl_Aligned

- (NSString *)description
{
    return @"aligned";
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
	[self logEvent:@(__func__)];
    [link.t3 stop];
    [link cancelEmergency];
    return [[UMM2PAInitialAlignmentControl_Idle alloc]initWithLink:link];
}

- (UMM2PAInitialAlignmentControl_State *)eventTimer3:(UMLayerM2PA *)link
{
	[self logEvent:@(__func__)];
    [link.t3 stop];
    [link cancelEmergency];
    link.iacState = [[UMM2PAInitialAlignmentControl_Idle alloc]initWithLink:link];
    [link lscAlignmentNotPossible];
    return link.iacState;
}

- (UMM2PAInitialAlignmentControl_State *)eventSIOS:(UMLayerM2PA *)link
{
	[self logEvent:@(__func__)];
    [link.t3 stop];
    [link cancelEmergency];
    link.iacState = [[UMM2PAInitialAlignmentControl_Idle alloc]initWithLink:link];
    [link lscAlignmentNotPossible];
    return link.iacState;
}

- (UMM2PAInitialAlignmentControl_State *)eventSIN:(UMLayerM2PA *)link
{
	[self logEvent:@(__func__)];
    [link.t3 stop];
    if(link.emergency)
    {
        /* use emergency proving period */
        link.t4.seconds = link.t4e;
    }
    else
    {
        link.t4.seconds = link.t4n;
    }
    [link.t4 start];
    /* Cp :=0 */
    /* cancel further proving */
    
   return  [[UMM2PAInitialAlignmentControl_Proving alloc]initWithLink:link];
}

- (UMM2PAInitialAlignmentControl_State *)eventSIE:(UMLayerM2PA *)link
{
	[self logEvent:@(__func__)];
    link.t4.seconds = link.t4e;
    return [self eventSIN:link];
}

- (UMM2PAInitialAlignmentControl_State *)eventEmergency:(UMLayerM2PA *)link
{
	[self logEvent:@(__func__)];
    [link txcSendSIE];
    link.t4.seconds = link.t4e;
    return self;
}


@end
#endif
