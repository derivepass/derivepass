//
//  ApplicationDataController.h
//  DerivePass
//
//  Created by Indutnyy, Fedor on 1/14/17.
//
//  This software is licensed under the MIT License.
//  Copyright © 2017 Indutny Inc. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

#import "Application+CoreDataProperties.h"

@protocol ApplicationDataControllerDelegate

- (void)onDataUpdate;

@end

@interface ApplicationDataController : NSData

@property(weak) id<ApplicationDataControllerDelegate> delegate;
@property(strong) NSString* masterHash;
@property(strong) AESCryptor* cryptor;

- (ApplicationDataController*)init;

- (NSMutableArray<Application*>*)applications;

- (Application*)allocApplication;
- (void)pushApplication:(Application*)object;
- (void)deleteApplication:(Application*)object;

- (void)save;

@end
