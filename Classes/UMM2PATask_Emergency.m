//
//  UMM2PATask_Emergency.m
//  ulibm2pa
//
//  Created by Andreas Fink on 02.12.14.
//  Copyright (c) 2016 Andreas Fink
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import "UMM2PATask_Emergency.h"
#import "UMLayerM2PA.h"

@implementation UMM2PATask_Emergency

- (UMM2PATask_Emergency *)initWithReceiver:(UMLayerM2PA *)rx
                                           sender:(id<UMLayerM2PAUserProtocol>)tx
{
    self = [super initWithName:[[self class]description]  receiver:rx sender:tx requiresSynchronisation:YES];
    if(self)
    {
    }
    return self;
}

- (void)main
{
    UMLayerM2PA *link = (UMLayerM2PA *)self.receiver;
    [link _emergencyTask:self];
}
@end
