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
  self.domainField.text = self.info.domain;
  self.loginField.text = self.info.login;
  self.revisionField.text =
      [NSString stringWithFormat:@"%d", self.info.revision];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
}


// TODO(indutny): move to data controller
- (IBAction)onSave:(id)sender {
  self.info.domain = self.domainField.text;
  self.info.login = self.loginField.text;

  int rev = atoi([self.revisionField.text UTF8String]);
  self.info.revision = rev;

  self.info.changed_at = [NSDate date];
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
