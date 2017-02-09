//
//  UMM2PATask_AdminDetachOrder.h
//  ulibm2pa
//
//  Created by Andreas Fink on 03/12/14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import <ulib/ulib.h>
@class UMLayerM2PA;
#import "UMLayerM2PAUserProtocol.h"

@interface UMM2PATask_AdminDetachOrder : UMLayerTask
{
    id userId;
}
@property (readwrite,strong) id userId;
- (UMM2PATask_AdminDetachOrder *)initWithReceiver:(UMLayerM2PA *)rx
                                           sender:(id<UMLayerM2PAUserProtocol>)tx
                                           userId:(id)uid;
- (void)main;

@end
