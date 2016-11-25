//
//  UMM2PATask_AdminSetConfig.m
//  ulibm2pa
//
//  Created by Andreas Fink on 01.12.14.
//  Copyright (c) 2016 Andreas Fink
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import "UMM2PATask_AdminSetConfig.h"
#import "UMLayerM2PA.h"

@implementation UMM2PATask_AdminSetConfig

@synthesize config;

- (UMM2PATask_AdminSetConfig *)initWithReceiver:(UMLayer *)rx
                                         sender:(id<UMLayerM2PAUserProtocol>)tx
                                         config:(NSDictionary *)cfg
{
    self = [super initWithName:[[self class]description]  receiver:rx sender:tx requiresSynchronisation:NO];
    if(self)
    {
        self.config = cfg;
    }
    return self;
}

- (void)main
{
    UMLayerM2PA *link = (UMLayerM2PA *)self.receiver;
    [link _adminSetConfigTask:self];
}

@end
