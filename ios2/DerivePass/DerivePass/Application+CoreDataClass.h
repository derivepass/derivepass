//
//  Application+CoreDataClass.h
//  DerivePass
//
//  Created by Indutnyy, Fedor on 1/19/17.
//
//  This software is licensed under the MIT License.
//  Copyright © 2017 Indutny Inc. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ApplicationCryptor

- (NSString*)encrypt:(NSString*)str;
- (NSString*)decrypt:(NSString*)str;

- (NSString*)encryptNumber:(int32_t)num;
- (int32_t)decryptNumber:(NSString*)str;


@end

@interface Application : NSManagedObject

@property(weak) id<ApplicationCryptor> cryptor;

@end

NS_ASSUME_NONNULL_END

#import "Application+CoreDataProperties.h"
