//
//  UMM2PALinkStateControl_State.h
//  ulibm2pa
//
//  Created by Andreas Fink on 05/12/14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import "UMM2PAInitialAlignmentControl_State.h"
@class UMLayerM2PA;

@interface UMM2PALinkStateControl_State : UMObject
{
    UMLayerM2PA __weak *_link;
}

- (UMM2PALinkStateControl_State *)initWithLink:(UMLayerM2PA *)link;
- (UMM2PALinkStateControl_State *)eventAlignmentNotPossible:(UMLayerM2PA *)link;
- (UMM2PALinkStateControl_State *)eventAlignmentComplete:(UMLayerM2PA *)link;
- (UMM2PALinkStateControl_State *)eventEmergency:(UMLayerM2PA *)link;
- (UMM2PALinkStateControl_State *)eventEmergencyCeases:(UMLayerM2PA *)link;
- (UMM2PALinkStateControl_State *)eventFisu:(UMLayerM2PA *)link;
- (UMM2PALinkStateControl_State *)eventLinkFailure:(UMLayerM2PA *)link;
- (UMM2PALinkStateControl_State *)eventLocalProcessorOutage:(UMLayerM2PA *)link;
- (UMM2PALinkStateControl_State *)eventLocalProcessorRecovered:(UMLayerM2PA *)link;
- (UMM2PALinkStateControl_State *)eventMsu:(UMLayerM2PA *)link;
- (UMM2PALinkStateControl_State *)eventPowerOn:(UMLayerM2PA *)link;
- (UMM2PALinkStateControl_State *)eventPowerOff:(UMLayerM2PA *)link;
- (UMM2PALinkStateControl_State *)eventSIE:(UMLayerM2PA *)link;
- (UMM2PALinkStateControl_State *)eventSIN:(UMLayerM2PA *)link;
- (UMM2PALinkStateControl_State *)eventSIO:(UMLayerM2PA *)link;
- (UMM2PALinkStateControl_State *)eventSIOS:(UMLayerM2PA *)link;
- (UMM2PALinkStateControl_State *)eventSIPO:(UMLayerM2PA *)link;
- (UMM2PALinkStateControl_State *)eventSIB:(UMLayerM2PA *)link;
- (UMM2PALinkStateControl_State *)eventStart:(UMLayerM2PA *)link;
- (UMM2PALinkStateControl_State *)eventStop:(UMLayerM2PA *)link;
- (UMM2PALinkStateControl_State *)eventTimer1:(UMLayerM2PA *)link;
- (UMM2PALinkStateControl_State *)eventFlushBuffers:(UMLayerM2PA *)link; /* from MTP3 */
- (UMM2PALinkStateControl_State *)eventContinue:(UMLayerM2PA *)link; /* from MTP3 */
- (UMM2PALinkStateControl_State *)eventNoProcessorOutage:(UMLayerM2PA *)link; /* from POC */


@end
