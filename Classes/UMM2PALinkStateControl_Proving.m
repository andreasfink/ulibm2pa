//
//  UMM2PALinkStateControl_Proving.m
//  ulibm2pa
//
//  Created by Andreas Fink on 29.11.18.
//  Copyright © 2018 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMM2PALinkStateControl_Proving.h"
#import "UMM2PALinkStateControl_AllStates.h"
#import "UMLayerM2PA.h"

@implementation UMM2PALinkStateControl_Proving


- (UMM2PALinkStateControl_State *)eventSIO:(UMLayerM2PA *)link
{
	[link.iacState eventSIO:link];
	[link.t4 stop];
	[link aermStop];
	[link.t3 start];
	return [[UMM2PALinkStateControl_Aligned alloc]initWithLink:link];
}


- (UMM2PALinkStateControl_State *)eventFISU:(UMLayerM2PA *)link
{
	if(link.furtherProving) /* further proving */
	{
		[link.t4 stop];
		/* 5 */
		[link aermStart];
		[link cancelFurtherProving];
		[link.t4 start];
		return self;
	}
	else
	{
		/* 6 */
		return self;
	}
}

- (UMM2PALinkStateControl_State *)eventTimer4:(UMLayerM2PA *)link
{
	if(link.furtherProving) /* further proving */
	{
		/* 5 */
		[link aermStart];
		[link cancelFurtherProving];
		[link.t4 start];
		return self;
	}
	else
	{
		[link lscAlignmentComplete];
		/* 4 */
		[link aermStop];
		[link cancelEmergency];
		return [[UMM2PALinkStateControl_Idle alloc]initWithLink:link];
	}

}

- (UMM2PALinkStateControl_State *)eventSIOS:(UMLayerM2PA *)link
{
	[link.iacState eventSIOS:link];
	[link.t4 stop];
	[link lscAlignmentNotPossible];
	/* 4 */
	[link aermStop];
	[link cancelEmergency];
	return [[UMM2PALinkStateControl_Idle alloc]initWithLink:link];
}

- (UMM2PALinkStateControl_State *)eventStop:(UMLayerM2PA *)link
{
	[link iacStop];
	[link.t4 stop];
	/* 4 */
	[link aermStop];
	[link cancelEmergency];
	return [[UMM2PALinkStateControl_Idle alloc]initWithLink:link];
}


- (UMM2PALinkStateControl_State *)eventAbortProving:(UMLayerM2PA *)link
{
	if(link.provingSent > 5)
	{
		[link lscAlignmentNotPossible];
		[link.t4 stop];
		/* 4 */
		[link aermStop];
		[link cancelEmergency];
		return [[UMM2PALinkStateControl_Idle alloc]initWithLink:link];
	}
	else
	{
		[link markFurtherProving];
		return self;
	}
}

- (UMM2PALinkStateControl_State *)eventEmergency:(UMLayerM2PA *)link
{
	[link txcSendSIE];
	[link.t4 stop];
	link.t4.seconds = link.t4e;
	[link aermStop];
	[link aermStart];
	[link cancelFurtherProving];
	[link.t4 start];
	return self;
}

- (UMM2PALinkStateControl_State *)eventSIE:(UMLayerM2PA *)link
{
	if(link.t4.seconds == link.t4e)
	{
		return self;
	}
	[link.t4 stop];
	link.t4.seconds = link.t4e;
	[link aermStop];
	[link aermStart];
	[link cancelFurtherProving];
	[link.t4 start];
	return self;
}

@end
