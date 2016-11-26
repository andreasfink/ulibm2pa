//
//  UMM2PATask_sctpDataIndication.h
//  ulibm2pa
//
//  Created by Andreas Fink on 05/12/14.
//  Copyright (c) 2016 Andreas Fink
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import <ulib/ulib.h>
#import <ulibsctp/ulibsctp.h>
@class UMLayerM2PA;

@interface UMM2PATask_sctpDataIndication : UMLayerTask
{
    id          userId;
    uint16_t    streamId;
    uint32_t    protocolId;
    NSData      *data;
    
}

@property(readwrite,strong) id          userId;
@property(readwrite,assign) uint16_t    streamId;
@property(readwrite,assign) uint32_t    protocolId;
@property(readwrite,strong) NSData *    data;

- (UMM2PATask_sctpDataIndication *)initWithReceiver:(UMLayerM2PA *)rx
                                             sender:(id)tx
                                             userId:(id)uid
                                           streamId:(uint16_t)str
                                         protocolId:(uint32_t)prot
                                               data:(NSData *)d;
- (void)main;

@end
