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
#import "ApplicationsTableViewController.h"

#import <CommonCrypto/CommonDigest.h>
#import <QuartzCore/QuartzCore.h>

#include <stdint.h>
#include <string.h>

#define ARRAY_SIZE(a) (sizeof(a) / sizeof((a)[0]))

static NSString* const kDefaultEmoji = @"😬";
static NSString* const kMasterPlaceholder = @"Master Password";
static NSString* const kConfirmPlaceholder = @"Confirm Password";

@interface PasswordViewController ()

@property(weak, nonatomic) IBOutlet UITextField* masterPassword;
@property(weak, nonatomic) IBOutlet UILabel* emojiLabel;
@property(weak, nonatomic) IBOutlet UILabel* emojiConfirmationLabel;

@end

@implementation PasswordViewController {
  NSString* confirming_;
}


- (void)viewDidLoad {
  [super viewDidLoad];
  [self.navigationController setNavigationBarHidden:YES];
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
      "😲",    "😵",      "😳",    "😨", "😰",    "😢",    "😥",      "🤤",
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
}


- (IBAction)onSubmitPassword:(id)sender {
  if (confirming_) {
    if (self.masterPassword.text != confirming_) {
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
    
    self.view.userInteractionEnabled = NO;
    [self hideConfirmation:^() {
      self.view.userInteractionEnabled = YES;
      [self performSegueWithIdentifier:@"ToApplications" sender:self];
    }];
    return;
  }
  
  [self performSegueWithIdentifier:@"ToApplications" sender:self];
}


- (void) hideConfirmation: (void (^)()) completion {
  if (confirming_ == nil)
    return completion();
  
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
                   } completion:^(BOOL finished) {
                     completion();
                   }];
}


- (IBAction)onEmojiTap:(id)sender {
  if (confirming_) {
    [self hideConfirmation: nil];
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
