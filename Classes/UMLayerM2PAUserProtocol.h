//
//  UMLayerM2PAUserProtocol.h
//  ulibm2pa
//
//  Created by Andreas Fink on 01.12.14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import <ulib/ulib.h>
#import <ulibsctp/ulibsctp.h>
#import "UMLayerM2PAStatus.h"

@protocol UMLayerM2PAUserProtocol<UMLayerUserProtocol>

- (NSString *)layerName;

- (void) adminAttachConfirm:(UMLayer *)attachedLayer
                        slc:(int)slc
                     userId:(id)uid;

- (void) adminAttachFail:(UMLayer *)attachedLayer
                     slc:(int)slc
                  userId:(id)uid
                  reason:(NSString *)reason;

- (void) sentAckConfirmFrom:(UMLayer *)sender
                   userInfo:(NSDictionary *)userInfo;

- (void) sentAckFailureFrom:(UMLayer *)sender
                   userInfo:(NSDictionary *)userInfo
                      error:(NSString *)err
                     reason:(NSString *)reason
                  errorInfo:(NSDictionary *)ei;

- (void) m2paStatusIndication:(UMLayer *)caller
                          slc:(int)xslc
                       userId:(id)uid
                       status:(M2PA_Status)s;

- (void) m2paSctpStatusIndication:(UMLayer *)caller
                              slc:(int)xslc
                           userId:(id)uid
                           status:(UMSocketStatus)s;

- (void) m2paDataIndication:(UMLayer *)caller
						slc:(int)xslc
			   mtp3linkName:(NSString *)linkName
					   data:(NSData *)d;

- (void) m2paCongestion:(UMLayer *)caller
                    slc:(int)xslc
                 userId:(id)ui;

- (void) m2paCongestionCleared:(UMLayer *)caller
                           slc:(int)xslc
                        userId:(id)uid;

- (void) m2paProcessorOutage:(UMLayer *)caller
                         slc:(int)xslc
                      userId:(id)uid;

- (void) m2paProcessorRestored:(UMLayer *)caller
                           slc:(int)xslc
                        userId:(id)uid;

- (void) m2paSpeedLimitReached:(UMLayer *)caller
                           slc:(int)xslc
                        userId:(id)uidd;

- (void) m2paSpeedLimitReachedCleared:(UMLayer *)caller
                                  slc:(int)xslc
                               userId:(id)uid;


@end
