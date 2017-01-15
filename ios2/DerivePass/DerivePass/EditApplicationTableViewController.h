//
//  EditApplicationTableViewController.h
//  DerivePass
//
//  Created by Indutnyy, Fedor on 1/14/17.
//
//  This software is licensed under the MIT License.
//  Copyright © 2017 Indutny Inc. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <UIKit/UIKit.h>

#import "ApplicationDataController.h"

@interface EditApplicationTableViewController : UITableViewController

@property NSManagedObject* info;
@property ApplicationDataController* dataController;

@end
