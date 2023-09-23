//
//  UMLayerM2PAUser.h
//  ulibm2pa
//
//  Created by Andreas Fink on 02.12.14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import <ulib/ulib.h>
#import <ulibm2pa/UMLayerM2PAUserProtocol.h>

@class UMLayerM2PAUserProfile;

@interface UMLayerM2PAUser : UMObject
{
    id<UMLayerM2PAUserProtocol>	_user;
    UMLayerM2PAUserProfile  	*_profile;
    NSString					*_linkName;
}

@property(readwrite,strong)	id<UMLayerM2PAUserProtocol> user;
@property(readwrite,strong) UMLayerM2PAUserProfile *profile;
@property(readwrite,strong) id linkName;

@end
