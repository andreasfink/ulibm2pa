//
//  UMM2PALinkStateControl_Aligned.m
//  ulibm2pa
//
//  Created by Andreas Fink on 29.11.18.
//  Copyright © 2018 Andreas Fink (andreas@fink.org). All rights reserved.
//
#if defined(OLD_IMPLMENETATION)

#import "UMM2PALinkStateControl_Aligned.h"
#import "UMM2PALinkStateControl_AllStates.h"
#import "UMLayerM2PA.h"

@implementation UMM2PALinkStateControl_Aligned



- (UMM2PALinkStateControl_State *)eventSIN:(UMLayerM2PA *)link
{
	link.t4.seconds = link.t4n;
	[link.t3 stop];
	[link.t4 start];
	return [[UMM2PALinkStateControl_Aligned alloc]initWithLink:link];
}

- (UMM2PALinkStateControl_State *)eventSIE:(UMLayerM2PA *)link
{
	link.t4.seconds = link.t4e;
	[link.t3 stop];
	[link.t4 start];
	return [[UMM2PALinkStateControl_Aligned alloc]initWithLink:link];
}

- (UMM2PALinkStateControl_State *)eventEmergency:(UMLayerM2PA *)link
{
	[link txcSendSIE];
	link.t4.seconds = link.t4e;
	return [[UMM2PALinkStateControl_Aligned alloc]initWithLink:link];
}

- (UMM2PALinkStateControl_State *)eventStop:(UMLayerM2PA *)link
{
	[link.t3 stop];
	[link cancelEmergency];
	return [[UMM2PALinkStateControl_Idle alloc]initWithLink:link];
}

- (UMM2PALinkStateControl_State *)eventTimer3:(UMLayerM2PA *)link
{
	[link lscAlignmentNotPossible];
	[link cancelEmergency];
	return [[UMM2PALinkStateControl_Idle alloc]initWithLink:link];
}

- (UMM2PALinkStateControl_State *)eventSIOS:(UMLayerM2PA *)link
{
	[link lscAlignmentNotPossible];
	[link.t3 stop];
	[link cancelEmergency];
	return [[UMM2PALinkStateControl_Idle alloc]initWithLink:link];
}
@end
#endif
