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

#include <dispatch/dispatch.h>

@interface ApplicationDataController ()

@property(strong) NSManagedObjectContext* managedObjectContext;
@property(strong) CKDatabase* db;

@property(strong) NSMutableArray<NSManagedObject*>* internalList;

@end


@implementation ApplicationDataController {
  BOOL deferred_save_;
}


- (ApplicationDataController*)init {
  self = [super init];
  if (!self) return nil;

  [self initCoreData];
  [self initCloudKit];

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

  NSFetchRequest* request =
      [NSFetchRequest fetchRequestWithEntityName:@"Application"];
  request.sortDescriptors =
      @[ [NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES] ];

  NSArray* res =
      [self.managedObjectContext executeFetchRequest:request error:&err];
  NSAssert(res != nil, @"Failed to save CoreData: %@\n%@",
           [err localizedDescription], [err userInfo]);

  self.internalList = [NSMutableArray arrayWithArray:res];
}


- (void)initCloudKit {
  self.db = [[CKContainer defaultContainer] privateCloudDatabase];

  NSPredicate* every = [NSPredicate predicateWithValue:YES];
  CKQuery* q =
      [[CKQuery alloc] initWithRecordType:@"Application" predicate:every];
  [self.db performQuery:q
           inZoneWithID:nil
      completionHandler:^(NSArray<CKRecord*>* _Nullable results,
                          NSError* _Nullable error) {
        // TODO(indutny): handle error
        if (error != nil) return;

        dispatch_async(dispatch_get_main_queue(), ^(void) {
          [self mergeCloudItems:results];
        });
      }];
}


- (void)mergeCloudItems:(NSArray<CKRecord*>*)items {
  // First pass: merge equal and find new remote items
  for (CKRecord* r in items) {
    NSString* uuid = r.recordID.recordName;

    BOOL found = NO;
    for (NSManagedObject* obj in self.internalList) {
      if ([[obj valueForKey:@"uuid"] isEqualToString:uuid]) {
        [self mergeCloudItem:r withLocalItem:obj];
        found = YES;
        break;
      }
    }

    if (found) continue;

    NSManagedObject* obj = [self allocApplication];
    [self updateObject:obj withRecord:r];

    [self.internalList insertObject:obj atIndex:0];
  }

  // Second pass: find new local items
  for (NSManagedObject* obj in self.internalList) {
    NSString* uuid = [obj valueForKey:@"uuid"];
    BOOL found = NO;
    for (CKRecord* r in items) {
      if (![uuid isEqualToString:r.recordID.recordName]) continue;
      found = YES;
      break;
    }

    // Already handled during first pass
    if (found) continue;

    [self uploadItemToCloud:obj];
  }

  [self sort];

  [self coreDataSave];
  [self.delegate onDataUpdate];
}


- (void)updateObject:(NSManagedObject*)obj withRecord:(CKRecord*)r {
  [obj setValue:r.recordID.recordName forKey:@"uuid"];
  [obj setValue:r[@"domain"] forKey:@"domain"];
  [obj setValue:r[@"login"] forKey:@"login"];
  [obj setValue:r[@"index"] forKey:@"index"];
  [obj setValue:r[@"revision"] forKey:@"revision"];
  [obj setValue:r[@"removed"] forKey:@"removed"];
  [obj setValue:r.modificationDate forKey:@"changed_at"];
  [obj setValue:r[@"master"] forKey:@"master"];
}


- (void)mergeCloudItem:(CKRecord*)item withLocalItem:(NSManagedObject*)obj {
  NSDate* local = [obj valueForKey:@"changed_at"];
  NSDate* remote = item.modificationDate;

  switch ([local compare:remote]) {
    // Update local
    case NSOrderedAscending: {
      [self updateObject:obj withRecord:item];
      break;
    }
    // Update remote
    case NSOrderedDescending: {
      [self uploadItemToCloud:obj];
      break;
    }
    // Same?
    default:
      break;
  }
}


- (void)uploadItemToCloud:(NSManagedObject*)obj {
  CKRecordID* recID =
      [[CKRecordID alloc] initWithRecordName:[obj valueForKey:@"uuid"]];

  [self.db
      fetchRecordWithID:recID
      completionHandler:^(CKRecord* _Nullable r, NSError* _Nullable error) {
        if (error.code == CKErrorUnknownItem) {
          r = [[CKRecord alloc] initWithRecordType:@"Application"
                                          recordID:recID];
        } else if (error != nil) {
          // TODO(indutny): handle errors
          return;
        }

        dispatch_async(dispatch_get_main_queue(), ^(void) {
          // Skip items that are the same
          if ([r.modificationDate
                  isEqualToDate:[obj valueForKey:@"changed_at"]])
            return;

          r[@"domain"] = [obj valueForKey:@"domain"];
          r[@"login"] = [obj valueForKey:@"login"];
          r[@"index"] = [obj valueForKey:@"index"];
          r[@"revision"] = [obj valueForKey:@"revision"];
          r[@"removed"] = [obj valueForKey:@"removed"];
          r[@"master"] = [obj valueForKey:@"master"];
          [self.db saveRecord:r
              completionHandler:^(CKRecord* _Nullable record,
                                  NSError* _Nullable error) {
                // Retry on obvious conflict
                if (error != nil && error.code == CKErrorServerRecordChanged)
                  [self uploadItemToCloud:obj];

                // TODO(indutny): handle other errors
              }];
        });
      }];
}


- (NSMutableArray<NSManagedObject*>*)applications {
  NSMutableArray<NSManagedObject*>* res = [NSMutableArray array];
  for (NSManagedObject* obj in self.internalList)
    if ([[obj valueForKey:@"master"] isEqualToString:self.masterHash])
      [res insertObject:obj atIndex:res.count];
  return res;
}


- (NSManagedObject*)allocApplication {
  NSManagedObject* res = [NSEntityDescription
      insertNewObjectForEntityForName:@"Application"
               inManagedObjectContext:self.managedObjectContext];
  [res setValue:[[NSUUID UUID] UUIDString] forKey:@"uuid"];
  [res setValue:[NSDate date] forKey:@"changed_at"];
  [res setValue:self.masterHash forKey:@"master"];
  return res;
}


- (void)pushApplication:(NSManagedObject*)object {
  [self.internalList insertObject:object atIndex:self.internalList.count];
}


- (void)deleteApplication:(NSManagedObject*)object {
  [object setValue:[NSNumber numberWithBool:YES] forKey:@"removed"];
}


- (void)save {
  [self sort];
  for (NSManagedObject* obj in self.internalList) {
    [self uploadItemToCloud:obj];
  }
  [self coreDataSave];
}


- (void)sort {
  [self.internalList sortUsingComparator:^NSComparisonResult(id _Nonnull obj1,
                                                             id _Nonnull obj2) {
    NSManagedObject* a = obj1;
    NSManagedObject* b = obj2;

    return [[a valueForKey:@"index"] compare:[b valueForKey:@"index"]];
  }];
}


- (void)coreDataSave {
  NSError* err = nil;
  [self.managedObjectContext save:&err];
  NSAssert(err == nil, @"Failed to save CoreData: %@\n%@",
           [err localizedDescription], [err userInfo]);
}

@end
