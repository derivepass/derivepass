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
  return [self.cryptor decrypt:[self valueForKey:@"domain"]];
}


- (void)setPlaintextLogin:(NSString *)login {
  [self setValue:[self.cryptor encrypt:login] forKey:@"login"];
}


- (NSString *)plaintextLogin {
  return [self.cryptor decrypt:[self valueForKey:@"login"]];
}


- (void)setPlainRevision:(int32_t)revision {
  [self setValue:[self.cryptor encryptNumber:revision] forKey:@"revision"];
}


- (int32_t)plainRevision {
  return [self.cryptor decryptNumber:[self valueForKey:@"revision"]];
}

@end
