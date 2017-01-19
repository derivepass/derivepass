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
@dynamic domain;
@dynamic index;
@dynamic login;
@dynamic master;
@dynamic removed;
@dynamic revision;
@dynamic uuid;

@end
