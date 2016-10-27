//
//  UMM2PATask_sctpStatusIndication.h
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

@interface UMM2PATask_sctpStatusIndication : UMLayerTask
{
    id userId;
    SCTP_Status status;
}

@property(readwrite,strong) id userId;
@property(readwrite,assign) SCTP_Status status;

- (UMM2PATask_sctpStatusIndication *)initWithReceiver:(UMLayerM2PA *)rx
                                               sender:(id)tx
                                               userId:(id)uid
                                               status:(int)s;
- (void)main;

@end

