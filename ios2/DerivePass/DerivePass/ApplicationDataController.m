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
#import "AESCryptor.h"

#import <CloudKit/CloudKit.h>

#include <dispatch/dispatch.h>

@interface ApplicationDataController ()

@property(strong) NSManagedObjectContext* managedObjectContext;
@property(strong) CKDatabase* db;

@property(strong) NSMutableArray<Application*>* internalList;

@end


@implementation ApplicationDataController {
  BOOL deferred_save_;
}


- (ApplicationDataController*)init {
  self = [super init];
  if (!self) return nil;

  // NOTE: cryptor MUST be initialzied before CoreData
  self.cryptor = [[AESCryptor alloc] init];

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

  // Needed to trigger "applicationProtectedDataWillBecomeUnavailable"
  NSError* err = nil;
  NSPersistentStore* store = [psc
      addPersistentStoreWithType:NSBinaryStoreType
                   configuration:nil
                             URL:storeURL
                         options:@{
                           NSFileProtectionKey : NSFileProtectionComplete,
                           NSMigratePersistentStoresAutomaticallyOption : @YES
                         }
                           error:&err];
  NSAssert(store != nil, @"Failed to initialize PSC: %@\n%@",
           [err localizedDescription], [err userInfo]);

  NSFetchRequest* request = [Application fetchRequest];
  request.sortDescriptors =
      @[ [NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES] ];

  NSArray* res =
      [self.managedObjectContext executeFetchRequest:request error:&err];
  NSAssert(res != nil, @"Failed to save CoreData: %@\n%@",
           [err localizedDescription], [err userInfo]);

  self.internalList = [NSMutableArray arrayWithArray:res];
  for (Application* app in self.internalList) app.cryptor = self.cryptor;
}


- (void)initCloudKit {
  self.db = [[CKContainer defaultContainer] privateCloudDatabase];

  NSPredicate* every = [NSPredicate predicateWithValue:YES];
  CKQuery* q = [[CKQuery alloc] initWithRecordType:@"EncryptedApplication"
                                         predicate:every];
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
    for (Application* obj in self.internalList) {
      if ([obj.uuid isEqualToString:uuid]) {
        [self mergeCloudItem:r withLocalItem:obj];
        found = YES;
        break;
      }
    }

    if (found) continue;

    Application* obj = [self allocApplication];
    [self updateObject:obj withRecord:r];

    [self.internalList insertObject:obj atIndex:0];
  }

  // Second pass: find new local items
  for (Application* obj in self.internalList) {
    NSString* uuid = obj.uuid;
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


- (void)updateObject:(Application*)obj withRecord:(CKRecord*)r {
  obj.uuid = r.recordID.recordName;
  obj.index = [r[@"index"] intValue];
  obj.removed = [r[@"removed"] intValue];
  obj.changed_at = r.modificationDate;
  obj.master = r[@"master"];

  // NOTE: copying them as they are, because we can't
  // decrypt them at this point
  [obj setValue:r[@"domain"] forKey:@"domain"];
  [obj setValue:r[@"login"] forKey:@"login"];
  [obj setValue:r[@"revision"] forKey:@"revision"];
}


- (void)mergeCloudItem:(CKRecord*)item withLocalItem:(Application*)obj {
  NSDate* local = obj.changed_at;
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


- (void)uploadItemToCloud:(Application*)obj {
  CKRecordID* recID = [[CKRecordID alloc] initWithRecordName:obj.uuid];

  [self.db
      fetchRecordWithID:recID
      completionHandler:^(CKRecord* _Nullable r, NSError* _Nullable error) {
        if (error.code == CKErrorUnknownItem) {
          r = [[CKRecord alloc] initWithRecordType:@"EncryptedApplication"
                                          recordID:recID];
        } else if (error != nil) {
          // TODO(indutny): handle errors
          return;
        }

        dispatch_async(dispatch_get_main_queue(), ^(void) {
          // Skip items that are the same
          if ([r.modificationDate isEqualToDate:obj.changed_at]) return;

          // Cloud object is newer!
          if ([r.modificationDate compare:obj.changed_at] ==
              NSOrderedDescending)
            return [self updateObject:obj withRecord:r];

          // Copy these as they are, because they are encrypted
          r[@"domain"] = [obj valueForKey:@"domain"];
          r[@"login"] = [obj valueForKey:@"login"];
          r[@"revision"] = [obj valueForKey:@"revision"];

          r[@"index"] = [NSNumber numberWithInt:obj.index];
          r[@"removed"] = [NSNumber numberWithBool:obj.removed];
          r[@"master"] = obj.master;

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


- (NSMutableArray<Application*>*)applications {
  NSMutableArray<Application*>* res = [NSMutableArray array];
  for (Application* obj in self.internalList)
    if ([obj.master isEqualToString:self.masterHash])
      [res insertObject:obj atIndex:res.count];
  return res;
}


- (Application*)allocApplication {
  Application* res = [NSEntityDescription
      insertNewObjectForEntityForName:@"Application"
               inManagedObjectContext:self.managedObjectContext];
  res.uuid = [[NSUUID UUID] UUIDString];
  res.changed_at = [NSDate date];
  res.master = self.masterHash;
  res.cryptor = self.cryptor;
  return res;
}


- (void)pushApplication:(Application*)object {
  [self.internalList insertObject:object atIndex:self.internalList.count];
}


- (void)deleteApplication:(Application*)object {
  object.removed = YES;

  // Clean-up encrypted data
  object.plainRevision = 1;
  object.plaintextLogin = @"";
  object.plaintextDomain = @"";

  object.changed_at = [NSDate date];
}


- (void)save {
  [self sort];
  for (Application* obj in self.internalList) {
    [self uploadItemToCloud:obj];
  }
  [self coreDataSave];
}


- (void)sort {
  [self.internalList sortUsingComparator:^NSComparisonResult(id _Nonnull obj1,
                                                             id _Nonnull obj2) {
    Application* a = obj1;
    Application* b = obj2;

    return a.index < b.index
               ? NSOrderedAscending
               : a.index > b.index ? NSOrderedDescending : NSOrderedSame;
  }];
}


- (void)coreDataSave {
  NSError* err = nil;
  [self.managedObjectContext save:&err];
  NSAssert(err == nil, @"Failed to save CoreData: %@\n%@",
           [err localizedDescription], [err userInfo]);
}

@end
