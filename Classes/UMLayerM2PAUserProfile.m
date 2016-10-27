//
//  UMLayerM2PAUserProfile.m
//  ulibm2pa
//
//  Created by Andreas Fink on 03.12.14.
//  Copyright (c) 2016 Andreas Fink
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import "UMLayerM2PAUserProfile.h"

@implementation UMLayerM2PAUserProfile

@synthesize allMessages;
@synthesize sctpLinkstateMessages;
@synthesize m2paLinkstateMessages;
@synthesize dataMessages;
@synthesize processorOutageMessages;

- (UMLayerM2PAUserProfile *)initWithDefaultProfile
{
    self = [super init];
    if(self)
    {
        allMessages = YES;
        sctpLinkstateMessages = YES;
        m2paLinkstateMessages = YES;
        dataMessages = YES;
        processorOutageMessages = YES;
    }
    return self;
}

- (BOOL) wantsDataMessages
{
    if((allMessages) || (dataMessages))
    {
        return YES;
    }
    return NO;
}

- (BOOL) wantsSctpLinkstateMessages
{
    if((allMessages) || (sctpLinkstateMessages))
    {
        return YES;
    }
    return NO;
}

- (BOOL) wantsM2PALinkstateMessages
{
    if((allMessages) || (m2paLinkstateMessages))
    {
        return YES;
    }
    return NO;
}

- (BOOL) wantsProcessorOutageMessages
{
    if((allMessages) || (processorOutageMessages))
    {
        return YES;
    }
    return NO;
}

@end
