//
//  UMM2PATask_AdminAttach.m
//  ulibm2pa
//
//  Created by Andreas Fink on 01.12.14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import "UMM2PATask_AdminAttach.h"
#import "UMLayerM2PA.h"
#import "UMLayerM2PAUserProfile.h"

@implementation UMM2PATask_AdminAttach

- (UMM2PATask_AdminAttach *)initWithReceiver:(UMLayerM2PA *)rx
									  sender:(id<UMLayerM2PAUserProtocol>)tx
									 profile:(UMLayerM2PAUserProfile *)p
										 slc:(int)xslc
									linkName:(NSString *)xlinkName
{
    self = [super initWithName:[[self class]description]  receiver:rx sender:tx requiresSynchronisation:NO];
    if(self)
    {
        if(p==NULL)
        {
            p = [[UMLayerM2PAUserProfile alloc]initWithDefaultProfile];
        }
        self.profile = p;
        self.slc = xslc;
		self.linkName = xlinkName;
    }
    return self;
}

- (void)main
{
    UMLayerM2PA *link = (UMLayerM2PA *)self.receiver;
    [link _adminAttachTask:self];
}

@end
