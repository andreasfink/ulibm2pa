//
//  UMM2PATask_AdminAttachOrder.h
//  ulibm2pa
//
//  Created by Andreas Fink on 03/12/14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import <ulib/ulib.h>
#import <ulibsctp/ulibsctp.h>
#import "UMLayerM2PA.h"
#import "UMLayerM2PAUserProtocol.h"


@interface UMM2PATask_AdminAttachOrder : UMLayerTask
{
    UMLayerSctp *layer;
}
@property (readwrite,strong)    UMLayerSctp *layer;

- (UMM2PATask_AdminAttachOrder *)initWithReceiver:(UMLayerM2PA *)rx
                                           sender:(id<UMLayerM2PAUserProtocol>)tx
                                            layer:(UMLayerSctp *)l;
- (void)main;

@end
