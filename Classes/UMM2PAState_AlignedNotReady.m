//
//  UMM2PAState_AlignedNotReady.m
//  ulibm2pa
//
//  Created by Andreas Fink on 17.03.20.
//  Copyright © 2020 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMM2PAState_AlignedNotReady.h"
#import "UMM2PAState_allStates.h"
#import "UMLayerM2PA.h"

@implementation UMM2PAState_AlignedNotReady

- (UMM2PAState *)initWithLink:(UMLayerM2PA *)link status:(M2PA_Status)statusCode
{
    self =[super initWithLink:link status:statusCode];
    {
        _link.linkstateProvingSent = 0;
        _statusCode = M2PA_STATUS_ALIGNED_NOT_READY;
        [_link.t2 stop];
        [_link.t4 stop];
        _t4_expired = NO;
        double t = _link.t4r;
        M2TIMER_VALIDATE(t,M2PA_DEFAULT_T4_R,M2PA_DEFAULT_T4_R_MIN,M2PA_DEFAULT_T4_R_MAX);
        _link.t4r = t;
        if(_link.emergency)
        {
            t = _link.t4e;
            M2TIMER_VALIDATE(t,M2PA_DEFAULT_T4_E,M2PA_DEFAULT_T4_E_MIN,M2PA_DEFAULT_T4_E_MAX);
            _link.t4e = t;
            _link.t4.seconds = t;  /* ending of proving period timer */
            [self sendLinkstateProvingEmergency:YES];
        }
        else
        {
            t = _link.t4n;
            M2TIMER_VALIDATE(t,M2PA_DEFAULT_T4_N,M2PA_DEFAULT_T4_N_MIN,M2PA_DEFAULT_T4_N_MAX);
            _link.t4n = t;
            _link.t4.seconds = t;   /* ending of proving period timer */
            [self sendLinkstateProvingNormal:YES];
        }
        [_link.t4 start];
        _link.repeatTimer.seconds = _link.t4r;
        [_link.repeatTimer start]; /* sending out status timer */
        [_link.t3 start];
    }
    return self;
}

- (NSString *)description
{
    return @"aligned-not-ready";
}

#pragma mark -
#pragma mark event handlers

- (UMM2PAState *)eventPowerOn   /* switch on the wire */
{
    [self logStatemachineEvent:__func__];
    [_link addToLayerHistoryLog:@"poweron in aligned not-ready ignored"];
    return self;
}

- (UMM2PAState *)eventPowerOff  /* switch off the wire */
{
    [self logStatemachineEvent:__func__];
    [_link addToLayerHistoryLog:@"poweroff in aligned not-ready ignored"];
    return self;
}

- (UMM2PAState *)eventStart     /* start the alignment process */
{
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventStop      /* stop the link */
{
    [self logStatemachineEvent:__func__];
    [self sendLinkstateOutOfService:YES];
    return [[UMM2PAState_OutOfService alloc]initWithLink:_link status:M2PA_STATUS_OOS];
}

- (UMM2PAState *)eventSctpUp    /* SCTP reports the 'wire' has come up*/
{
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventSctpDown   /* SCTP reports the conncetion is lost */
{
    return [super eventSctpDown];
}

- (UMM2PAState *)eventEmergency             /* MTP3 tells his is an emergency link */
{
    [self logStatemachineEvent:__func__];
    if(_link.emergency==NO)
    {
        _link.t4.seconds = _link.t4e;
    }
    _link.emergency = YES;
    return self;
}

- (UMM2PAState *)eventEmergencyCeases       /* MTP3 tells his is not an emergency link */
{
    [self logStatemachineEvent:__func__];
    if(_link.emergency==YES)
    {
        _link.t4.seconds = _link.t4n;
    }
    _link.emergency = NO;
    return self;
}

- (UMM2PAState *) eventLocalProcessorOutage         /* MTP3 tells processor is out */
{
    [self logStatemachineEvent:__func__ forced:YES];
    _link.local_processor_outage = YES;
    return self;
}

- (UMM2PAState *) eventLocalProcessorRecovery        /* MTP3 tells processor is back */
{
    [self logStatemachineEvent:__func__ forced:YES];
    _link.local_processor_outage = NO;
    [_link sendLinkstatus:M2PA_LINKSTATE_READY synchronous:YES]; /* sending FISU */
    return [[UMM2PAState_AlignedReady alloc] initWithLink:_link status:M2PA_STATUS_ALIGNED_READY];
}

- (UMM2PAState *)eventReceiveUserData:(NSData *)userData
{
    /* data processing is done outside by the caller */
    [self logStatemachineEvent:__func__ forced:YES];
    _link.remote_processor_outage = YES;
    return  [[UMM2PAState_ProcessorOutage alloc]initWithLink:_link status:M2PA_STATUS_PROCESSOR_OUTAGE];
    return self;
}

- (UMM2PAState *)eventSendUserData:(NSData *)data
                        ackRequest:(NSDictionary *)ackRequest
                               dpc:(int)dpc
{
    [self logStatemachineEvent:__func__ forced:YES];
    [_link notifyMtp3:M2PA_STATUS_ALIGNED_NOT_READY async:YES];
    return self;
}


#pragma mark -
#pragma mark eventLinkstatus handlers

- (UMM2PAState *)eventLinkstatusOutOfService:(NSNumber *)socketNumber    /* other side sent us linkstatus out of service SIOS */
{
    [self logStatemachineEvent:__func__ socketNumber:socketNumber];
    [self sendLinkstateOutOfService:YES];
    return [[UMM2PAState_OutOfService alloc]initWithLink:_link status:M2PA_STATUS_OOS];
}

- (UMM2PAState *)eventLinkstatusAlignment:(NSNumber *)socketNumber       /* other side sent us linkstatus alignment SIO */
{
    [self logStatemachineEvent:__func__ socketNumber:socketNumber];
    if(_link.emergency)
    {
        [self sendLinkstateProvingEmergency:YES];
    }
    else
    {
        [self sendLinkstateProvingNormal:YES];
    }
    return self;
//    [self sendLinkstateOutOfService:YES];
//    return [[UMM2PAState_OutOfService alloc]initWithLink:_link status:M2PA_STATUS_OOS];
}

- (UMM2PAState *)eventLinkstatusProvingNormal:(NSNumber *)socketNumber       /* other side sent us linkstatus proving normal SIN */
{
    [self logStatemachineEvent:__func__ socketNumber:socketNumber];
    return self;
}

- (UMM2PAState *)eventLinkstatusProvingEmergency:(NSNumber *)socketNumber    /* other side sent us linkstatus proving normal SIE */
{
    [self logStatemachineEvent:__func__ socketNumber:socketNumber];
    return self;
}

- (UMM2PAState *)eventLinkstatusReady:(NSNumber *)socketNumber       /* other side sent us linkstatus ready FISU */
{
    [self logStatemachineEvent:__func__ socketNumber:socketNumber];
    /* according to Q.703 we should go to processor outage here */
    /* however in RFC 4165 this is handled differently by a special processor outage message */
    [self sendLinkstateReady:YES];
    return  [[UMM2PAState_AlignedReady alloc]initWithLink:_link status:M2PA_STATUS_ALIGNED_READY];
}

- (UMM2PAState *)eventLinkstatusBusy:(NSNumber *)socketNumber                /* other side sent us linkstatus busy */
{
    [self logStatemachineEvent:__func__ socketNumber:socketNumber];
    return self;
}

- (UMM2PAState *)eventLinkstatusBusyEnded:(NSNumber *)socketNumber           /* other side sent us linkstatus busy ended */
{
    [self logStatemachineEvent:__func__ socketNumber:socketNumber];
    return self;
}

- (UMM2PAState *)eventLinkstatusProcessorOutage:(NSNumber *)socketNumber     /* other side sent us linkstatus processor outage SIPO */
{
    [self logStatemachineEvent:__func__ socketNumber:socketNumber];
    _link.remote_processor_outage = YES;
    return  [[UMM2PAState_ProcessorOutage alloc]initWithLink:_link status:M2PA_STATUS_PROCESSOR_OUTAGE];
}

- (UMM2PAState *)eventLinkstatusProcessorRecovered:(NSNumber *)socketNumber
{
    [self logStatemachineEvent:__func__ socketNumber:socketNumber];
    _link.remote_processor_outage = NO;
    return self;
}


#pragma mark -
#pragma mark timers

- (UMM2PAState *)eventTimer1                        /* timer 1 fired (alignment ready timer) */
{
    [self logStatemachineEvent:__func__];
    return self;
}

- (UMM2PAState *)eventTimer1r                        /* timer 1r fired (time to send alignment ready) */
{
    [self logStatemachineEvent:__func__];
    return self;
}


- (UMM2PAState *)eventTimer2                       /* timer 2 fired (not aligned timer) */
{
    [self logStatemachineEvent:__func__];
    return self;
}


- (UMM2PAState *)eventTimer3                       /* timer 3 fired (waiting for first proving. alignment timer) */
{
    [self logStatemachineEvent:__func__];
    if(([_link.t4 isExpired]) || (_t4_expired))
    {
        [_link.t1 stop];
        [_link.t2 stop];
        [_link.t4 stop];
        [self sendLinkstateReady:YES];
        return [[UMM2PAState_AlignedReady alloc]initWithLink:_link status:M2PA_STATUS_ALIGNED_READY];
    }
    if(_link.emergency)
    {
        [self sendLinkstateProvingEmergency:YES];
    }
    else
    {
        [self sendLinkstateProvingNormal:YES];
    }
    return self;
}

- (UMM2PAState *)eventTimer4                       /* timer 4 fired (proving period) */
{
    _t4_expired = YES;
    [self logStatemachineEvent:__func__];
    [_link.t1 stop];
    [_link.t2 stop];
    [_link.t4 stop];
    [self sendLinkstateReady:YES];
    return [[UMM2PAState_AlignedReady alloc]initWithLink:_link status:M2PA_STATUS_ALIGNED_READY];
}


- (UMM2PAState *)eventRepeatTimer                      /* timer 4r fired (time between proving packets being sent) */
{
    [self logStatemachineEvent:__func__];
    if(([_link.t4 isExpired]) || (_t4_expired))
    {
        [_link.t1 stop];
        [_link.t2 stop];
        [_link.t4 stop];
        [_link.repeatTimer stop];
        [self sendLinkstateReady:YES];
        return [[UMM2PAState_AlignedReady alloc]initWithLink:_link status:M2PA_STATUS_ALIGNED_READY];
    }
    if(_link.emergency)
    {
        [self sendLinkstateProvingEmergency:YES];
    }
    else
    {
        [self sendLinkstateProvingNormal:YES];
    }
    return self;
}


- (UMM2PAState *)eventTimer5                        /* timer 5 fired */
{
    [self logStatemachineEvent:__func__];
    return self;
}


- (UMM2PAState *)eventTimer6                       /* timer 6 fired (remote congestion timer.
                                                            if remote stays longer than this, we go OOS) */
{
    [self logStatemachineEvent:__func__];
    return self;
}


- (UMM2PAState *)eventTimer7                       /* timer 7 fired ((excessive delay of acknowledgement) */
{
    [self logStatemachineEvent:__func__];
    return self;
}


@end
