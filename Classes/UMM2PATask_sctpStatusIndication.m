//
//  UMM2PATask_sctpStatusIndication.m
//  ulibm2pa
//
//  Created by Andreas Fink on 05/12/14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import "UMM2PATask_sctpStatusIndication.h"
#import "UMLayerM2PA.h"

@implementation UMM2PATask_sctpStatusIndication

@synthesize userId;
@synthesize status;

- (UMM2PATask_sctpStatusIndication *)initWithReceiver:(UMLayerM2PA *)rx
                                               sender:(id)tx
                                               userId:(id)uid
                                               status:(int)s;
{
    self = [super initWithName:[[self class]description]  receiver:rx sender:tx requiresSynchronisation:NO];
    if(self)
    {
        self.userId = uid;
        self.status = s;
    }
    return self;
}

- (void)main
{
    @autoreleasepool
    {
        UMLayerM2PA *link = (UMLayerM2PA *)self.receiver;
        [link _sctpStatusIndicationTask:self];
    }
}

@end
