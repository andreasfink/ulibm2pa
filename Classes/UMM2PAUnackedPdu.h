//
//  UMM2PAUnackedPdu.h
//  ulibm2pa
//
//  Created by Andreas Fink on 30.07.21.
//  Copyright © 2021 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/ulib.h>


@interface UMM2PAUnackedPdu : UMObject
{
    int     _dpc;
    NSData  *_data;
}

@property(readwrite,assign) int     dpc;
@property(readwrite,strong) NSData  *data;

@end
