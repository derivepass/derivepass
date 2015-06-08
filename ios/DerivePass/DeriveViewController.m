//
//  DeriveViewController.m
//  DerivePass
//
//  Created by Fedor Indutny on 08/06/15.
//  Copyright (c) 2015 Fedor Indutny. All rights reserved.
//

#import <dispatch/dispatch.h>  // dispatch_queue_t
#import <LocalAuthentication/LAContext.h>
#import <Security/Security.h>

#import "common.h"

#import "DeriveViewController.h"


static const CFStringRef kAccountName = @"master@secret";


@interface DeriveViewController ()

@end

@implementation DeriveViewController {
  BOOL use_touch_id;
}

- (void) viewDidLoad {
  LAContext* la_context = [[LAContext alloc] init];

  LAPolicy policy = LAPolicyDeviceOwnerAuthenticationWithBiometrics;
  NSError* auth_error;

  use_touch_id = NO;

  NSString* reason =
      @"Would you like to use Touch ID to load and store Master secret";

  if ([la_context canEvaluatePolicy: policy error: &auth_error]) {
    [la_context evaluatePolicy: policy
               localizedReason: reason
                         reply: ^(BOOL success, NSError* error) {
                           use_touch_id = success;
                           if (success) {
                             NSLog(@"Using Touch ID");
                             [self loadMasterSecret];
                           } else {
                             NSLog(@"Not using Touch ID");
                           }
                         }];
  } else {
    NSLog(@"No luck with Touch ID");
  }
  [super viewDidLoad];
  [self.DomainTextField becomeFirstResponder];
}


- (void) didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
}


- (NSMutableDictionary*) getMasterSecretQuery {
  NSMutableDictionary* query = [NSMutableDictionary dictionaryWithCapacity: 4];

  query[(__bridge __strong id) kSecClass] =
      (__bridge id) kSecClassGenericPassword;
  query[(__bridge __strong id) kSecAttrAccount] =
      (__bridge id) kAccountName;

  return query;
}


- (void) loadMasterSecret {
  NSMutableDictionary* query = [self getMasterSecretQuery];

  OSStatus status;
  CFTypeRef result;

  query[(__bridge __strong id) kSecReturnData] = (__bridge id) kCFBooleanTrue;
  status = SecItemCopyMatching((__bridge CFDictionaryRef) query, &result);
  if (status == errSecItemNotFound)
    return;

  NSAssert(status == noErr, @"Some unexpected SecItemCopyMatching() error");

  __block NSString* secret =
      [[NSString alloc]  initWithData: (__bridge NSData*) result
                             encoding: NSUTF8StringEncoding];

  dispatch_async(dispatch_get_main_queue(), ^{
    self.MasterSecretTextField.text = secret;
  });
}


- (void) storeMasterSecret: (NSString*) secret {
  if (!use_touch_id)
    return;

  NSMutableDictionary* query = [self getMasterSecretQuery];

  OSStatus status;
  status = SecItemCopyMatching((__bridge CFDictionaryRef) query, NULL);

  if (status == noErr) {
    // Update existing item
    NSMutableDictionary* attrs =
        [NSMutableDictionary dictionaryWithCapacity: 10];
    attrs[(__bridge __strong id) kSecValueData] =
        [secret dataUsingEncoding: NSUTF8StringEncoding];
    attrs[(__bridge __strong id) kSecAttrModificationDate] = [NSDate date];

    status = SecItemUpdate((__bridge CFDictionaryRef) query,
                           (__bridge CFDictionaryRef) attrs);
    NSAssert(status == noErr, @"Some unexpected SecItemUpdate() error");
    return;
  }

  // Add new item
  NSAssert(status == errSecItemNotFound, @"SecItemCopyMatching() error");

  query[(__bridge __strong id) kSecAttrCreationDate] = [NSDate date];
  query[(__bridge __strong id) kSecAttrModificationDate] = [NSDate date];
  query[(__bridge __strong id) kSecValueData] =
      [secret dataUsingEncoding: NSUTF8StringEncoding];

  status = SecItemAdd((__bridge CFDictionaryRef) query, NULL);
  NSAssert(status == noErr, @"Some unexpected SecItemAdd() error");
}


- (IBAction) onDeriveClick: (id) sender {
  __block NSString* passphrase = self.MasterSecretTextField.text;
  __block NSString* domain = self.DomainTextField.text;

  dispatch_queue_t queue = dispatch_get_global_queue(
      DISPATCH_QUEUE_PRIORITY_DEFAULT,
      0);

  [self.view setUserInteractionEnabled: NO];
  [self.ActivityIndicator startAnimating];
  [self storeMasterSecret: passphrase];

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
    });
  });
}


- (IBAction)onDomainEnter: (id) sender {
  if ([self.MasterSecretTextField.text length] != 0)
    [self onMasterEnter: sender];
  else
    [self.MasterSecretTextField becomeFirstResponder];
}


- (IBAction)onMasterEnter: (id) sender {
  [self onDeriveClick: sender];
}

@end
