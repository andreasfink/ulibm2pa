//
//  UMM2PATask_AdminAttach.h
//  ulibm2pa
//
//  Created by Andreas Fink on 01.12.14.
//  Copyright (c) 2016 Andreas Fink
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import <ulib/ulib.h>
#import "UMLayerM2PAUserProtocol.h"

@class UMLayerM2PA;
@class UMLayerM2PAUserProfile;

@interface UMM2PATask_AdminAttach : UMLayerTask
{
    UMLayerM2PAUserProfile *profile;
    int slc;
    int ni;
    id  userId;
}
@property (readwrite,strong) UMLayerM2PAUserProfile *profile;
@property (readwrite,strong) id userId;
@property (readwrite,assign) int ni;
@property (readwrite,assign) int slc;

- (UMM2PATask_AdminAttach *)initWithReceiver:(UMLayerM2PA *)rx
                                      sender:(id<UMLayerM2PAUserProtocol>)tx
                                     profile:(UMLayerM2PAUserProfile *)profile
                                          ni:(int)xni
                                         slc:(int)xslc
                                      userId:(id)uid;
- (void)main;

@end
