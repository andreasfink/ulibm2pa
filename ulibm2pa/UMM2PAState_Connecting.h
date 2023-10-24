//
//  UMM2PAState_Connecting.h
//  ulibm2pa
//
//  Created by Andreas Fink on 10.10.22.
//  Copyright © 2022 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulibm2pa/UMM2PAState.h>


/*
 We are in "OFF" state when the link is completely down.
 We are in "Connecting "state when we have given the order to SCTP to connect but
 sctp is not up yet.
*/

@interface UMM2PAState_Connecting : UMM2PAState

@end

