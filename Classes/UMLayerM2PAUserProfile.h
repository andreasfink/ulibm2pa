//
//  UMLayerM2PAUserProfile.h
//  ulibm2pa
//
//  Created by Andreas Fink on 03.12.14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import <ulib/ulib.h>

@interface UMLayerM2PAUserProfile : UMObject
{
    BOOL allMessages;
    BOOL sctpLinkstateMessages;
    BOOL m2paLinkstateMessages;
    BOOL dataMessages;
    BOOL processorOutageMessages;
    
}

@property(readwrite,assign) BOOL allMessages;
@property(readwrite,assign) BOOL sctpLinkstateMessages;
@property(readwrite,assign) BOOL m2paLinkstateMessages;
@property(readwrite,assign) BOOL dataMessages;
@property(readwrite,assign) BOOL processorOutageMessages;



@property(readwrite,strong) NSArray *serviceIndicators;
@property(readwrite,strong) NSArray *networkIndicators;
- (UMLayerM2PAUserProfile *)initWithDefaultProfile;
- (BOOL) wantsDataMessages;
- (BOOL) wantsSctpLinkstateMessages;
- (BOOL) wantsM2PALinkstateMessages;
- (BOOL) wantsProcessorOutageMessages;

@end
