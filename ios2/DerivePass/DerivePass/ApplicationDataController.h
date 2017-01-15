//
//  ApplicationDataController.h
//  DerivePass
//
//  Created by Indutnyy, Fedor on 1/14/17.
//  Copyright © 2017 Indutny Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface ApplicationDataController : NSData

- (ApplicationDataController*) init;

- (NSArray<NSManagedObject*>*) list;
- (NSManagedObject*) allocApplication;
- (void) deleteObject: (NSManagedObject*) object;
- (void) save;

@end
