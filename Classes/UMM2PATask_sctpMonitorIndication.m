//
//  UMM2PATask_sctpMonitorIndication.m
//  ulibm2pa
//
//  Created by Andreas Fink on 05/12/14.
//  Copyright (c) 2016 Andreas Fink
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import "UMM2PATask_sctpMonitorIndication.h"
#import "UMLayerM2PA.h"

@implementation UMM2PATask_sctpMonitorIndication

@synthesize userId;
@synthesize streamId;
@synthesize protocolId;
@synthesize data;
@synthesize incoming;


- (UMM2PATask_sctpMonitorIndication *)initWithReceiver:(UMLayerM2PA *)rx
                                                sender:(id)tx
                                                userId:(id)uid
                                              streamId:(uint16_t)str
                                            protocolId:(uint32_t)prot
                                                  data:(NSData *)d
                                              incoming:(BOOL)in

{
    self = [super initWithName:[[self class]description]  receiver:rx sender:tx requiresSynchronisation:NO];
    if(self)
    {
        self.userId = uid;
        self.streamId = str;
        self.protocolId = prot;
        self.data = d;
        self.incoming = in;
    }
    return self;
}

- (void)main
{
    UMLayerM2PA *link = (UMLayerM2PA *)self.receiver;
    [link _sctpMonitorIndicationTask:self];
}

@end
