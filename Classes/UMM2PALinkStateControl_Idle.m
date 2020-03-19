//
//  UMM2PALinkStateControl_Idle.m
//  ulibm2pa
//
//  Created by Andreas Fink on 29.11.18.
//  Copyright © 2018 Andreas Fink (andreas@fink.org). All rights reserved.
//

#if defined(OLD_IMPLEMENTATION)

#import "UMM2PALinkStateControl_Idle.h"
#import "UMM2PALinkStateControl_AllStates.h"
#import "UMLayerM2PA.h"

@implementation UMM2PALinkStateControl_Idle

-(NSString *)description
{
	return @"idle";
}

- (UMM2PALinkStateControl_Idle *)initWithLink:(UMLayerM2PA *)link
{
	self =[super initWithLink:link];
	if(self)
	{
	}
	return self;
}

- (UMM2PALinkStateControl_State *)eventEmergency:(UMLayerM2PA *)link
{
	[link iacEmergency];
	link.emergency=YES;
	return self;
}

- (UMM2PALinkStateControl_State *)eventStart:(UMLayerM2PA *)link
{
	[link iacStart];
	/* txcSendSIO is done in IAC */
	[link.t2 start];
	return [[UMM2PALinkStateControl_NotAligned alloc]initWithLink:link];
}


@end
#endif
