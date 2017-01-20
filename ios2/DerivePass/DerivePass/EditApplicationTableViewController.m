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

@property(weak, nonatomic) IBOutlet UIBarButtonItem* saveButtonItem;
@property(weak, nonatomic) IBOutlet UITextField* domainField;
@property(weak, nonatomic) IBOutlet UITextField* loginField;
@property(weak, nonatomic) IBOutlet UITextField* revisionField;

@end

@implementation EditApplicationTableViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  self.navigationItem.rightBarButtonItem = self.saveButtonItem;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];

  // "Add" screen
  if (self.info == nil) return;

  self.domainField.text = self.info.plaintextDomain;
  self.loginField.text = self.info.plaintextLogin;
  self.revisionField.text =
      [NSString stringWithFormat:@"%d", self.info.plainRevision];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
}


// TODO(indutny): move to data controller
- (IBAction)onSave:(id)sender {
  BOOL valid = YES;

  UITextField* fields[] = {self.domainField, self.loginField,
                           self.revisionField};
  BOOL (^verifiers[])
  (NSString*) = {^BOOL(NSString* v){
      return v.length != 0;
}
,
    ^BOOL(NSString* v) {
      return v.length != 0;
    },
    ^BOOL(NSString* v) {
      return v.length != 0 && atoi(v.UTF8String) >= 1;
    }
}
;

for (int i = 0; i < 3; i++) {
  UITextField* field = fields[i];

  field.layer.borderWidth = 0.0;

  if (verifiers[i](field.text)) continue;

  valid = NO;
  field.layer.borderColor = [[UIColor redColor] CGColor];
  field.layer.borderWidth = 1.0;
}

if (!valid) return;

if (self.info == nil) {
  self.info = [self.dataController allocApplication];
  [self.dataController pushApplication:self.info];
}

self.info.plaintextDomain = self.domainField.text;
self.info.plaintextLogin = self.loginField.text;

int rev = atoi([self.revisionField.text UTF8String]);
self.info.plainRevision = rev;

self.info.changed_at = [NSDate date];
[self.dataController save];

[self.navigationController popViewControllerAnimated:YES];
}


- (IBAction)onFieldEdit:(id)sender {
  UITextField* field = sender;

  field.layer.borderWidth = 0.0;
}

@end
