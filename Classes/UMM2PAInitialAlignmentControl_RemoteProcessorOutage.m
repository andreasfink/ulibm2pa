//
//  UMM2PAInitialAlignmentControl_RemoteProcessorOutage.m
//  ulibm2pa
//
//  Created by Andreas Fink on 29.11.18.
//  Copyright © 2018 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMM2PAInitialAlignmentControl_RemoteProcessorOutage.h"
#import "UMM2PAInitialAlignmentControl_AllStates.h"
#import "UMLayerM2PA.h"

@implementation UMM2PAInitialAlignmentControl_RemoteProcessorOutage

- (NSString *)description
{
	return @"remote-processor-outage";
}

- (UMM2PAInitialAlignmentControl_State *)eventLocalProcessorOutage:(UMLayerM2PA *)link
{
	[link pocLocalProcessorOutage];
	return [[UMM2PAInitialAlignmentControl_BothProcessorsOut alloc]initWithLink:link];
}


- (UMM2PAInitialAlignmentControl_State *)eventRemoteProcessorRecovered:(UMLayerM2PA *)link
{
	[link pocRemoteProcessorRecovered];
	[link lscNoProcessorOutage];
	return [[UMM2PAInitialAlignmentControl_Idle alloc]initWithLink:link];
}

- (UMM2PAInitialAlignmentControl_State *)eventStop:(UMLayerM2PA *)link
{
	[link pocStop];
	return [[UMM2PAInitialAlignmentControl_Idle alloc]initWithLink:link];
}

@end
