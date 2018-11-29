//
//  UMM2PAInitialAlignmentControl_LocalProcessorOutage.m
//  ulibm2pa
//
//  Created by Andreas Fink on 29.11.18.
//  Copyright © 2018 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMM2PAInitialAlignmentControl_LocalProcessorOutage.h"
#import "UMM2PAInitialAlignmentControl_AllStates.h"
#import "UMLayerM2PA.h"

@implementation UMM2PAInitialAlignmentControl_LocalProcessorOutage

- (NSString *)description
{
	return @"local-processor-outage";
}

- (UMM2PAInitialAlignmentControl_State *)eventStop:(UMLayerM2PA *)link
{
	return [[UMM2PAInitialAlignmentControl_Idle alloc]initWithLink:link];
}


- (UMM2PAInitialAlignmentControl_State *)eventRemoteProcessorOutage:(UMLayerM2PA *)link
{
	[link pocRemoteProcessorOutage];
	return [[UMM2PAInitialAlignmentControl_BothProcessorsOut alloc]initWithLink:link];
}

- (UMM2PAInitialAlignmentControl_State *)eventLocalProcessorRecovered:(UMLayerM2PA *)link
{
	[link pocLocalProcessorRecovered];
	[link lscNoProcessorOutage];
	return [[UMM2PAInitialAlignmentControl_Idle alloc]initWithLink:link];
}

@end
