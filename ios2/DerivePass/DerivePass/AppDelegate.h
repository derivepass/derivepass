//
//  AppDelegate.h
//  DerivePass
//
//  Created by Indutnyy, Fedor on 1/13/17.
//  Copyright © 2017 Indutny Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;


@end

