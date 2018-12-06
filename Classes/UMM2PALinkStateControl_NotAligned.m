//
//  UMM2PALinkStateControl_NotAligned.m
//  ulibm2pa
//
//  Created by Andreas Fink on 29.11.18.
//  Copyright © 2018 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMM2PALinkStateControl_NotAligned.h"
#import "UMM2PALinkStateControl_AllStates.h"
#import "UMLayerM2PA.h"

@implementation UMM2PALinkStateControl_NotAligned


- (UMM2PALinkStateControl_State *)eventStop:(UMLayerM2PA *)link
{
	[link iacStop];
	/* txcSendSIO is done in IAC */
	[link.t2 stop];
	link.emergency=NO;
	return [[UMM2PALinkStateControl_Idle alloc]initWithLink:link];
}

- (UMM2PALinkStateControl_State *)eventTimer2:(UMLayerM2PA *)link
{
	[link lscAlignmentNotPossible];
	link.emergency=NO;
	return [[UMM2PALinkStateControl_Idle alloc]initWithLink:link];
}

- (UMM2PALinkStateControl_State *)eventEmergency:(UMLayerM2PA *)link
{
	link.emergency=YES;
	[link iacEmergency];
	return self;
}

- (UMM2PALinkStateControl_State *)eventSIO:(UMLayerM2PA *)link
{
	[link.t2 stop];
	if(link.emergency)
	{
		link.t4.seconds = link.t4e;
		[link txcSendSIE];
		[link.t4 start];
	}
	else
	{
		link.t4.seconds = link.t4n;
		[link txcSendSIN];
		[link.t4 start];
	}
	[link.t3 start];
	return [[UMM2PALinkStateControl_Aligned alloc]initWithLink:link];
}

- (UMM2PALinkStateControl_State *)eventSIN:(UMLayerM2PA *)link
{
	[link.t2 stop];
	if(link.emergency)
	{
		link.t4.seconds = link.t4e;
		[link txcSendSIE];
		[link.t4 start];
	}
	else
	{
		link.t4.seconds = link.t4n;
		[link txcSendSIN];
		[link.t4 start];
	}
	[link.t3 start];
	return [[UMM2PALinkStateControl_Aligned alloc]initWithLink:link];
}

- (UMM2PALinkStateControl_State *)eventSIE:(UMLayerM2PA *)link
{
    link.iac
	[link.t2 stop];
	if(link.emergency)
	{
		link.t4.seconds = link.t4e;
		[link txcSendSIE];
		[link.t4 start];
	}
	else
	{
		link.t4.seconds = link.t4n;
		[link txcSendSIN];
		[link.t4 start];
	}
	[link.t3 start];
	return [[UMM2PALinkStateControl_Aligned alloc]initWithLink:link];
}


@end
