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

static inline NSString *UMM2PAState_currentMethodName(const char *funcName);

static inline NSString *UMM2PAState_currentMethodName(const char *funcName)
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
    NSAssert(link!=NULL,@"link can not be NULL");
    self = [super init];
    if(self)
    {
        _link = link;
    }
    return self;
}

- (void) logStatemachineEvent:(const char *)func
{
    NSString *s;
    if((_link.logLevel <= UMLOG_DEBUG) || (_link.stateMachineLogFeed!=NULL))
    {
        /* func name is something like "[UMM2PAState eventNew]" */
        NSString *functionName  = UMM2PAState_currentMethodName(func);
        s = [NSString stringWithFormat:@"EVENT %@ in STATE %@",functionName,[self description]];
    }
    if(_link.logLevel <= UMLOG_DEBUG)
    {
        [_link logDebug:s];
    }
    if(_link.stateMachineLogFeed)
    {
        [_link.stateMachineLogFeed debugText:s];
    }
}

- (NSString *)description
{
    return @"undefined-state";
}

- (M2PA_Status)statusCode
{
    return M2PA_STATUS_DISCONNECTED;
}

#pragma mark -
#pragma mark eventHandlers

- (UMM2PAState *)eventPowerOn
{
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventPowerOff
{
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventStop
{
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventStart
{
    [self logStatemachineEvent:__func__];
    [_link.startTimer stop];
    [_link startupInitialisation];
    [self sendLinkstateOutOfService];
    [_link notifyMtp3OutOfService];
    if(_link.forcedOutOfService == NO)
    {
        [self sendLinkstateAlignment];
    }
    [_link.t2 start];
    return [[UMM2PAState_OutOfService alloc]initWithLink:_link];
}


- (UMM2PAState *)eventSctpUp
{
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventSctpDown
{
    [self logStatemachineEvent:__func__];
    [_link.startTimer stop];
    [_link notifyMtp3Stop];
    return [[UMM2PAState_Off alloc]initWithLink:_link];
}

- (UMM2PAState *)eventLinkstatusOutOfService
{
    [self logStatemachineEvent:__func__];
    [_link.startTimer stop];
    [_link startupInitialisation];
    [_link notifyMtp3OutOfService];
    [self sendLinkstateAlignment];
    if([_link.t2 isRunning]==NO)
    {
        [_link.t2 start];
    }
    return  [[UMM2PAState_InitialAlignment alloc]initWithLink:_link];
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
    _link.congested = YES;
    return self;
}

- (UMM2PAState *)eventLinkstatusBusyEnded
{
    [self logStatemachineEvent:__func__];
    _link.congested = NO;
    return self;
}


- (UMM2PAState *)eventLinkstatusProcessorOutage
{
    [self logStatemachineEvent:__func__];
    _link.remote_processor_outage = YES;
    return self;
}

- (UMM2PAState *)eventLinkstatusProcessorRecovered
{
    [self logStatemachineEvent:__func__];
    _link.remote_processor_outage = NO;
    return self;
}

- (UMM2PAState *)eventSctpError
{
    [self logStatemachineEvent:__func__];
    [_link.stateMachineLogFeed debugText:@"closing-sctp"];
    [_link.sctpLink closeFor:_link];
    return [[UMM2PAState_Off alloc]initWithLink:_link];
}


- (UMM2PAState *)eventSendUserData:(NSData *)data ackRequest:(NSDictionary *)ackRequest
{
    [_link sendData:data
             stream:M2PA_STREAM_USERDATA
         ackRequest:ackRequest];
    [_link.stateMachineLogFeed debugText:@"send-data"];
    return self;
}

- (UMM2PAState *)eventReceiveUserData:(NSData *)userData
{
    [self logStatemachineEvent:__func__];
    [_link notifyMtp3UserData:userData];
    [_link.stateMachineLogFeed debugText:@"receive-data"];
    return self;
}

- (UMM2PAState *)eventTimer1
{
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventTimer2
{
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventTimer3
{
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventTimer4
{
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventTimer4r
{
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventTimer5
{
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventTimer6
{
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventTimer7
{
    [self logStatemachineEvent:__func__];
    return self;
}

#pragma mark -
#pragma mark actionHelpers

- (void) sendLinkstateAlignment
{
    [_link sendLinkstatus:M2PA_LINKSTATE_ALIGNMENT];
    _link.linkstateAlignmentSent++;
    [_link.stateMachineLogFeed debugText:@"sendLinkstateAlignment"];
}

- (void) sendLinkstateProvingNormal
{
    if([self isKindOfClass:[UMM2PAState_OutOfService class]])
    {
        NSLog(@"wrong state");
    }
    [_link sendLinkstatus:M2PA_LINKSTATE_PROVING_NORMAL];
    _link.linkstateProvingSent++;
    [_link.stateMachineLogFeed debugText:@"sendLinkstateProvingNormal"];

}

- (void) sendLinkstateProvingEmergency
{
    [_link sendLinkstatus:M2PA_LINKSTATE_PROVING_EMERGENCY];
    _link.linkstateProvingSent++;
    [_link.stateMachineLogFeed debugText:@"sendLinkstateProvingEmergency"];
}

- (void) sendLinkstateReady
{
    [_link sendLinkstatus:M2PA_LINKSTATE_READY];
    _link.linkstateReadySent++;
    [_link.stateMachineLogFeed debugText:@"sendLinkstateReady"];

}

- (void) sendLinkstateProcessorOutage
{
    [_link sendLinkstatus:M2PA_LINKSTATE_PROCESSOR_OUTAGE];
    _link.linkstateProcessorOutageSent++;
    [_link.stateMachineLogFeed debugText:@"sendLinkstateProcessorOutage"];

}

- (void) sendLinkstateProcessorRecovered
{
    [_link sendLinkstatus:M2PA_LINKSTATE_PROCESSOR_RECOVERED];
    _link.linkstateProcessorRecoveredSent++;
    [_link.stateMachineLogFeed debugText:@"sendLinkstateProcessorRecovered"];

}

- (void) sendLinkstateBusy
{
    [_link sendLinkstatus:M2PA_LINKSTATE_BUSY];
    _link.linkstateBusySent++;
    [_link.stateMachineLogFeed debugText:@"sendLinkstateBusy"];

}

- (void) sendLinkstateBusyEnded
{
    [_link sendLinkstatus:M2PA_LINKSTATE_BUSY_ENDED];
    _link.linkstateBusyEndedSent++;
    [_link.stateMachineLogFeed debugText:@"sendLinkstateBusyEnded"];

}

- (void) sendLinkstateOutOfService
{
    if([self isKindOfClass:[UMM2PAState_InitialAlignment class]])
    {
        NSLog(@"wrong state");
    }
   else  if([self isKindOfClass:[UMM2PAState_AlignedReady class]])
    {
        NSLog(@"wrong state");
    }

    [_link sendLinkstatus:M2PA_LINKSTATE_OUT_OF_SERVICE];
    _link.linkstateOutOfServiceSent++;
    [_link.stateMachineLogFeed debugText:@"sendLinkstateOutOfService"];

}

@end
