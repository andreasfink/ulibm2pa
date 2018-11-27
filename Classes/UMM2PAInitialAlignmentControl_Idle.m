//
//  UMM2PAState_Idle.m
//  ulibm2pa
//
//  Created by Andreas Fink on 05/12/14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import "UMM2PAInitialAlignmentControl_Idle.h"
#import "UMM2PAInitialAlignmentControl_AllStates.h"
#import "UMLayerM2PA.h"

@implementation UMM2PAInitialAlignmentControl_Idle

- (NSString *)description
{
    return @"idle";
}

- (NSString *)stateName
{
    return @"InitialAlignmentControl_Idle";
}

- (UMM2PAInitialAlignmentControl_Idle *)initWithLink:(UMLayerM2PA *)link
{
    self = [super initWithLink:link];
    if(self)
    {
        
    }
    return self;
}

- (UMM2PAInitialAlignmentControl_Idle *)init
{
    @throw([NSException exceptionWithName:@"API_ERROR"
                                   reason:@"don't call init. Call initWithLink: instead"
                                 userInfo:@{    @"backtrace":   UMBacktrace(NULL,0) }]);
}

- (UMM2PAInitialAlignmentControl_State *)eventStart:(UMLayerM2PA *)link
{
    [link txcSendSIO];
    return [[UMM2PAInitialAlignmentControl_NotAligned alloc]initWithLink:link];
}

- (UMM2PAInitialAlignmentControl_State *)eventEmergency:(UMLayerM2PA *)link
{
    link.emergency=YES;
    return self;
}

- (UMM2PAInitialAlignmentControl_State *)eventEmergencyCeases:(UMLayerM2PA *)link
{
    link.emergency=NO;
    return self;
}

- (UMM2PAInitialAlignmentControl_State *)eventPowerOff:(UMLayerM2PA *)link
{
    [link.t2 stop];
    return self;
}

@end
