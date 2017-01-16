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

#import <CommonCrypto/CommonDigest.h>
#import <QuartzCore/QuartzCore.h>
#import <dispatch/dispatch.h>  // dispatch_queue_t

#include <stdint.h>
#include <string.h>

#include "src/common.h"

#define ARRAY_SIZE(a) (sizeof(a) / sizeof((a)[0]))

static const char* kScryptDomain = "derivepass/key";
static NSString* const kDefaultEmoji = @"😬";
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
  NSString* masterHashOrigin_;
  NSString* masterHash_;
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
  confirming_ = nil;
  self.emojiLabel.text = kDefaultEmoji;
  self.emojiConfirmationLabel.text = kDefaultEmoji;
  self.emojiConfirmationLabel.alpha = 0.0;
  self.masterPassword.text = @"";
  self.masterPassword.placeholder = kMasterPlaceholder;
  self.masterPassword.returnKeyType = UIReturnKeyDone;
  [self.navigationController setNavigationBarHidden:YES];
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
  // NOTE: Inspired by some unknown application on the internet
  static char* smile[] = {
      "😀",    "😃",      "😄",    "😆", "😅",    "😂",    "☺️", "😊",
      "😇",    "🙂",   "🙃", "😉", "😌",    "😍",    "😘",      "😗",
      "😙",    "😚",      "😋",    "😜", "😝",    "😛",    "🤑",   "🤗",
      "🤓", "😎",      "😏",    "😒", "😞",    "😔",    "😟",      "😕",
      "🙁", "☹️", "😣",    "😖", "😫",    "😩",    "😤",      "😬",
      "😡",    "😶",      "😐",    "😑", "😯",    "😦",    "😧",      "😮",
      "😲",    "😵",      "😳",    "😨", "😰",    "😢",    "😥", "😁",
      "😭",    "😓",      "😪",    "😴", "🙄", "🤔", "😠",      "🤐",
      "😷",    "🤒",   "🤕", "😈", "👿",    "👻",    "💀",      "☠️",
      "👽",    "👾",      "🤖", "🎃", "😺",    "😸",    "😹",      "😻",
      "😼",    "😽",      "😿",    "😾"};
  static char* gesture[] = {"👐", "🙌",      "👏",    "🙏",    "👍", "👎", "👊",
                            "✊", "✌️", "🤘", "👌",    "👈", "👉", "👆",
                            "👇", "☝️", "✋",    "🖖", "👋", "💪"};
  static char* animal[] = {
      "🐶", "🐱",    "🐭",    "🐹", "🐰",    "🐻",    "🐼",   "🐨", "🐯", "🦁",
      "🐮", "🐷",    "🐽",    "🐵", "🐒",    "🐔",    "🐧",   "🐦", "🐤", "🐣",
      "🐥", "🐺",    "🐗",    "🐴", "🦄", "🐝",    "🐛",   "🐌", "🐚", "🐞",
      "🐜", "🕷", "🐢",    "🐍", "🦂", "🦀", "🐙",   "🐠", "🐟", "🐡",
      "🐬", "🐳",    "🐋",    "🐊", "🐆",    "🐅",    "🐃",   "🐂", "🐄", "🐪",
      "🐫", "🐘",    "🐎",    "🐖", "🐐",    "🐏",    "🐑",   "🐕", "🐩", "🐈",
      "🐓", "🦃", "🕊", "🐇", "🐁",    "🐀",    "🐿"};
  static char* food[] = {
      "🍏", "🍎", "🍐",      "🍊", "🍋", "🍌",    "🍉", "🍇", "🍓",    "🍈",    "🍒",
      "🍑", "🍍", "🍅",      "🍆", "🌽", "🌶", "🍠", "🌰", "🍯",    "🍞",    "🧀",
      "🍳", "🍤", "🍗",      "🍖", "🍕", "🌭", "🍔", "🍟", "🌮", "🌯", "🍝",
      "🍜", "🍲", "🍥",      "🍣", "🍱", "🍛",    "🍚", "🍙", "🍘",    "🍢",    "🍡",
      "🍧", "🍨", "🍦",      "🍰", "🎂", "🍮",    "🍭", "🍬", "🍫",    "🍿", "🍩",
      "🍪", "🍼", "☕️", "🍵", "🍶", "🍺",    "🍻", "🍷", "🍸",    "🍹",    "🍾"};
  static char* object[] = {
      "⌚️", "📱",      "💻",       "⌨️", "🖥",   "🖨", "🖱",
      "🖲",   "🕹",   "🗜",    "💾",      "💿",      "📼",    "📷",
      "🗑",   "🎞",   "📞",       "☎️", "📟",      "📠",    "📺",
      "📻",      "🎙",   "⏱",       "⌛️", "📡",      "🔋",    "🔌",
      "💡",      "🔦",      "🕯",    "🎥",      "🛢",   "💵",    "💴",
      "💶",      "💷",      "💳",       "💎",      "⚖️", "🔧",    "🔨",
      "🔩",      "⚙️", "🔫",       "💣",      "🔪",      "🗡", "🚬",
      "🔮",      "📿",   "💈",       "⚗️", "🔭",      "🔬",    "🕳",
      "💊",      "💉",      "🌡",    "🚽",      "🚰",      "🛁",    "🛎",
      "🗝",   "🚪",      "🛋",    "🛏",   "🖼",   "🛍", "🎁",
      "🎈",      "🎀",      "🎉",       "✉️", "📦",      "🏷", "📫",
      "📯",      "📜",      "📆",       "📅",      "📇",      "🗃", "🗄",
      "📋",      "📂",      "🗞",    "📓",      "📖",      "🔗",    "📎",
      "📐",      "📌",      "🏳️", "🌈",      "✂️", "🖌", "✏️",
      "🔍",      "🔒",      "🍴"};

  NSString* value = [((UITextField*)sender)text];
  const char* utf8value = value.UTF8String;

  // No password - display default emoji
  if (value.length == 0) {
    if (confirming_)
      self.emojiConfirmationLabel.text = kDefaultEmoji;
    else
      self.emojiLabel.text = kDefaultEmoji;
    return;
  }

  unsigned char digest[CC_SHA256_DIGEST_LENGTH];

  CC_SHA256(utf8value, (CC_LONG)strlen(utf8value), digest);

  static char** alphabet[] = {smile, gesture, animal, food, object};
  static unsigned int alphabet_size[] = {ARRAY_SIZE(smile), ARRAY_SIZE(gesture),
                                         ARRAY_SIZE(animal), ARRAY_SIZE(food),
                                         ARRAY_SIZE(object)};

  uint64_t fingerprint =
      digest[4] | (digest[5] << 8) | (digest[6] << 16) | (digest[7] << 24);
  fingerprint <<= 32;
  fingerprint |=
      digest[0] | (digest[1] << 8) | (digest[2] << 16) | (digest[3] << 24);

  char emoji_fingerprint[128];
  char* p = emoji_fingerprint;
  int len = sizeof(emoji_fingerprint);
  for (unsigned int i = 0; i < ARRAY_SIZE(alphabet); i++) {
    unsigned int idx = fingerprint % alphabet_size[i];
    fingerprint /= alphabet_size[i];

    int n = snprintf(p, len, "%s", alphabet[i][idx]);
    len -= n;
    p += n;
  }

  NSString* res = [NSString stringWithUTF8String:emoji_fingerprint];
  if (confirming_)
    self.emojiConfirmationLabel.text = res;
  else
    self.emojiLabel.text = res;

  [self computeHashEarly];
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

    [self computeHash:nil];
  });
}


- (void)computeHash:(void (^)(NSString*))completion {
  dispatch_queue_t queue =
      dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

  __block NSString* origin = self.masterPassword.text;

  // Cached already
  if (masterHashOrigin_ == origin) {
    if (completion != nil) completion(masterHash_);
    return;
  }

  // Wait for current computation to finish
  if ((baton_ & 1) == 1) {
    dispatch_async(queue, ^{
      dispatch_async(dispatch_get_main_queue(), ^{
        [self computeHash:completion];
      });
    });
    return;
  }

  baton_ |= 1;
  dispatch_async(queue, ^{
    scrypt_state_t state;
    __block char* out;

    state.n = kDeriveScryptN;
    state.r = kDeriveScryptR;
    state.p = kDeriveScryptP;

    out = derive(&state, origin.UTF8String, kScryptDomain);
    NSAssert(out != NULL, @"Failed to derive");

    dispatch_async(dispatch_get_main_queue(), ^{
      baton_ ^= 1;

      masterHash_ = [NSString stringWithUTF8String:out];
      masterHashOrigin_ = origin;
      free(out);

      if (completion != nil) completion(masterHash_);
    });
  });
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

  UIBlurEffect* effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
  UIVisualEffectView* effectView =
      [[UIVisualEffectView alloc] initWithEffect:effect];
  effectView.frame = self.view.frame;
  effectView.alpha = 0.0;

  [UIView animateWithDuration:0.1
                   animations:^{
                     effectView.alpha = 1.0;
                   }];

  // Do not blur things out if we already know the hash
  if (![masterHashOrigin_ isEqualToString:self.masterPassword.text]) {
    [self.view addSubview:effectView];
    [self.view bringSubviewToFront:self.spinner];
    [self.spinner startAnimating];
  }

  self.view.userInteractionEnabled = NO;
  [self computeHash:^(NSString* hash) {
    self.view.userInteractionEnabled = YES;
    [self.spinner stopAnimating];
    [UIView animateWithDuration:0.1
        animations:^{
          effectView.alpha = 0.0;
        }
        completion:^(BOOL finished) {
          [effectView removeFromSuperview];
        }];

    self.dataController.masterHash = hash;
    if (self.dataController.applications.count == 0) {
      if (!after_confirmation) return [self onEmojiTap:self];
    }

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
