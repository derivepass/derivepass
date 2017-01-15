//
//  ApplicationDataController.m
//  DerivePass
//
//  Created by Indutnyy, Fedor on 1/14/17.
//
//  This software is licensed under the MIT License.
//  Copyright © 2017 Indutny Inc. All rights reserved.
//

#import "ApplicationDataController.h"

#import <CloudKit/CloudKit.h>

@interface ApplicationDataController ()

@property(strong) NSManagedObjectContext* managedObjectContext;

@end


@implementation ApplicationDataController

- (ApplicationDataController*)init {
  self = [super init];
  if (!self) return nil;

  [self initCoreData];
  return self;
}


- (void)initCoreData {
  NSURL* modelUrl = [[NSBundle mainBundle] URLForResource:@"DerivePass"
                                            withExtension:@"momd"];
  NSManagedObjectModel* model =
      [[NSManagedObjectModel alloc] initWithContentsOfURL:modelUrl];
  NSAssert(model != nil, @"Failed to initialize managed object model");

  NSPersistentStoreCoordinator* psc =
      [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
  NSManagedObjectContext* ctx = [[NSManagedObjectContext alloc]
      initWithConcurrencyType:NSMainQueueConcurrencyType];
  ctx.persistentStoreCoordinator = psc;
  self.managedObjectContext = ctx;

  NSFileManager* fm = [NSFileManager defaultManager];
  NSURL* documentsURL = [[fm URLsForDirectory:NSDocumentDirectory
                                    inDomains:NSUserDomainMask] lastObject];
  NSURL* storeURL =
      [documentsURL URLByAppendingPathComponent:@"Applications.data"];

  NSError* err = nil;
  NSPersistentStore* store = [psc addPersistentStoreWithType:NSBinaryStoreType
                                               configuration:nil
                                                         URL:storeURL
                                                     options:nil
                                                       error:&err];
  NSAssert(store != nil, @"Failed to initialize PSC: %@\n%@",
           [err localizedDescription], [err userInfo]);
}


- (NSArray<NSManagedObject*>*)list {
  NSError* err = nil;
  NSFetchRequest* request =
      [NSFetchRequest fetchRequestWithEntityName:@"Application"];
  request.sortDescriptors =
      @[ [NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES] ];

  NSArray* res =
      [self.managedObjectContext executeFetchRequest:request error:&err];
  NSAssert(res != nil, @"Failed to save CoreData: %@\n%@",
           [err localizedDescription], [err userInfo]);

  return res;
}


- (NSManagedObject*)allocApplication {
  return [NSEntityDescription
      insertNewObjectForEntityForName:@"Application"
               inManagedObjectContext:self.managedObjectContext];
}


- (void)deleteObject:(NSManagedObject*)object {
  [self.managedObjectContext deleteObject:object];
}


- (void)save {
  NSError* err = nil;
  [self.managedObjectContext save:&err];
  NSAssert(err == nil, @"Failed to save CoreData: %@\n%@",
           [err localizedDescription], [err userInfo]);
}

@end
