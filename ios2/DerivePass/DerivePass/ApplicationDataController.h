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

@protocol ApplicationDataControllerDelegate

- (void)onDataUpdate;

@end

@interface ApplicationDataController : NSData

@property(weak) id<ApplicationDataControllerDelegate> delegate;
@property(strong) NSString* masterHash;

- (ApplicationDataController*)init;

- (NSMutableArray<NSManagedObject*>*)applications;

- (NSManagedObject*)allocApplication;
- (void)pushApplication:(NSManagedObject*)object;
- (void)deleteApplication:(NSManagedObject*)object;

- (void)save;

@end
