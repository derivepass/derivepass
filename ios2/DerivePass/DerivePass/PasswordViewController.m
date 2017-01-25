//
//  ViewController.m
//  DerivePass
//
//  Created by Indutnyy, Fedor on 1/13/17.
//
//  This software is licensed under the MIT License.
//  Copyright © 2017 Indutny Inc. All rights reserved.
//

#import "PasswordViewController.h"
#import "ApplicationDataController.h"
#import "ApplicationsTableViewController.h"
#import "Helpers.h"

#import <QuartzCore/QuartzCore.h>
#import <dispatch/dispatch.h>  // dispatch_queue_t

static NSString* const kMasterPlaceholder = @"Master Password";
static NSString* const kConfirmPlaceholder = @"Confirm Password";

@interface PasswordViewController ()

@property(weak, nonatomic) IBOutlet UITextField* masterPassword;
@property(weak, nonatomic) IBOutlet UILabel* emojiLabel;
@property(weak, nonatomic) IBOutlet UILabel* emojiConfirmationLabel;
@property(weak, nonatomic) IBOutlet UIActivityIndicatorView* spinner;

@property(strong) ApplicationDataController* dataController;

@end

@implementation PasswordViewController {
  NSString* confirming_;
  NSString* masterAESOrigin_;
  NSData* masterAES_;
  NSData* masterMAC_;
  uint64_t baton_;
}


- (void)viewDidLoad {
  [super viewDidLoad];

  self.dataController = [[ApplicationDataController alloc] init];
  [self.navigationController setNavigationBarHidden:YES];

  NSUserDefaults* def = [NSUserDefaults standardUserDefaults];
  if ([def boolForKey:@"seenTutorial"]) return;

  // Do asynchronously to prevent black bar at the top
  dispatch_async(dispatch_get_main_queue(), ^{
    [self performSegueWithIdentifier:@"ToTutorial" sender:self];
  });
}


- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self reset];
  [self.navigationController setNavigationBarHidden:YES];
}


- (void)reset {
  confirming_ = nil;
  self.emojiLabel.text = kDefaultEmoji;
  self.emojiConfirmationLabel.text = kDefaultEmoji;
  self.emojiConfirmationLabel.alpha = 0.0;
  self.masterPassword.text = @"";
  self.masterPassword.placeholder = kMasterPlaceholder;
  self.masterPassword.returnKeyType = UIReturnKeyDone;
}


- (void)protectedDataWillBecomeUnavailable {
  [self reset];
}


- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
}


- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender {
  if ([[segue identifier] isEqualToString:@"ToApplications"]) {
    ApplicationsTableViewController* c = [segue destinationViewController];
    c.dataController = self.dataController;
    c.masterPassword = self.masterPassword.text;
  }
}


- (IBAction)onPasswordChange:(id)sender {
  NSString* emoji = [Helpers passwordToEmoji:self.masterPassword.text];
  if (confirming_)
    self.emojiConfirmationLabel.text = emoji;
  else
    self.emojiLabel.text = emoji;

  if (self.masterPassword.text.length != 0) [self computeHashEarly];
}


- (void)computeHashEarly {
  if (confirming_) return;

  // Currently computing
  if ((baton_ & 1) == 1) return;

  dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, 500 * NSEC_PER_MSEC);
  baton_ += 2;
  uint64_t baton = baton_;
  dispatch_after(when, dispatch_get_main_queue(), ^{
    if (baton != baton_) return;

    [self computeAESKey:nil];
  });
}


- (void)computeAESKey:(void (^)(NSData* aes, NSData* mac))completion {
  dispatch_queue_t queue =
      dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

  __block NSString* origin = self.masterPassword.text;

  // Cached already
  if (masterAESOrigin_ == origin) {
    if (completion != nil) completion(masterAES_, masterMAC_);
    return;
  }

  // Wait for current computation to finish
  if ((baton_ & 1) == 1) {
    dispatch_async(queue, ^{
      dispatch_async(dispatch_get_main_queue(), ^{
        [self computeAESKey:completion];
      });
    });
    return;
  }

  baton_ |= 1;
  [Helpers passwordToAESAndMACKey:origin
                   withCompletion:^(NSData* aes, NSData* mac) {
                     baton_ ^= 1;

                     masterAES_ = aes;
                     masterMAC_ = mac;
                     masterAESOrigin_ = origin;

                     if (completion != nil) completion(aes, mac);
                   }];
}


- (IBAction)onSubmitPassword:(id)sender {
  __block BOOL after_confirmation = NO;
  if (confirming_) {
    if (![self.masterPassword.text isEqualToString:confirming_]) {
      UITextField* f = self.masterPassword;

      CABasicAnimation* a = [CABasicAnimation animationWithKeyPath:@"position"];
      [a setDuration:0.1];
      [a setRepeatCount:2];
      [a setAutoreverses:YES];
      [a setFromValue:[NSValue valueWithCGPoint:CGPointMake(f.center.x - 5,
                                                            f.center.y)]];
      [a setToValue:[NSValue valueWithCGPoint:CGPointMake(f.center.x + 5,
                                                          f.center.y)]];
      [f.layer addAnimation:a forKey:@"position"];
      return;
    }
    after_confirmation = YES;
    [self hideConfirmation:nil];
  }

  self.dataController.masterHash = self.emojiLabel.text;
  if (self.dataController.applications.count == 0) {
    if (!after_confirmation) return [self onEmojiTap:self];
  }

  UIBlurEffect* effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
  UIVisualEffectView* effectView = [[UIVisualEffectView alloc] init];
  effectView.frame = self.view.frame;

  // Do not blur things out if we already know the hash
  if (![masterAESOrigin_ isEqualToString:self.masterPassword.text]) {
    [UIView animateWithDuration:0.25
                     animations:^{
                       effectView.effect = effect;
                     }];

    [self.view addSubview:effectView];
    [self.view bringSubviewToFront:self.spinner];
    [self.spinner startAnimating];
  }

  self.view.userInteractionEnabled = NO;
  [self computeAESKey:^(NSData* aes, NSData* mac) {
    self.view.userInteractionEnabled = YES;
    [self.spinner stopAnimating];
    [UIView animateWithDuration:0.1
        animations:^{
          effectView.effect = nil;
        }
        completion:^(BOOL finished) {
          [effectView removeFromSuperview];
        }];

    self.dataController.cryptor.AESKey = aes;
    self.dataController.cryptor.MACKey = mac;

    [self performSegueWithIdentifier:@"ToApplications" sender:self];
  }];
}


- (void)hideConfirmation:(void (^)())completion {
  if (confirming_ == nil) {
    if (completion != nil) completion();
    return;
  }

  UILabel* original = self.emojiLabel;
  UILabel* conf = self.emojiConfirmationLabel;

  self.masterPassword.text = confirming_;
  self.masterPassword.placeholder = kMasterPlaceholder;
  self.masterPassword.returnKeyType = UIReturnKeyDone;
  confirming_ = nil;

  [UIView animateWithDuration:0.3
      animations:^{
        conf.center = original.center;
        conf.alpha = 0.0;
      }
      completion:^(BOOL finished) {
        if (completion != nil) completion();
      }];
}


- (IBAction)onEmojiTap:(id)sender {
  if (confirming_) {
    [self hideConfirmation:nil];
    return;
  }

  UILabel* original = self.emojiLabel;
  UILabel* conf = self.emojiConfirmationLabel;


  // No transition when master password is empty
  if (self.masterPassword.text.length == 0) return;

  conf.center = original.center;
  confirming_ = self.masterPassword.text;

  self.masterPassword.text = @"";
  self.masterPassword.placeholder = kConfirmPlaceholder;
  self.masterPassword.returnKeyType = UIReturnKeyNext;

  conf.text = kDefaultEmoji;
  [UIView animateWithDuration:0.3
                   animations:^() {
                     conf.center = CGPointMake(
                         conf.center.x,
                         conf.center.y + conf.frame.size.height * 1.2);
                     conf.alpha = 1.0;
                   }];
}

@end
