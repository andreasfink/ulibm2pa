//
//  UMM2PATask_PowerOff.m
//  ulibm2pa
//
//  Created by Andreas Fink on 02.12.14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import "UMM2PATask_PowerOff.h"
#import "UMLayerM2PA.h"
#import "UMLayerM2PAUserProtocol.h"

@implementation UMM2PATask_PowerOff

- (UMM2PATask_PowerOff *)initWithReceiver:(UMLayer *)rx
                                   sender:(id<UMLayerM2PAUserProtocol>)tx;
{
    self = [super initWithName:[[self class]description]  receiver:rx sender:tx requiresSynchronisation:NO];
    if(self)
    {
    }
    return self;
}

- (void)main
{
    UMLayerM2PA *link = (UMLayerM2PA *)self.receiver;
    [link _powerOffTask:self];
}


@end
