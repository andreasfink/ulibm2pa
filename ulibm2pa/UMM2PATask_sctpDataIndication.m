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

- (UMM2PATask_sctpDataIndication *)initWithReceiver:(UMLayerM2PA *)rx
                                             sender:(id)tx
                                             userId:(id)uid
                                           streamId:(uint16_t)str
                                         protocolId:(uint32_t)prot
                                               data:(NSData *)d
                                             socket:(NSNumber *)socketNumber;
{
    self = [super initWithName:[[self class]description]  receiver:rx sender:tx requiresSynchronisation:NO];
    if(self)
    {
        _streamId = str;
        _protocolId = prot;
        _userId = uid;
        _data = d;
        _socketNumber = socketNumber;
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
