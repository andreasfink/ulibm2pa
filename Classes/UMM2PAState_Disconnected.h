//
//  UMM2PAState_Off.h
//  ulibm2pa
//
//  Created by Andreas Fink on 17.03.20.
//  Copyright © 2020 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMM2PAState.h"


/*
 We are in "OFF" state when the link is completely down.
 We are in "Connecting "state when we have given the order to SCTP to connect but
 sctp is not up yet.
*/

@interface UMM2PAState_Disconnected : UMM2PAState

@end

