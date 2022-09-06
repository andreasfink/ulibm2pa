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


- (UMM2PAState *)initWithLink:(UMLayerM2PA *)link status:(M2PA_Status)statusCode
{
    _statusCode = statusCode;
    NSAssert(link!=NULL,@"link can not be NULL");
    self = [super init];
    if(self)
    {
        if(link==NULL)
        {
            NSString *backtrace = UMBacktrace(NULL,0);
            NSString *s = [NSString stringWithFormat:@"passing NULL to initWithLink:\nbacktrace:%@",backtrace];
            @throw([NSException exceptionWithName:@"WRONG_INITIALISATION" reason:s userInfo:NULL]);
        }
        if (![link isKindOfClass:[UMLayerM2PA class]])
        {
            NSString *backtrace = UMBacktrace(NULL,0);
            NSString *s = [NSString stringWithFormat:@"passing wrong object of type %@ to initWithLink:\nbacktrace:%@",
                           link!=NULL ? @(object_getClassName(link)): @"NULL",backtrace];
            @throw([NSException exceptionWithName:@"WRONG_INITIALISATION" reason:s userInfo:NULL]);
        }
        _link = link;
        _statusCode = statusCode;
        [_link notifyMtp3:_statusCode async:YES];
    }
    return self;
}

- (void) logStatemachineEvent:(const char *)func
{
    [self logStatemachineEvent:func forced:NO];
}

- (void) logStatemachineEvent:(const char *)func forced:(BOOL)forced
{
    NSString *s=NULL;
    if((_link.logLevel <= UMLOG_DEBUG) || (_link.stateMachineLogFeed!=NULL) || (forced) || (_link.layerHistory))
    {
        /* func name is something like "[UMM2PAState eventNew]" */
        NSString *functionName  = UMM2PAState_currentMethodName(func);
        s = [NSString stringWithFormat:@"EVENT %@ in STATE %@",functionName,[self description]];
    }
    if((_link.logLevel <= UMLOG_DEBUG) && (s))
    {
        [_link logDebug:s];
    }
    if((forced) && (s))
    {
        [_link logWarning:s];
    }
    if((_link.stateMachineLogFeed) && (s))
    {
        [_link.stateMachineLogFeed debugText:s];
    }
    [_link addToLayerHistoryLog:s];
}

- (void) logStatemachineEventString:(NSString *)str
{
    return [self logStatemachineEventString:str forced:NO];
}

- (void) logStatemachineEventString:(NSString *)str forced:(BOOL)forced
{
    NSString *s=NULL;
    if((_link.logLevel <= UMLOG_DEBUG) || (_link.stateMachineLogFeed!=NULL) || (forced))
    {
        s = [NSString stringWithFormat:@"EVENT %@ in STATE %@",str,[self description]];
    }
    if((_link.logLevel <= UMLOG_DEBUG) && (s))
    {
        [_link logDebug:s];
    }
    if((forced) && (s))
    {
        [_link logWarning:s];
    }
    if((_link.stateMachineLogFeed) && (s))
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
    [self logStatemachineEvent:__func__];
    [_link.sctpLink closeFor:_link reason:@"eventPowerOff"];
    [_link notifyMtp3Off];
    return [[UMM2PAState_Off alloc]initWithLink:_link status:M2PA_STATUS_OFF];
}

- (UMM2PAState *)eventStop
{
    [self logStatemachineEvent:__func__];
    [_link.startTimer stop];
    [_link startupInitialisation];
    [_link notifyMtp3OutOfService];
    return  [[UMM2PAState_OutOfService alloc]initWithLink:_link status:M2PA_STATUS_OOS];
}

- (UMM2PAState *)eventStart
{
    [self logStatemachineEvent:__func__];
    [_link.startTimer stop];
    [_link startupInitialisation];
    [_link.t2 start];
    return [[UMM2PAState_OutOfService alloc]initWithLink:_link status:M2PA_STATUS_OOS];
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
    [_link startupInitialisation];
    [_link notifyMtp3Stop];
    return [[UMM2PAState_Off alloc]initWithLink:_link status:M2PA_STATUS_OFF];
}

- (UMM2PAState *)eventLinkstatusOutOfService
{
    [self logStatemachineEvent:__func__];
    [_link.startTimer stop];
    [_link startupInitialisation];
    [_link notifyMtp3OutOfService];
    return  [[UMM2PAState_OutOfService alloc]initWithLink:_link status:M2PA_STATUS_OOS];
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

- (UMM2PAState *) eventLocalProcessorOutage
{
    [self logStatemachineEvent:__func__ forced:YES];
    [_link sendLinkstatus:M2PA_LINKSTATE_PROCESSOR_OUTAGE synchronous:YES];
    _link.linkstateProcessorOutageSent++;
    [self logStatemachineEventString:@"sendProcessorOutage"];
    [_link addToLayerHistoryLog:@"sendProcessorOutage"];
    return self;
}


- (UMM2PAState *)eventLinkstatusAlignment
{
    [self logStatemachineEvent:__func__];
    if(_link.forcedOutOfService==YES)
    {
        return [[UMM2PAState_OutOfService alloc]initWithLink:_link status:M2PA_STATUS_OOS];
    }
    return [[UMM2PAState_NotAligned alloc]initWithLink:_link status:M2PA_STATUS_NOT_ALIGNED];
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
    return  [[UMM2PAState_InService alloc]initWithLink:_link status:M2PA_STATUS_IS];
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
    [self logStatemachineEventString:@"closing-sctp"];
    [_link.sctpLink closeFor:_link reason:@"eventSctpError"];
    return [[UMM2PAState_Off alloc]initWithLink:_link status:M2PA_STATUS_OFF];
}


- (UMM2PAState *)eventSendUserData:(NSData *)data
                        ackRequest:(NSDictionary *)ackRequest
                               dpc:(int)dpc
{
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventReceiveUserData:(NSData *)userData
{
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventTimer1
{
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventTimer1r
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
    [self logStatemachineEventString:@"sendLinkstateAlignment"];
    [_link addToLayerHistoryLog:@"sendLinkstateAlignment"];

}

- (void) sendLinkstateProvingNormal:(BOOL)sync
{
    if(   (_statusCode != M2PA_STATUS_OOS)
       && (_statusCode != M2PA_STATUS_NOT_ALIGNED)
       && (_statusCode != M2PA_STATUS_ALIGNED_NOT_READY))
    {
        [_link logWarning:@"trying to sendLinkstateProvingNormal not in INITIAL ALIGNMENT or ALIGNED_NOT_READY state. Ignored"];
        [_link addToLayerHistoryLog:@"trying to sendLinkstateProvingNormal not in INITIAL ALIGNMENT or ALIGNED_NOT_READY or OOS state. Ignored"];

    }
    else
    {
        [_link sendLinkstatus:M2PA_LINKSTATE_PROVING_NORMAL synchronous:sync];
        _link.linkstateProvingSent++;
        [self logStatemachineEventString:@"sendLinkstateProvingNormal"];
        [_link addToLayerHistoryLog:@"sendLinkstateProvingNormal"];
    }
}

- (void) sendLinkstateProvingEmergency:(BOOL)sync
{
    if(   (_statusCode != M2PA_STATUS_OOS)
       && (_statusCode != M2PA_STATUS_NOT_ALIGNED)
       && (_statusCode != M2PA_STATUS_ALIGNED_NOT_READY))
    {
        [_link logWarning:@"trying to sendLinkstateProvingEmergency not in INITIAL ALIGNMENT or ALIGNED_NOT_READY or OOS state. Ignored"];
        [_link addToLayerHistoryLog:@"trying to sendLinkstateProvingEmergency not in INITIAL ALIGNMENT or ALIGNED_NOT_READY or OOS state. Ignored"];
    }
    else
    {
        [_link sendLinkstatus:M2PA_LINKSTATE_PROVING_EMERGENCY synchronous:sync];
        _link.linkstateProvingSent++;
        [self logStatemachineEventString:@"sendLinkstateProvingEmergency"];
        [_link addToLayerHistoryLog:@"sendLinkstateProvingEmergency"];

    }
}

- (void) sendLinkstateReady:(BOOL)sync
{
    [_link sendLinkstatus:M2PA_LINKSTATE_READY synchronous:sync];
    _link.linkstateReadySent++;
    [self logStatemachineEventString:@"sendLinkstateReady"];
    [_link addToLayerHistoryLog:@"sendLinkstateReady"];

}


- (void) sendLinkstateProcessorOutage:(BOOL)sync
{
    [_link sendLinkstatus:M2PA_LINKSTATE_PROCESSOR_OUTAGE synchronous:sync];
    _link.linkstateProcessorOutageSent++;
    [self logStatemachineEventString:@"sendLinkstateProcessorOutage"];
    [_link addToLayerHistoryLog:@"sendLinkstateProcessorOutage"];

}

- (void) sendLinkstateProcessorRecovered:(BOOL)sync
{
    [_link sendLinkstatus:M2PA_LINKSTATE_PROCESSOR_RECOVERED synchronous:sync];
    _link.linkstateProcessorRecoveredSent++;
    [self logStatemachineEventString:@"sendLinkstateProcessorRecovered"];
    [_link addToLayerHistoryLog:@"sendLinkstateProcessorRecovered"];

}

- (void) sendLinkstateBusy:(BOOL)sync
{
    [_link sendLinkstatus:M2PA_LINKSTATE_BUSY synchronous:sync];
    _link.linkstateBusySent++;
    [self logStatemachineEventString:@"sendLinkstateBusy"];
    [_link addToLayerHistoryLog:@"sendLinkstateBusy"];

}

- (void) sendLinkstateBusyEnded:(BOOL)sync
{
    [_link sendLinkstatus:M2PA_LINKSTATE_BUSY_ENDED synchronous:sync];
    _link.linkstateBusyEndedSent++;
    [self logStatemachineEventString:@"sendLinkstateBusyEnded"];
    [_link addToLayerHistoryLog:@"sendLinkstateBusyEnded"];

}

- (void) sendLinkstateOutOfService:(BOOL)sync
{
    [self logStatemachineEvent:__func__ forced:YES];
    [_link sendLinkstatus:M2PA_LINKSTATE_OUT_OF_SERVICE synchronous:sync];
    _link.linkstateOutOfServiceSent++;
    [self logStatemachineEventString:@"sendLinkstateOutOfService"];
    [_link addToLayerHistoryLog:@"sendLinkstateOutOfService"];
}



@end
