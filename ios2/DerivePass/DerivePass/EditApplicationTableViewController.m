//
//  EditApplicationTableViewController.m
//  DerivePass
//
//  Created by Indutnyy, Fedor on 1/14/17.
//
//  This software is licensed under the MIT License.
//  Copyright © 2017 Indutny Inc. All rights reserved.
//

#import "EditApplicationTableViewController.h"

@interface EditApplicationTableViewController ()

@property(weak, nonatomic) IBOutlet UIBarButtonItem *saveButtonItem;
@property(weak, nonatomic) IBOutlet UITextField *domainField;
@property(weak, nonatomic) IBOutlet UITextField *loginField;
@property(weak, nonatomic) IBOutlet UITextField *revisionField;

@end

@implementation EditApplicationTableViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  self.navigationItem.rightBarButtonItem = self.saveButtonItem;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.domainField.text = [self.info valueForKey:@"domain"];
  self.loginField.text = [self.info valueForKey:@"login"];
  self.revisionField.text =
      [NSString stringWithFormat:@"%@", [self.info valueForKey:@"revision"]];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
}


// TODO(indutny): move to data controller
- (IBAction)onSave:(id)sender {
  [self.info setValue:self.domainField.text forKey:@"domain"];
  [self.info setValue:self.loginField.text forKey:@"login"];

  int rev = atoi([self.revisionField.text UTF8String]);
  [self.info setValue:[NSNumber numberWithInt:rev] forKey:@"revision"];

  [self.info setValue:[NSDate date] forKey:@"changed_at"];
  [self.dataController save];

  [self.navigationController popViewControllerAnimated:YES];
}


- (IBAction)onFieldEdit:(id)sender {
  BOOL valid = YES;

  self.domainField.layer.borderWidth = 0.0;
  self.loginField.layer.borderWidth = 0.0;
  self.revisionField.layer.borderWidth = 0.0;

  if (self.domainField.text.length == 0) {
    valid = NO;

    self.domainField.layer.borderColor = [[UIColor redColor] CGColor];
    self.domainField.layer.borderWidth = 1.0;
  }

  if (self.loginField.text.length == 0) {
    valid = NO;

    self.loginField.layer.borderColor = [[UIColor redColor] CGColor];
    self.loginField.layer.borderWidth = 1.0;
  }

  if (self.revisionField.text.length == 0 ||
      atoi(self.revisionField.text.UTF8String) < 1) {
    valid = NO;

    self.revisionField.layer.borderColor = [[UIColor redColor] CGColor];
    self.revisionField.layer.borderWidth = 1.0;
  }

  self.saveButtonItem.enabled = valid;
}

@end
