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
    BOOL _allMessages;
    BOOL _sctpLinkstateMessages;
    BOOL _m2paLinkstateMessages;
    BOOL _dataMessages;
    BOOL _processorOutageMessages;
    BOOL _speedMessages;
    BOOL _owner;
}

@property(readwrite,assign) BOOL allMessages;
@property(readwrite,assign) BOOL sctpLinkstateMessages;
@property(readwrite,assign) BOOL m2paLinkstateMessages;
@property(readwrite,assign) BOOL dataMessages;
@property(readwrite,assign) BOOL processorOutageMessages;
@property(readwrite,assign) BOOL speedMessages;
@property(readwrite,assign) BOOL owner;



@property(readwrite,strong) NSArray *serviceIndicators;
@property(readwrite,strong) NSArray *networkIndicators;
- (UMLayerM2PAUserProfile *)initWithDefaultProfile;
- (BOOL) wantsDataMessages;
- (BOOL) wantsSctpLinkstateMessages;
- (BOOL) wantsM2PALinkstateMessages;
- (BOOL) wantsProcessorOutageMessages;
- (BOOL) wantsSpeedMessages;

@end
