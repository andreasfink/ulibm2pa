//
//  UMM2PATask_Emergency.h
//  ulibm2pa
//
//  Created by Andreas Fink on 02.12.14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import <ulib/ulib.h>
#import <ulibm2pa/UMLayerM2PAUserProtocol.h>

@class UMLayerM2PA;

@interface UMM2PATask_Emergency : UMLayerTask
{
    
}

- (UMM2PATask_Emergency *)initWithReceiver:(UMLayerM2PA *)rx sender:(id<UMLayerUserProtocol>)tx;
- (void)main;

@end


