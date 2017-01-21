//
//  Helpers.h
//  DerivePass
//
//  Created by Indutnyy, Fedor on 1/20/17.
//
//  This software is licensed under the MIT License.
//  Copyright © 2017 Indutny Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <stdint.h>

static NSString* const kDefaultEmoji = @"😬";

@interface Helpers : NSObject

+ (NSString*)passwordToEmoji:(NSString*)password;
+ (void)passwordToAESAndMACKey:(NSString*)password
                withCompletion:(void (^)(NSData* aes, NSData* mac))completion;
+ (void)passwordFromMaster:(NSString*)master
                    domain:(NSString*)domain
                     login:(NSString*)login
               andRevision:(int32_t)revision
            withCompletion:(void (^)(NSString*))completion;

@end
