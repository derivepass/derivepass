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

@interface ApplicationDataController : NSData

- (ApplicationDataController*)init;

- (NSArray<NSManagedObject*>*)list;
- (NSManagedObject*)allocApplication;
- (void)deleteObject:(NSManagedObject*)object;
- (void)save;

@end
