//
//  DeriveViewController.m
//  DerivePass
//
//  Created by Fedor Indutny on 08/06/15.
//  Copyright (c) 2015 Fedor Indutny. All rights reserved.
//

#import <dispatch/dispatch.h>  // dispatch_queue_t

#import "common.h"

#import "DeriveViewController.h"


static const CFStringRef kAccountName = @"master@secret";


@interface DeriveViewController ()

@end

@implementation DeriveViewController {
  BOOL use_touch_id;
}

- (void) viewDidLoad {
  [super viewDidLoad];
  [self.DomainTextField becomeFirstResponder];
}


- (void) didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
}


- (IBAction) onDeriveClick: (id) sender {
  UITextField* master_field = self.MasterSecretTextField;
  __block NSString* passphrase = master_field.text;
  NSString* check_passphrase = self.RepeatSecretTextField.text;

  // Check that passwords match
  if (![passphrase isEqualToString:check_passphrase]) {
    master_field.layer.borderColor = [[UIColor redColor] CGColor];
    master_field.layer.borderWidth = 1.0;
    [master_field becomeFirstResponder];
    return;
  }

  master_field.layer.borderWidth = 0.0;
  __block NSString* domain = self.DomainTextField.text;

  dispatch_queue_t queue = dispatch_get_global_queue(
      DISPATCH_QUEUE_PRIORITY_DEFAULT,
      0);

  [self.view setUserInteractionEnabled: NO];
  [self.ActivityIndicator startAnimating];

  dispatch_async(queue, ^{
    scrypt_state_t state;
    __block char* out;

    state.n = kDeriveScryptN;
    state.r = kDeriveScryptR;
    state.p = kDeriveScryptP;

    out = derive(&state, passphrase.UTF8String, domain.UTF8String);
    NSAssert(out != NULL, @"Failed to derive");

    dispatch_async(dispatch_get_main_queue(), ^{
      NSString* derived =
          [[NSString alloc] initWithCString: out
                                   encoding: NSUTF8StringEncoding];
      free(out);

      [self.ActivityIndicator stopAnimating];
      [self.view setUserInteractionEnabled: YES];

      self.DerivedKeyTextField.text = derived;
      [self.DerivedKeyTextField becomeFirstResponder];
    });
  });
}


- (IBAction) onDomainEnter: (id) sender {
  if ([self.MasterSecretTextField.text length] != 0)
    [self onRepeatSecretEnter: sender];
  else
    [self.MasterSecretTextField becomeFirstResponder];
}


- (IBAction) onMasterEnter: (id) sender {
  [self.RepeatSecretTextField becomeFirstResponder];
}


- (IBAction) onRepeatSecretEnter: (id) sender {
  [self onDeriveClick: sender];
}


- (IBAction) onClearClick: (id) sender {
  self.DomainTextField.text = @"";
  self.DerivedKeyTextField.text = @"";
  self.MasterSecretTextField.text = @"";
  self.RepeatSecretTextField.text = @"";
}

@end
