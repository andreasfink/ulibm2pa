//
//  UMM2PAState_AlignedReady.m
//  ulibm2pa
//
//  Created by Andreas Fink on 17.03.20.
//  Copyright © 2020 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMM2PAState_AlignedReady.h"
#import "UMM2PAState_allStates.h"
#import "UMLayerM2PA.h"

@implementation UMM2PAState_AlignedReady

- (UMM2PAState *)initWithLink:(UMLayerM2PA *)link status:(M2PA_Status)statusCode
{
    self = [super initWithLink:link status:statusCode];
    {
        [_link.t1 stop];
        [_link.t2 stop];
        [_link.t3 stop];
        [_link.t4 stop];
        _statusCode = M2PA_STATUS_ALIGNED_READY;
        /* we now send a READY signal every second
           until the other side sends READY as well or sends traffic
           Then we go int In service state
        */
        [_link.t1r start];
        [_link.t1 start];
        _readySent = 0;
    }
    return self;
}

- (NSString *)description
{
    return @"aligned-ready";
}

#pragma mark -
#pragma mark event handlers


- (UMM2PAState *)eventPowerOn                   /* switch on the wire */
{
    [self logStatemachineEvent:__func__];
    [_link addToLayerHistoryLog:@"poweron in aligned ready ignored"];
    return self;
}

- (UMM2PAState *)eventPowerOff                  /* switch off the wire */
{
    [self logStatemachineEvent:__func__];
    [_link addToLayerHistoryLog:@"poweroff in aligned ready ignored"];
    return self;
}


- (UMM2PAState *)eventStart                     /* start the alignment process */
{
    [self logStatemachineEvent:__func__];
    [_link addToLayerHistoryLog:@"start in aligned ready ignored"];
    return self;
}


- (UMM2PAState *)eventStop                      /* stop the link */
{
    [self logStatemachineEvent:__func__];
    [self sendLinkstateOutOfService:YES];
    return [[UMM2PAState_OutOfService alloc]initWithLink:_link status:M2PA_STATUS_OOS];
}

- (UMM2PAState *)eventSctpUp:(NSNumber *)socketNumber              /* SCTP reports the 'wire' has come up*/
{
    [self logStatemachineEvent:__func__ socketNumber:socketNumber];
    return self;
}

- (UMM2PAState *)eventSctpDown:(NSNumber *)socketNumber             /* SCTP reports the conncetion is lost */
{
    [self logStatemachineEvent:__func__ socketNumber:socketNumber];
    /* link failure event according to Q:703 07/96 page 5 */
    /* we cant send OOS on a already dead link so we skip it */
    // [self sendLinkstateOutOfService:YES];
    return [[UMM2PAState_Disconnected alloc]initWithLink:_link status:M2PA_STATUS_DISCONNECTED];
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
    _link.emergency = NO;
    if(_link.emergency==YES)
    {
        _link.t4.seconds = _link.t4n;
    }
    return self;
}

- (UMM2PAState *) eventLocalProcessorOutage         /* MTP3 tells processor is out */
{
    [self logStatemachineEvent:__func__ forced:YES];
    [_link sendLinkstatus:M2PA_LINKSTATE_PROCESSOR_OUTAGE synchronous:YES];
    _link.linkstateProcessorOutageSent++;
    [self logStatemachineEventString:@"sendProcessorOutage"];
    [_link addToLayerHistoryLog:@"sendProcessorOutage"];
    return [[UMM2PAState_AlignedNotReady alloc] initWithLink:_link status:M2PA_STATUS_ALIGNED_NOT_READY];
}

- (UMM2PAState *) eventLocalProcessorRecovery       /* MTP3 tells processor is back */
{
    [self logStatemachineEvent:__func__ forced:YES];
    return self;
}

#pragma mark -
#pragma mark eventLinkstatus handlers

- (UMM2PAState *)eventLinkstatusOutOfService:(NSNumber *)socketNumber /* other side sent us linkstatus out of service SIOS */
{
    [self logStatemachineEvent:__func__ socketNumber:socketNumber];
    [self sendLinkstateOutOfService:YES];
    return [[UMM2PAState_OutOfService alloc]initWithLink:_link status:M2PA_STATUS_OOS];
}


- (UMM2PAState *)eventLinkstatusAlignment:(NSNumber *)socketNumber /* other side sent us linkstatus alignment SIO */
{
    [self logStatemachineEvent:__func__ socketNumber:socketNumber];
    [self sendLinkstateReady:YES];
//  return [[UMM2PAState_OutOfService alloc]initWithLink:_link status:M2PA_STATUS_OOS];
    return self;
}

- (UMM2PAState *)eventLinkstatusProvingNormal:(NSNumber *)socketNumber /* other side sent us linkstatus proving normal SIN */
{
    [self logStatemachineEvent:__func__ socketNumber:socketNumber];
    return self;
}

- (UMM2PAState *)eventLinkstatusProvingEmergency:(NSNumber *)socketNumber /* other side sent us linkstatus emergency normal SIE */
{
    [self logStatemachineEvent:__func__ socketNumber:socketNumber];
    return self;
}

- (UMM2PAState *)eventLinkstatusReady:(NSNumber *)socketNumber   /* other side sent us linkstatus ready FISU */
{
    [self logStatemachineEvent:__func__ socketNumber:socketNumber];
    [_link.t1 stop];
    [_link.t2 stop];
    [_link.t4 stop];
    [_link notifyMtp3InService];
    return  [[UMM2PAState_InService alloc]initWithLink:_link status:M2PA_STATUS_IS];
}

- (UMM2PAState *)eventLinkstatusBusy:(NSNumber *)socketNumber        /* other side sent us linkstatus busy */
{
    [self logStatemachineEvent:__func__ socketNumber:socketNumber];
    return self;
}

- (UMM2PAState *)eventLinkstatusBusyEnded:(NSNumber *)socketNumber   /* other side sent us linkstatus busy ended */
{
    [self logStatemachineEvent:__func__ socketNumber:socketNumber];
    return self;
}


- (UMM2PAState *)eventLinkstatusProcessorOutage:(NSNumber *)socketNumber /* other side sent us linkstatus processor outage SIPO */
{
    [self logStatemachineEvent:__func__ socketNumber:socketNumber];
    _link.remote_processor_outage = YES;
    return  [[UMM2PAState_ProcessorOutage alloc]initWithLink:_link status:M2PA_STATUS_PROCESSOR_OUTAGE];
    return self;
}

- (UMM2PAState *)eventLinkstatusProcessorRecovered:(NSNumber *)socketNumber  /* other side sent us linkstatus processor recovered */
{
    [self logStatemachineEvent:__func__ socketNumber:socketNumber];
    _link.remote_processor_outage = NO;
    return self;
}


- (UMM2PAState *)eventSendUserData:(NSData *)data
                        ackRequest:(NSDictionary *)ackRequest
                               dpc:(int)dpc
{
    [_link sendData:data
             stream:M2PA_STREAM_USERDATA
         ackRequest:ackRequest
                dpc:dpc];
    return [[UMM2PAState_InService alloc]initWithLink:_link status:M2PA_STATUS_IS];
}

- (UMM2PAState *)eventReceiveUserData:(NSData *)userData socketNumber:(NSNumber *)socketNumber
{
    [self logStatemachineEvent:__func__ forced:YES socketNumber:socketNumber];
    [_link.t1 stop];
    [_link.t1r stop];
    [_link.t2 stop];
    [_link.t4 stop];
    [self logStatemachineEventString:@"receiveUserData going IS"];
    [_link notifyMtp3InService];
    return [[UMM2PAState_InService alloc]initWithLink:_link status:M2PA_STATUS_IS];
}



#pragma mark -
#pragma mark timers

- (UMM2PAState *)eventTimer1                        /* timer 1 fired (alignment ready timer) */
{
    [self logStatemachineEvent:__func__];
    _readySent++;
    [self sendLinkstateReady:YES];
    [_link.t1 stop];
    [_link.t2 stop];
    [_link.t4 stop];
    [self logStatemachineEventString:@"t1 expired. going IS"];
    return [[UMM2PAState_InService alloc]initWithLink:_link status:M2PA_STATUS_IS];
}

- (UMM2PAState *)eventTimer1r                       /* timer 1r fired (time to send alignment ready) */
{
    [self logStatemachineEvent:__func__];
    _readySent++;
    [self sendLinkstateReady:YES];
    return self;
}


@end
