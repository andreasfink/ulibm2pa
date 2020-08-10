//
//  UMM2PATask_sctpStatusIndication.h
//  ulibm2pa
//
//  Created by Andreas Fink on 05/12/14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import <ulib/ulib.h>
#import <ulibsctp/ulibsctp.h>
@class UMLayerM2PA;

@interface UMM2PATask_sctpStatusIndication : UMLayerTask
{
    id          userId;
    UMSocketStatus status;
}

@property(readwrite,strong) id userId;
@property(readwrite,assign) UMSocketStatus status;

- (UMM2PATask_sctpStatusIndication *)initWithReceiver:(UMLayerM2PA *)rx
                                               sender:(id)tx
                                               userId:(id)uid
                                               status:(int)s;
- (void)main;

@end

