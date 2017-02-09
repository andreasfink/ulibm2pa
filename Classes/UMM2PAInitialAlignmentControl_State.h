//
//  UMM2PAInitialAlignmentControl_State.h
//  ulibm2pa
//
//  Created by Andreas Fink on 05/12/14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import <ulib/ulib.h>
@class UMLayerM2PA;

@interface UMM2PAInitialAlignmentControl_State : UMObject
{
    UMLayerM2PA __weak *_link;
}

- (NSString *)description;

- (UMM2PAInitialAlignmentControl_State *)initWithLink:(UMLayerM2PA *)link;
- (UMM2PAInitialAlignmentControl_State *)eventStart:(UMLayerM2PA *)link;
- (UMM2PAInitialAlignmentControl_State *)eventStop:(UMLayerM2PA *)link;
- (UMM2PAInitialAlignmentControl_State *)eventSIO:(UMLayerM2PA *)link;
- (UMM2PAInitialAlignmentControl_State *)eventSIN:(UMLayerM2PA *)link;
- (UMM2PAInitialAlignmentControl_State *)eventSIE:(UMLayerM2PA *)link;
- (UMM2PAInitialAlignmentControl_State *)eventSIOS:(UMLayerM2PA *)link;
- (UMM2PAInitialAlignmentControl_State *)eventEmergency:(UMLayerM2PA *)link;
- (UMM2PAInitialAlignmentControl_State *)eventEmergencyCeases:(UMLayerM2PA *)link;
- (UMM2PAInitialAlignmentControl_State *)eventProvingPeriodExpires:(UMLayerM2PA *)link;
- (UMM2PAInitialAlignmentControl_State *)eventHighLinkErrorRate:(UMLayerM2PA *)link;
- (UMM2PAInitialAlignmentControl_State *)eventPowerOff:(UMLayerM2PA *)link;
- (UMM2PAInitialAlignmentControl_State *)eventProvingEnds:(UMLayerM2PA *)link;

@end
