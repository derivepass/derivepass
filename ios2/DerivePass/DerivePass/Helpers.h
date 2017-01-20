//
//  Helpers.h
//  DerivePass
//
//  Created by Indutnyy, Fedor on 1/20/17.
//  Copyright © 2017 Indutny Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <stdint.h>

static NSString* const kDefaultEmoji = @"😬";

@interface Helpers : NSObject

+ (NSString*)passwordToEmoji:(NSString*)password;
+ (void)passwordToAESKey:(NSString*)password
          withCompletion:(void (^)(NSData*))completion;
+ (void)passwordFromMaster:(NSString*)master
                    domain:(NSString*)domain
                     login:(NSString*)login
               andRevision:(int32_t)revision
            withCompletion:(void (^)(NSString*))completion;

@end
