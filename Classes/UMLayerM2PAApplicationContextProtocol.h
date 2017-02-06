//
//  UMSS7Stack_ApplicationContext_protocol.h
//  ulibm2pa
//
//  Created by Andreas Fink on 24.01.17.
//  Copyright © 2017 Andreas Fink. All rights reserved.
//

#import <Foundation/Foundation.h>

@class UMLayerM2PA;

@protocol UMLayerM2PAApplicationContextProtocol<NSObject>

- (UMLayerSctp *)getSCTP:(NSString *)name;

@end
