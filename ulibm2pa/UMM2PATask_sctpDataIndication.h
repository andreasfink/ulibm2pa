//
//  UMM2PATask_sctpDataIndication.h
//  ulibm2pa
//
//  Created by Andreas Fink on 05/12/14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import <ulib/ulib.h>
#import <ulibsctp/ulibsctp.h>
@class UMLayerM2PA;

@interface UMM2PATask_sctpDataIndication : UMLayerTask
{
    id          _userId;
    uint16_t    _streamId;
    uint32_t    _protocolId;
    NSData      *_data;
    NSNumber    *_socketNumber;
}

@property(readwrite,strong) id          userId;
@property(readwrite,assign) uint16_t    streamId;
@property(readwrite,assign) uint32_t    protocolId;
@property(readwrite,strong) NSData *    data;
@property(readwrite,strong) NSNumber *  socketNumber;

- (UMM2PATask_sctpDataIndication *)initWithReceiver:(UMLayerM2PA *)rx
                                             sender:(id)tx
                                             userId:(id)uid
                                           streamId:(uint16_t)str
                                         protocolId:(uint32_t)prot
                                               data:(NSData *)d
                                             socket:(NSNumber*)socketNumber;
- (void)main;

@end
