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

#import <MobileCoreServices/UTCoreTypes.h>

#import <dispatch/dispatch.h>  // dispatch_queue_t

#include "src/common.h"

@interface ApplicationsTableViewController ()

@property(strong, nonatomic) IBOutlet UIBarButtonItem* addButtonItem;

@end

@implementation ApplicationsTableViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  self.navigationItem.rightBarButtonItems =
      @[ self.addButtonItem, self.editButtonItem ];

  self.dataController.delegate = self;

  [self onDataUpdate];
}


- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self.tableView reloadData];
  [self.navigationController setNavigationBarHidden:NO];
}


- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
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

  return cell;
}


- (void)reindex {
  // Update indexes
  int index = 0;
  for (Application* obj in self.applications) {
    obj.index = index++;
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

  ApplicationTableViewCell* cell =
      [self.tableView cellForRowAtIndexPath:indexPath];
  Application* info = self.applications[indexPath.row];
  __block const char* master = self.masterPassword.UTF8String;
  const char* domain = info.plaintextDomain.UTF8String;
  const char* login = info.plaintextLogin.UTF8String;

  self.view.userInteractionEnabled = NO;
  [cell.activityIndicator startAnimating];
  cell.activityIndicator.center =
      CGPointMake(cell.center.x, cell.contentView.center.y);

  dispatch_queue_t queue =
      dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

  dispatch_async(queue, ^{
    scrypt_state_t state;
    __block char* out;

    __block char tmp[1024];
    if (info.plainRevision <= 1) {
      snprintf(tmp, sizeof(tmp), "%s/%s", domain, login);
    } else {
      snprintf(tmp, sizeof(tmp), "%s/%s#%d", domain, login, info.plainRevision);
    }

    state.n = kDeriveScryptN;
    state.r = kDeriveScryptR;
    state.p = kDeriveScryptP;

    out = derive(&state, master, tmp);
    NSAssert(out != NULL, @"Failed to derive");

    dispatch_async(dispatch_get_main_queue(), ^{
      UIPasteboard* pasteboard = [UIPasteboard generalPasteboard];

      // 5 minute expiration
      NSDate* expire = [NSDate dateWithTimeIntervalSinceNow:5 * 60];

      [pasteboard setItems:@[ @{
                    (NSString*)
                    kUTTypeUTF8PlainText : [NSString stringWithUTF8String:out]
                  } ]
                   options:@{
                     UIPasteboardOptionLocalOnly : [NSNumber numberWithInt:0],
                     UIPasteboardOptionExpirationDate : expire
                   }];

      pasteboard.string = [NSString stringWithUTF8String:out];

      free(out);

      [cell.activityIndicator stopAnimating];
      UIAlertController* alert = [UIAlertController
          alertControllerWithTitle:@""
                           message:@"Password copied to clipboard"
                    preferredStyle:UIAlertControllerStyleAlert];
      [self presentViewController:alert animated:YES completion:nil];

      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC),
                     dispatch_get_main_queue(), ^(void) {
                       [alert dismissViewControllerAnimated:YES completion:nil];
                       [self.view setUserInteractionEnabled:YES];
                     });
    });
  });
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender {
  if ([[segue identifier] isEqualToString:@"ToEditApplication"]) {
    EditApplicationTableViewController* c = [segue destinationViewController];

    UITableViewCell* cell = sender;
    NSInteger row = [self.tableView indexPathForCell:cell].row;

    c.title = @"Edit";
    c.info = self.applications[row];
    c.dataController = self.dataController;
  }
}


- (IBAction)onAdd:(id)sender {
  Application* info = [self.dataController allocApplication];

  info.plaintextDomain = @"gmail.com";
  info.plaintextLogin = @"my username";
  info.plainRevision = 1;
  info.index = (int)self.applications.count;

  [self.applications insertObject:info atIndex:self.applications.count];
  [self.dataController pushApplication:info];
  [self.dataController save];

  [self.tableView reloadData];
}

@end
