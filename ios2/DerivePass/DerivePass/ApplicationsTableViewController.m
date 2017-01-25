//
//  ApplicationsTableViewController.m
//  DerivePass
//
//  Created by Indutnyy, Fedor on 1/14/17.
//
//  This software is licensed under the MIT License.
//  Copyright © 2017 Indutny Inc. All rights reserved.
//

#import "ApplicationsTableViewController.h"
#import "ApplicationTableViewCell.h"
#import "EditApplicationTableViewController.h"
#import "Helpers.h"

#import <MobileCoreServices/UTCoreTypes.h>
#import <dispatch/dispatch.h>  // dispatch_queue_t

@interface ApplicationsTableViewController ()

@property(strong, nonatomic) IBOutlet UIBarButtonItem* addButtonItem;
@property(strong) UIImage* iconCopy;

@end

@implementation ApplicationsTableViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  self.iconCopy = [UIImage imageNamed:@"Copy"];

  self.navigationItem.rightBarButtonItems =
      @[ self.addButtonItem, self.editButtonItem ];

  self.dataController.delegate = self;

  [self onDataUpdate];
}


- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];

  // We may came here from the "Add" screen
  // reload apps in this case
  [self onDataUpdate];

  [self.tableView reloadData];
  [self.navigationController setNavigationBarHidden:NO];
}


- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
}


- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
  [super setEditing:editing animated:animated];
  if (editing) {
    self.navigationItem.rightBarButtonItems = @[ self.editButtonItem ];
  } else {
    self.navigationItem.rightBarButtonItems =
        @[ self.addButtonItem, self.editButtonItem ];
  }
}


- (void)onDataUpdate {
  self.applications = [NSMutableArray array];
  for (Application* obj in self.dataController.applications) {
    if (obj.removed) continue;
    [self.applications insertObject:obj atIndex:self.applications.count];
  }

  [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView*)tableView
    numberOfRowsInSection:(NSInteger)section {
  return self.applications.count;
}


- (UITableViewCell*)tableView:(UITableView*)tableView
        cellForRowAtIndexPath:(NSIndexPath*)indexPath {
  UITableViewCell* cell =
      [tableView dequeueReusableCellWithIdentifier:@"ApplicationCell"
                                      forIndexPath:indexPath];

  Application* info = self.applications[indexPath.row];

  cell.textLabel.text = info.plaintextDomain;
  cell.detailTextLabel.text = info.plaintextLogin;
  cell.accessoryView = [[UIImageView alloc] initWithImage:self.iconCopy];

  return cell;
}


- (void)reindex {
  // Update indexes
  int index = 0;
  for (Application* obj in self.applications) {
    if (obj.index != index) {
      obj.index = index;
      obj.changed_at = [NSDate date];
    }
    index++;
  }
}


- (void)tableView:(UITableView*)tableView
    moveRowAtIndexPath:(NSIndexPath*)fromIndexPath
           toIndexPath:(NSIndexPath*)toIndexPath {
  Application* info = self.applications[fromIndexPath.row];
  [self.applications removeObjectAtIndex:fromIndexPath.row];
  [self.applications insertObject:info atIndex:toIndexPath.row];

  [self reindex];

  [self.dataController save];
}


- (void)tableView:(UITableView*)tableView
    commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
     forRowAtIndexPath:(NSIndexPath*)indexPath {
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    Application* app = self.applications[indexPath.row];
    [self.applications removeObjectAtIndex:indexPath.row];

    [self.dataController deleteApplication:app];
    [self reindex];
    [self.dataController save];
    [tableView reloadData];
  }
}


- (void)tableView:(UITableView*)tableView
    didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  if (tableView.isEditing) return;

  __block ApplicationTableViewCell* cell =
      [self.tableView cellForRowAtIndexPath:indexPath];
  Application* info = self.applications[indexPath.row];

  self.view.userInteractionEnabled = NO;
  [cell.activityIndicator startAnimating];
  cell.activityIndicator.center = cell.accessoryView.center;

  __block UIView* accessory = cell.accessoryView;
  cell.accessoryView = nil;

  void (^completion)(NSString*) = ^(NSString* password) {
    UIPasteboard* pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = password;

    __block UIAlertController* alert = [UIAlertController
        alertControllerWithTitle:@""
                         message:@"Password copied to clipboard"
                  preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:alert
                       animated:YES
                     completion:^{
                       [cell.activityIndicator stopAnimating];
                       cell.accessoryView = accessory;
                     }];

    dispatch_queue_t queue = dispatch_get_main_queue();
    dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC);
    dispatch_after(when, queue, ^{
      [alert dismissViewControllerAnimated:YES completion:nil];
      [self.view setUserInteractionEnabled:YES];
    });
  };

  [Helpers passwordFromMaster:self.masterPassword
                       domain:info.plaintextDomain
                        login:info.plaintextLogin
                  andRevision:info.plainRevision
               withCompletion:completion];
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender {
  EditApplicationTableViewController* c = [segue destinationViewController];
  c.dataController = self.dataController;

  if ([[segue identifier] isEqualToString:@"ToEditApplication"]) {
    UITableViewCell* cell = sender;
    NSInteger row = [self.tableView indexPathForCell:cell].row;

    c.title = @"Edit";
    c.info = self.applications[row];
    c.insertIndex = 0;
  } else if ([[segue identifier] isEqualToString:@"ToAddApplication"]) {
    c.title = @"Add";
    c.info = nil;
    c.insertIndex = (int32_t)self.applications.count;
  }
}

@end
