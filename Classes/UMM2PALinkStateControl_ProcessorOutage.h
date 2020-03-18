//
//  UMM2PALinkStateControl_ProcessorOutage.h
//  ulibm2pa
//
//  Created by Andreas Fink on 05/12/14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#if defined(OLD_IMPLMENETATION)

#import "UMM2PALinkStateControl_State.h"

@interface UMM2PALinkStateControl_ProcessorOutage : UMM2PALinkStateControl_State

- (UMM2PALinkStateControl_ProcessorOutage *)initWithLink:(UMLayerM2PA *)link;

@end
#endif

