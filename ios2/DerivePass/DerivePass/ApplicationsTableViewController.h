//
//  ApplicationsTableViewController.h
//  DerivePass
//
//  Created by Indutnyy, Fedor on 1/14/17.
//  Copyright © 2017 Indutny Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface ApplicationsTableViewController : UITableViewController

@property NSString* masterPassword;
@property NSMutableArray<NSManagedObject*>* applications;

@end
