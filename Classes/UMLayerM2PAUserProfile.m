//
//  UMLayerM2PAUserProfile.m
//  ulibm2pa
//
//  Created by Andreas Fink on 03.12.14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import "UMLayerM2PAUserProfile.h"

@implementation UMLayerM2PAUserProfile


- (UMLayerM2PAUserProfile *)initWithDefaultProfile
{
    self = [super init];
    if(self)
    {
        _allMessages = YES;
        _sctpLinkstateMessages = YES;
        _m2paLinkstateMessages = YES;
        _dataMessages = YES;
        _processorOutageMessages = YES;
        _owner = YES;
    }
    return self;
}

- (BOOL) wantsDataMessages
{
    if((_allMessages) || (_dataMessages))
    {
        return YES;
    }
    return NO;
}

- (BOOL) wantsSctpLinkstateMessages
{
    if((_allMessages) || (_sctpLinkstateMessages))
    {
        return YES;
    }
    return NO;
}

- (BOOL) wantsM2PALinkstateMessages
{
    if((_allMessages) || (_m2paLinkstateMessages))
    {
        return YES;
    }
    return NO;
}

- (BOOL) wantsProcessorOutageMessages
{
    if((_allMessages) || (_processorOutageMessages))
    {
        return YES;
    }
    return NO;
}

@end
