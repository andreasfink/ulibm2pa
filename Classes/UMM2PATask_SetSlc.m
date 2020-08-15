//
//  UMM2PATask_SetSlc.m
//  ulibm2pa
//
//  Created by Andreas Fink on 02.12.14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import "UMM2PATask_SetSlc.h"
#import "UMLayerM2PA.h"

@implementation UMM2PATask_SetSlc

@synthesize slc;


- (UMM2PATask_SetSlc *)initWithReceiver:(UMLayerM2PA *)rx
                                 sender:(id<UMLayerM2PAUserProtocol>)tx
                                    slc:(int)xslc
{
    self = [super initWithName:[[self class]description]  receiver:rx sender:tx requiresSynchronisation:NO];
    if(self)
    {
        self.slc = xslc;
    }
    return self;
}

- (void)main
{
    @autoreleasepool
    {
        UMLayerM2PA *link = (UMLayerM2PA *)self.receiver;
        [link _setSlcTask:self];
    }
}

@end
