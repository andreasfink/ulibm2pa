//
//  UMM2PAState.m
//  ulibm2pa
//
//  Created by Andreas Fink on 17.03.20.
//  Copyright © 2020 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMM2PAState.h"
#import "UMLayerM2PA.h"
#import "UMM2PAState_allStates.h"

NSString *UMM2PAState_currentMethodName(const char *funcName)
{
    /* func name is something like "[UMM2PAState eventNew]" */

    NSString *func = @(funcName);
    func = [func stringByTrimmingCharactersInSet:[UMObject bracketsAndWhitespaceCharacterSet]];
    NSArray *a = [func componentsSeparatedByCharactersInSet:[UMObject whitespaceAndNewlineCharacterSet]];
    if(a.count == 1)
    {
        return a[0];
    }
    if(a.count > 1)
    {
        return a[1];
    }
    return func;
}



@implementation UMM2PAState

- (UMM2PAState *)init
{
    @throw([NSException exceptionWithName:@"API_ERROR"
                                   reason:@"dont call init. Call initWithLink"
                                 userInfo:@{    @"backtrace":   UMBacktrace(NULL,0) }]);
}

- (UMM2PAState *)initWithLink:(UMLayerM2PA *)link
{
    self = [super init];
    if(self)
    {
        _link = link;
    }
    return self;
}

-(void) logStatemachineEvent:(const char *)func
{
    if(_link.logLevel <= UMLOG_DEBUG)
    {
        NSString *s = [NSString stringWithFormat:@"EVENT %@ in STATE %@",
                        UMM2PAState_currentMethodName(func),
                        [self description]];
        [_link logDebug:s];
    }
}

- (NSString *)description
{
    return @"undefined-state";
}


- (UMM2PAState *)eventStop
{
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventStart
{
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventSctpUp
{
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventSctpDown
{
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventLinkstatusOutOfService
{
    [self logStatemachineEvent:__func__];
    return self;
}


- (UMM2PAState *)eventEmergency
{
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventEmergencyCeases
{
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventLinkstatusAlignment
{
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventLinkstatusProvingNormal
{
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventLinkstatusProvingEmergency
{
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventLinkstatusReady
{
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventLinkstatusBusy
{
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventLinkstatusBusyEnded
{
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventLinkstatusProcessorOutage
{
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventLinkstatusProcessorRecovered
{
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventSctpError
{
    [self logStatemachineEvent:__func__];
    _link.state = [[UMM2PAState_OutOfService alloc]initWithLink:_link];
    return _link.state;
}

- (void) sendLinkstateAlignment
{
    [_link sendLinkstatus:M2PA_LINKSTATE_ALIGNMENT];
}

- (void) sendLinkstateProvingNormal
{
    [_link sendLinkstatus:M2PA_LINKSTATE_PROVING_NORMAL];
}

- (void) sendLinkstateProvingEmergency
{
    [_link sendLinkstatus:M2PA_LINKSTATE_PROVING_EMERGENCY];
}

- (void) sendLinkstateReady
{
    [_link sendLinkstatus:M2PA_LINKSTATE_READY];
}

- (void) sendLinkstateProcessorOutage
{
    [_link sendLinkstatus:M2PA_LINKSTATE_PROCESSOR_OUTAGE];
}

- (void) sendLinkstateProcessorRecovered
{
    [_link sendLinkstatus:M2PA_LINKSTATE_PROCESSOR_RECOVERED];
}

- (void) sendLinkstateBusy
{
    [_link sendLinkstatus:M2PA_LINKSTATE_BUSY];
}

- (void) sendLinkstateBusyEnded
{
    [_link sendLinkstatus:M2PA_LINKSTATE_BUSY_ENDED];
}

- (void) sendLinkstateOutOfService
{
    [_link sendLinkstatus:M2PA_LINKSTATE_OUT_OF_SERVICE];
}

@end
