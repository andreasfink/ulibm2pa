//
//  UMM2PALinkStateControl_Idle.h
//  ulibm2pa
//
//  Created by Andreas Fink on 29.11.18.
//  Copyright © 2018 Andreas Fink (andreas@fink.org). All rights reserved.
//
#if defined(OLD_IMPLEMENTATION)

#import "UMM2PALinkStateControl_State.h"

@interface UMM2PALinkStateControl_Idle : UMM2PALinkStateControl_State

- (UMM2PALinkStateControl_Idle *)initWithLink:(UMLayerM2PA *)link;

@end
#endif

