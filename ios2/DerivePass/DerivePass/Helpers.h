//
//  Helpers.h
//  DerivePass
//
//  Created by Indutnyy, Fedor on 1/20/17.
//  Copyright © 2017 Indutny Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString* const kDefaultEmoji = @"😬";

@interface Helpers : NSObject

+ (NSString*)passwordToEmoji:(NSString*)password;
+ (void)passwordToAESKey:(NSString*)password
          withCompletion:(void (^)(NSData*))completion;

@end
