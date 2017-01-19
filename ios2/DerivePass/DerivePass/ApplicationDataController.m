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
#import <CommonCrypto/CommonCryptor.h>
#import <Security/SecRandom.h>

#include <dispatch/dispatch.h>

@interface ApplicationDataController ()<ApplicationCryptor>

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

  NSFetchRequest* request = [Application fetchRequest];
  request.sortDescriptors =
      @[ [NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES] ];

  NSArray* res =
      [self.managedObjectContext executeFetchRequest:request error:&err];
  NSAssert(res != nil, @"Failed to save CoreData: %@\n%@",
           [err localizedDescription], [err userInfo]);

  self.internalList = [NSMutableArray arrayWithArray:res];
  for (Application* app in self.internalList) app.cryptor = self;
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
          if ([r.modificationDate
                  isEqualToDate:[obj valueForKey:@"changed_at"]])
            return;

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
  res.cryptor = self;
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
}


- (uint8_t)hexDigit:(char)digit {
  if ('0' <= digit && digit <= '9')
    return digit - '0';
  else if ('a' <= digit && digit <= 'f')
    return (digit - 'a') + 0xa;
  else if ('A' <= digit && digit <= 'F')
    return (digit - 'A') + 0xa;
  else
    NSAssert(NO, @"Invalid HEX digit");
  return 0;
}


- (NSData*)fromHex:(NSString*)str {
  const char* bytes = str.UTF8String;
  int len = (int)str.length;
  NSAssert(len % 2 == 0, @"Invalid HEX string");

  NSMutableData* res = [NSMutableData dataWithLength:len / 2];
  uint8_t* o = (uint8_t*)res.mutableBytes;
  for (int i = 0; i < len; i += 2) {
    char h = bytes[i];
    char l = bytes[i + 1];

    o[i / 2] = ([self hexDigit:h] << 4) | [self hexDigit:l];
  }
  return res;
}


- (NSString*)toHex:(NSData*)data {
  NSMutableString* res = [NSMutableString stringWithCapacity:data.length * 2];

  const uint8_t* bytes = (const uint8_t*)data.bytes;
  for (int i = 0; i < (int)data.length; i++) {
    [res appendFormat:@"%02x", bytes[i]];
  }

  return res;
}


- (NSString*)encrypt:(NSString*)str {
  NSAssert(self.AESKey.length == kApplicationDataKeySize,
           @"Invalid AES key length");

  NSMutableData* res =
      [NSMutableData dataWithLength:kCCBlockSizeAES128 * 2 + str.length];
  NSAssert(res != nil, @"Failed to allocated mutable output for encrypt");

  // Set IV
  int err = SecRandomCopyBytes(kSecRandomDefault, kCCBlockSizeAES128,
                               res.mutableBytes);
  NSAssert(err == 0, @"SecRandomCopyBytes failure");

  size_t bytes;
  CCCryptorStatus st;
  st = CCCrypt(kCCEncrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding,
               self.AESKey.bytes, self.AESKey.length, res.bytes,
               (void*)str.UTF8String, str.length,
               res.mutableBytes + kCCBlockSizeAES128,
               res.length - kCCBlockSizeAES128, &bytes);
  NSAssert(st == kCCSuccess, @"CCCrypt encrypt failure");

  res.length = kCCBlockSizeAES128 + bytes;

  return [self toHex:res];
}


- (NSString*)decrypt:(NSString*)str {
  NSAssert(self.AESKey.length == kApplicationDataKeySize,
           @"Invalid AES key length");

  NSData* data = [self fromHex:str];
  NSAssert(data.length > kCCBlockSizeAES128, @"Invalid encrypted data length");

  NSMutableData* res = [NSMutableData dataWithLength:data.length];
  NSAssert(res != nil, @"Failed to allocated mutable output for decrypt");

  size_t bytes;
  CCCryptorStatus err;
  err = CCCrypt(
      kCCDecrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding, self.AESKey.bytes,
      self.AESKey.length, data.bytes, data.bytes + kCCBlockSizeAES128,
      data.length - kCCBlockSizeAES128, res.mutableBytes, res.length, &bytes);
  NSAssert(err == kCCSuccess, @"CCCrypt decrypt failure");

  return [NSString stringWithFormat:@"%.*s", (int)bytes, res.bytes];
}


- (NSString*)encryptNumber:(int32_t)num {
  return [self encrypt:[NSString stringWithFormat:@"%d", num]];
}


- (int32_t)decryptNumber:(NSString*)str {
  return atoi([self decrypt:str].UTF8String);
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
