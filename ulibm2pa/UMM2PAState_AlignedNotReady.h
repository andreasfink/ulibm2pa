//
//  UMM2PAState_AlignedNotReady.h
//  ulibm2pa
//
//  Created by Andreas Fink on 17.03.20.
//  Copyright © 2020 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulibm2pa/UMM2PAState.h>

@interface UMM2PAState_AlignedNotReady : UMM2PAState
{
    BOOL _t4_expired;
    BOOL _ready_received;
}
@end

