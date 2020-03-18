//
//  UMM2PAInitialAlignmentControl_BothProcessorsOut.m
//  ulibm2pa
//
//  Created by Andreas Fink on 29.11.18.
//  Copyright © 2018 Andreas Fink (andreas@fink.org). All rights reserved.
//
#if defined(OLD_IMPLMENETATION)

#import "UMM2PAInitialAlignmentControl_BothProcessorsOut.h"
#import "UMM2PAInitialAlignmentControl_AllStates.h"
#import "UMLayerM2PA.h"

@implementation UMM2PAInitialAlignmentControl_BothProcessorsOut

- (NSString *)description
{
	return @"both-processors-out";
}

- (UMM2PAInitialAlignmentControl_State *)eventLocalProcessorRecovered:(UMLayerM2PA *)link
{
	[self logEvent:@(__func__)];
	[link pocLocalProcessorRecovered];
	return [[UMM2PAInitialAlignmentControl_RemoteProcessorOutage alloc]initWithLink:link];
}


- (UMM2PAInitialAlignmentControl_State *)eventRemoteProcessorRecovered:(UMLayerM2PA *)link
{
	[self logEvent:@(__func__)];
	[link pocRemoteProcessorRecovered];
	return [[UMM2PAInitialAlignmentControl_LocalProcessorOutage alloc]initWithLink:link];
}

- (UMM2PAInitialAlignmentControl_State *)eventStop:(UMLayerM2PA *)link
{
	[self logEvent:@(__func__)];
	[link pocStop];
	return [[UMM2PAInitialAlignmentControl_Idle alloc]initWithLink:link];
}

@end
#endif
