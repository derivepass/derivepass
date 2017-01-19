//
//  Application+CoreDataProperties.h
//  DerivePass
//
//  Created by Indutnyy, Fedor on 1/19/17.
//
//  This software is licensed under the MIT License.
//  Copyright © 2017 Indutny Inc. All rights reserved.
//

#import "Application+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface Application (CoreDataProperties)

+ (NSFetchRequest<Application *> *)fetchRequest;

@property(nullable, nonatomic, copy) NSDate *changed_at;
@property(nullable, nonatomic, copy) NSString *domain;
@property(nonatomic) int32_t index;
@property(nullable, nonatomic, copy) NSString *login;
@property(nullable, nonatomic, copy) NSString *master;
@property(nonatomic) BOOL removed;
@property(nonatomic) int32_t revision;
@property(nullable, nonatomic, copy) NSString *uuid;

@end

NS_ASSUME_NONNULL_END
