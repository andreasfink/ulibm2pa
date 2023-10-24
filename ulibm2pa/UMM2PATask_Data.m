//
//  UMM2PATask_Data.m
//  ulibm2pa
//
//  Created by Andreas Fink on 02.12.14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import "UMM2PATask_Data.h"
#import "UMLayerM2PA.h"
#import "UMLayerM2PAUserProtocol.h"

@implementation UMM2PATask_Data

- (UMM2PATask_Data *)initWithReceiver:(UMLayerM2PA *)rx
                               sender:(id<UMLayerM2PAUserProtocol>)tx
                                 data:(NSData *)d
                           ackRequest:(NSDictionary *)ack
                                  dpc:(int)dpc
{
    self = [super initWithName:[[self class]description]  receiver:rx sender:tx requiresSynchronisation:NO];
    if(self)
    {
        _data = d;
        _ackRequest = ack;
        self.receiver = rx;
        _dpc = dpc;
    }
    return self;
}

- (void)main
{
    @autoreleasepool
    {
        UMLayerM2PA *link = (UMLayerM2PA *)self.receiver;
        [link _dataTask:self];
    }
}

@end
