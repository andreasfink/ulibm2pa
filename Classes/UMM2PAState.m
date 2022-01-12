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
    return [self initWithLink:link notify:NO];
}

- (UMM2PAState *)initWithLink:(UMLayerM2PA *)link notify:(BOOL)notify
{
    NSAssert(link!=NULL,@"link can not be NULL");
    self = [super init];
    if(self)
    {
        _link = link;
        _statusCode = M2PA_STATUS_DISCONNECTED;
        if(notify)
        {
            [_link notifyMtp3:_statusCode async:YES];
        }
    }
    return self;
}

- (void) logStatemachineEvent:(const char *)func
{
    [self logStatemachineEvent:func forced:NO];
}

- (void) logStatemachineEvent:(const char *)func forced:(BOOL)forced
{
    NSString *s;
    if((_link.logLevel <= UMLOG_DEBUG) || (_link.stateMachineLogFeed!=NULL) || (forced))
    {
        /* func name is something like "[UMM2PAState eventNew]" */
        NSString *functionName  = UMM2PAState_currentMethodName(func);
        s = [NSString stringWithFormat:@"EVENT %@ in STATE %@",functionName,[self description]];
    }
    if(_link.logLevel <= UMLOG_DEBUG)
    {
        [_link logDebug:s];
    }
    if(forced)
    {
        [_link logWarning:s];
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
    [self sendLinkstateOutOfService:YES];
    if(_link.forcedOutOfService == NO)
    {
        [self sendLinkstateAlignment:YES];
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
    if(_link.forcedOutOfService == NO)
    {
        [self sendLinkstateAlignment:YES];
    }
    else
    {
        [self sendLinkstateOutOfService:YES];
    }
    [_link.t2 start];
    return  [[UMM2PAState_OutOfService alloc]initWithLink:_link];
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
    if(_link.forcedOutOfService==YES)
    {
        return [[UMM2PAState_OutOfService alloc]initWithLink:_link];
    }
    return [[UMM2PAState_InitialAlignment alloc]initWithLink:_link];
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
    [_link.t1 stop];
    [_link.t2 stop];
    [_link.t4r stop];
    [_link.t4 stop];
    [_link notifyMtp3InService];
    return  [[UMM2PAState_InService alloc]initWithLink:_link];;
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


- (UMM2PAState *)eventSendUserData:(NSData *)data
                        ackRequest:(NSDictionary *)ackRequest
                               dpc:(int)dpc
{
    [_link sendData:data
             stream:M2PA_STREAM_USERDATA
         ackRequest:ackRequest
                dpc:dpc];
    //[_link.stateMachineLogFeed debugText:@"send-data"];
    return self;
}

- (UMM2PAState *)eventReceiveUserData:(NSData *)userData
{
    [self logStatemachineEvent:__func__];
    [_link notifyMtp3UserData:userData];
    //[_link.stateMachineLogFeed debugText:@"receive-data"];
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

- (void) sendLinkstateAlignment:(BOOL)sync
{
    [_link sendLinkstatus:M2PA_LINKSTATE_ALIGNMENT synchronous:sync];
    _link.linkstateAlignmentSent++;
    [_link.stateMachineLogFeed debugText:@"sendLinkstateAlignment"];
}

- (void) sendLinkstateProvingNormal:(BOOL)sync
{
    if(   (_statusCode != M2PA_STATUS_OOS)
       && (_statusCode != M2PA_STATUS_INITIAL_ALIGNMENT)
       && (_statusCode != M2PA_STATUS_ALIGNED_NOT_READY))
    {
        [_link logWarning:@"trying to sendLinkstateProvingNormal not in INITIAL ALIGNMENT or ALIGNED_NOT_READY state. Ignored"];
    }
    else
    {
        [_link sendLinkstatus:M2PA_LINKSTATE_PROVING_NORMAL synchronous:sync];
        _link.linkstateProvingSent++;
        [_link.stateMachineLogFeed debugText:@"sendLinkstateProvingNormal"];
    }
}

- (void) sendLinkstateProvingEmergency:(BOOL)sync
{
    if(   (_statusCode != M2PA_STATUS_OOS)
       && (_statusCode != M2PA_STATUS_INITIAL_ALIGNMENT)
       && (_statusCode != M2PA_STATUS_ALIGNED_NOT_READY))
    {
        [_link logWarning:@"trying to sendLinkstateProvingEmergency not in INITIAL ALIGNMENT or ALIGNED_NOT_READY or OOS state. Ignored"];
    }
    else
    {
        [_link sendLinkstatus:M2PA_LINKSTATE_PROVING_EMERGENCY synchronous:sync];
        _link.linkstateProvingSent++;
        [_link.stateMachineLogFeed debugText:@"sendLinkstateProvingEmergency"];
    }
}

- (void) sendLinkstateReady:(BOOL)sync
{
    [_link sendLinkstatus:M2PA_LINKSTATE_READY synchronous:sync];
    _link.linkstateReadySent++;
    [_link.stateMachineLogFeed debugText:@"sendLinkstateReady"];

}


- (void) sendLinkstateProcessorOutage:(BOOL)sync
{
    [_link sendLinkstatus:M2PA_LINKSTATE_PROCESSOR_OUTAGE synchronous:sync];
    _link.linkstateProcessorOutageSent++;
    [_link.stateMachineLogFeed debugText:@"sendLinkstateProcessorOutage"];

}

- (void) sendLinkstateProcessorRecovered:(BOOL)sync
{
    [_link sendLinkstatus:M2PA_LINKSTATE_PROCESSOR_RECOVERED synchronous:sync];
    _link.linkstateProcessorRecoveredSent++;
    [_link.stateMachineLogFeed debugText:@"sendLinkstateProcessorRecovered"];

}

- (void) sendLinkstateBusy:(BOOL)sync
{
    [_link sendLinkstatus:M2PA_LINKSTATE_BUSY synchronous:sync];
    _link.linkstateBusySent++;
    [_link.stateMachineLogFeed debugText:@"sendLinkstateBusy"];

}

- (void) sendLinkstateBusyEnded:(BOOL)sync
{
    [_link sendLinkstatus:M2PA_LINKSTATE_BUSY_ENDED synchronous:sync];
    _link.linkstateBusyEndedSent++;
    [_link.stateMachineLogFeed debugText:@"sendLinkstateBusyEnded"];

}

- (void) sendLinkstateOutOfService:(BOOL)sync
{
    [self logStatemachineEvent:__func__ forced:YES];
    [_link sendLinkstatus:M2PA_LINKSTATE_OUT_OF_SERVICE synchronous:sync];
    _link.linkstateOutOfServiceSent++;
    [_link.stateMachineLogFeed debugText:@"sendLinkstateOutOfService"];
}

@end
