//
//  Application+CoreDataProperties.m
//  DerivePass
//
//  Created by Indutnyy, Fedor on 1/19/17.
//
//  This software is licensed under the MIT License.
//  Copyright © 2017 Indutny Inc. All rights reserved.
//

#import "Application+CoreDataProperties.h"

@implementation Application (CoreDataProperties)

+ (NSFetchRequest<Application *> *)fetchRequest {
  return [[NSFetchRequest alloc] initWithEntityName:@"Application"];
}

@dynamic changed_at;
@dynamic index;
@dynamic master;
@dynamic removed;
@dynamic uuid;

- (void)setPlaintextDomain:(NSString *)domain {
  [self setValue:[self.cryptor encrypt:domain] forKey:@"domain"];
}


- (NSString *)plaintextDomain {
  NSString *encrypted = [self valueForKey:@"domain"];
  if (encrypted == domainEnc) return domainClear;
  domainEnc = encrypted;
  domainClear = [self.cryptor decrypt:encrypted];
  return domainClear;
}


- (void)setPlaintextLogin:(NSString *)login {
  [self setValue:[self.cryptor encrypt:login] forKey:@"login"];
}


- (NSString *)plaintextLogin {
  NSString *encrypted = [self valueForKey:@"login"];
  if (encrypted == loginEnc) return loginClear;
  loginEnc = encrypted;
  loginClear = [self.cryptor decrypt:encrypted];
  return loginClear;
}


- (void)setPlainRevision:(int32_t)revision {
  [self setValue:[self.cryptor encryptNumber:revision] forKey:@"revision"];
}


- (int32_t)plainRevision {
  NSString *encrypted = [self valueForKey:@"revision"];
  if (encrypted == revisionEnc) return revisionClear;
  revisionEnc = encrypted;
  revisionClear = [self.cryptor decryptNumber:encrypted];
  return revisionClear;
}

@end
