//
//  UMM2PAInitialAlignmentControl_State.m
//  ulibm2pa
//
//  Created by Andreas Fink on 05/12/14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import "UMM2PAInitialAlignmentControl_State.h"
#import "UMM2PAInitialAlignmentControl_AllStates.h"
#import "UMLayerM2PA.h"


@implementation UMM2PAInitialAlignmentControl_State

-(NSString *)description
{
    return @"undefined";
}


- (UMM2PAInitialAlignmentControl_State *)initWithLink:(UMLayerM2PA *)link
{
    self =[super init];
    if(self)
    {
        
    }
    return self;
}

- (UMM2PAInitialAlignmentControl_State *)init
{
    @throw([NSException exceptionWithName:@"API_ERROR"
                                   reason:@"don't call init. Call initWithLink: instead"
                                 userInfo:@{    @"backtrace":   UMBacktrace(NULL,0) }]);
}


- (UMM2PAInitialAlignmentControl_State *)eventStart:(UMLayerM2PA *)link
{
    return self;
}

- (UMM2PAInitialAlignmentControl_State *)eventStop:(UMLayerM2PA *)link
{
    return self;

}
- (UMM2PAInitialAlignmentControl_State *)eventSIO:(UMLayerM2PA *)link
{
    return self;
  
}
- (UMM2PAInitialAlignmentControl_State *)eventSIN:(UMLayerM2PA *)link
{
    return self;
}

- (UMM2PAInitialAlignmentControl_State *)eventSIE:(UMLayerM2PA *)link
{
    return self;
 
}
- (UMM2PAInitialAlignmentControl_State *)eventSIOS:(UMLayerM2PA *)link
{
    return [[UMM2PAInitialAlignmentControl_Idle alloc]initWithLink:link];
}

- (UMM2PAInitialAlignmentControl_State *)eventEmergency:(UMLayerM2PA *)link
{
    return self;

}

- (UMM2PAInitialAlignmentControl_State *)eventEmergencyCeases:(UMLayerM2PA *)link
{
    return self;
    
}


- (UMM2PAInitialAlignmentControl_State *)eventProvingPeriodExpires:(UMLayerM2PA *)link
{
    return self;

}
- (UMM2PAInitialAlignmentControl_State *)eventHighLinkErrorRate:(UMLayerM2PA *)link
{
    return self;

}

- (UMM2PAInitialAlignmentControl_State *)eventProvingResendEvent:(UMLayerM2PA *)link
{
    return self;
}

- (UMM2PAInitialAlignmentControl_State *)eventPowerOff:(UMLayerM2PA *)link
{
    return [[UMM2PAInitialAlignmentControl_Idle alloc] initWithLink:link];
}

- (UMM2PAInitialAlignmentControl_State *)eventProvingEnds:(UMLayerM2PA *)link
{
    return [[UMM2PAInitialAlignmentControl_Idle alloc] initWithLink:link];
}

- (UMM2PAInitialAlignmentControl_State *)eventTimer4:(UMLayerM2PA *)link
{
    return self;
}

- (UMM2PAInitialAlignmentControl_State *)eventTimer4r:(UMLayerM2PA *)link
{
    [link.t4r stop]; /* if we are not in alignment state, we are ignoring it */
    return self;
}


@end
