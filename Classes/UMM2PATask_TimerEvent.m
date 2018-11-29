//
//  UMM2PATask_TimerEvent.m
//  ulibm2pa
//
//  Created by Andreas Fink on 02/12/14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import "UMM2PATask_TimerEvent.h"
#import "UMLayerM2PA.h"

@implementation UMM2PATask_TimerEvent

- (UMM2PATask_TimerEvent *)initWithReceiver:(UMLayerM2PA *)rx sender:(id<UMLayerM2PAUserProtocol>)tx timerName:(NSString *)tname;
{
    self = [super initWithName:[[self class]description]  receiver:rx sender:tx requiresSynchronisation:NO];
    if(self)
    {
        _timerName = tname;
    }
    return self;
}

- (void)main
{
	UMLayerM2PA *link = (UMLayerM2PA *)self.receiver;

	if(link.logLevel <= UMLOG_DEBUG)
	{
		[link.logFeed debugText:[NSString stringWithFormat:@"Timer %@ fires",_timerName]];
	}
    [link _timerEventTask:self];
}

@end
