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
#import "ValidationErrorButton.h"

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


static BOOL check_non_empty(NSString* v, NSString** msg) {
  if (v.length == 0) {
    *msg = @"Can\'t be empty";
    return NO;
  }
  return YES;
}


static BOOL check_is_number(NSString* v, NSString** msg) {
  if (v.length == 0) {
    *msg = @"Can\'t be empty";
    return NO;
  }

  if (atoi(v.UTF8String) < 1) {
    *msg = @"Must be a number > 1";
    return NO;
  }

  return YES;
}


// TODO(indutny): move to data controller
- (IBAction)onSave:(id)sender {
  BOOL valid = YES;

  UITextField* fields[] = {self.domainField, self.loginField,
                           self.revisionField};
  BOOL(*verifiers[])
  (NSString*, NSString**) = {check_non_empty, check_non_empty, check_is_number};

  for (int i = 0; i < 3; i++) {
    UITextField* field = fields[i];
    NSString* msg = nil;

    field.rightViewMode = UITextFieldViewModeNever;
    field.rightView = nil;

    if (verifiers[i](field.text, &msg)) continue;

    valid = NO;
    field.rightView = [[ValidationErrorButton alloc] initWithMessage:msg
                                             andParentViewController:self];
    field.rightViewMode = UITextFieldViewModeAlways;
  }

  if (!valid) return;

  if (self.info == nil) {
    self.info = [self.dataController allocApplication];
    self.info.index = self.insertIndex;
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

  field.rightViewMode = UITextFieldViewModeNever;
  field.rightView = nil;
}

@end
