//
//  UMM2PATask_AdminSetConfig.h
//  ulibm2pa
//
//  Created by Andreas Fink on 01.12.14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import <ulib/ulib.h>
#import <ulibm2pa/UMLayerM2PAUserProtocol.h>

@class UMLayerM2PA;

@interface UMM2PATask_AdminSetConfig : UMLayerTask
{
    NSDictionary *config;
    id appContext;
}
@property(readwrite,strong)     NSDictionary *config;

- (UMM2PATask_AdminSetConfig *)initWithReceiver:(UMLayerM2PA *)receiver
                                         sender:(id<UMLayerM2PAUserProtocol>)sender
                                         config:(NSDictionary *)cfg
                             applicationContext:(id)appContext;
- (void)main;
- (id)applicationContext;

@end
