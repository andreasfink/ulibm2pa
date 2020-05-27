//
//  UMM2PATask_sctpDataIndication.m
//  ulibm2pa
//
//  Created by Andreas Fink on 05/12/14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import "UMM2PATask_sctpDataIndication.h"
#import "UMLayerM2PA.h"

@implementation UMM2PATask_sctpDataIndication

@synthesize userId;
@synthesize streamId;
@synthesize protocolId;
@synthesize data;



- (UMM2PATask_sctpDataIndication *)initWithReceiver:(UMLayerM2PA *)rx
                                             sender:(id)tx
                                             userId:(id)uid
                                           streamId:(uint16_t)str
                                         protocolId:(uint32_t)prot
                                               data:(NSData *)d;
{
    self = [super initWithName:[[self class]description]  receiver:rx sender:tx requiresSynchronisation:NO];
    if(self)
    {
        self.streamId = str;
        self.protocolId = prot;
        self.userId = uid;
        self.data = d;
    }
    return self;
}

- (void)main
{
    @autoreleasepool
    {
        UMLayerM2PA *link = (UMLayerM2PA *)self.receiver;
        [link _sctpDataIndicationTask:self];
    }
}

@end
