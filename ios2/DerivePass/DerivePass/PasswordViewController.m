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

#include <stdint.h>
#include <string.h>

#define ARRAY_SIZE(a) (sizeof(a) / sizeof((a)[0]))

@interface PasswordViewController ()

@property(weak, nonatomic) IBOutlet UITextField* masterPassword;
@property(weak, nonatomic) IBOutlet UILabel* emojiLabel;

@end

@implementation PasswordViewController


- (void)viewDidLoad {
  [super viewDidLoad];
  [self.navigationController setNavigationBarHidden:YES];
}


- (void)viewWillAppear:(BOOL)animated {
  self.emojiLabel.text = @"😬";
  self.masterPassword.text = @"";
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
      "😀",    "😃",    "😄",    "😆",      "😅",      "😂", "🤣", "☺️",
      "😊",    "😇",    "🙂", "🙃",   "😉",      "😌", "😍",    "😘",
      "😗",    "😙",    "😚",    "😋",      "😜",      "😝", "😛",    "🤑",
      "🤗", "🤓", "😎",    "🤠",   "😏",      "😒", "😞",    "😔",
      "😟",    "😕",    "🙁", "☹️", "😣",      "😖", "😫",    "😩",
      "😤",    "😠",    "😡",    "😶",      "😐",      "😑", "😯",    "😦",
      "😧",    "😮",    "😲",    "😵",      "😳",      "😨", "😰",    "😢",
      "😥",    "🤤", "😭",    "😓",      "😪",      "😴", "🙄", "🤔",
      "🤥", "😬",    "🤐", "🤢",   "🤧",   "😷", "🤒", "🤕",
      "😈",    "👿",    "👻",    "💀",      "☠️", "👽", "👾",    "🤖",
      "🎃",    "😺",    "😸",    "😹",      "😻",      "😼", "😽",    "😿",
      "😾"};
  static char* gesture[] = {"👐",      "🙌", "👏",    "🙏",    "🤝", "👍",
                            "👎",      "👊", "✊",    "🤜", "🤞", "✌️",
                            "🤘",   "👌", "👈",    "👉",    "👆",    "👇",
                            "☝️", "✋", "🖖", "👋",    "🤙", "💪"};
  static char* animal[] = {
      "🐶",    "🐱",    "🐭",    "🐹",    "🐰",    "🦊", "🐻", "🐼",    "🐨", "🐯",
      "🦁", "🐮",    "🐷",    "🐽",    "🐵",    "🐒",    "🐔", "🐧",    "🐦", "🐤",
      "🐣",    "🐥",    "🦆", "🦅", "🦉", "🦇", "🐺", "🐗",    "🐴", "🦄",
      "🐝",    "🐛",    "🦋", "🐌",    "🐚",    "🐞",    "🐜", "🕷", "🐢", "🐍",
      "🦎", "🦂", "🦀", "🦑", "🐙",    "🦐", "🐠", "🐟",    "🐡", "🐬",
      "🦈", "🐳",    "🐋",    "🐊",    "🐆",    "🐅",    "🐃", "🐂",    "🐄", "🦌",
      "🐪",    "🐫",    "🐘",    "🦏", "🦍", "🐎",    "🐖", "🐐",    "🐏", "🐑",
      "🐕",    "🐩",    "🐈",    "🐓",    "🦃", "🕊", "🐇", "🐁",    "🐀", "🐿"};
  static char* food[] = {
      "🍏",      "🍎",    "🍐",    "🍊",    "🍋",    "🍌",    "🍉",    "🍇",    "🍓",
      "🍈",      "🍒",    "🍑",    "🍍",    "🥝", "🥑", "🍅",    "🍆",    "🥒",
      "🥕",   "🌽",    "🌶", "🥔", "🍠",    "🌰",    "🥜", "🍯",    "🥐",
      "🍞",      "🥖", "🧀", "🥚", "🍳",    "🥓", "🥞", "🍤",    "🍗",
      "🍖",      "🍕",    "🌭", "🍔",    "🍟",    "🥙", "🌮", "🌯", "🥗",
      "🥘",   "🍝",    "🍜",    "🍲",    "🍥",    "🍣",    "🍱",    "🍛",    "🍚",
      "🍙",      "🍘",    "🍢",    "🍡",    "🍧",    "🍨",    "🍦",    "🍰",    "🎂",
      "🍮",      "🍭",    "🍬",    "🍫",    "🍿", "🍩",    "🍪",    "🥛", "🍼",
      "☕️", "🍵",    "🍶",    "🍺",    "🍻",    "🥂", "🍷",    "🥃", "🍸",
      "🍹",      "🍾"};
  static char* object[] = {
      "⌚️", "📱",      "💻",    "⌨️",  "🖥",   "🖨",   "🖱",
      "🖲",   "🕹",   "🗜", "💾",       "💿",      "📼",      "📷",
      "🎥",      "🎞",   "📞",    "☎️",  "📟",      "📠",      "📺",
      "📻",      "🎙",   "⏱",    "⌛️",  "📡",      "🔋",      "🔌",
      "💡",      "🔦",      "🕯", "🗑",    "🛢",   "💵",      "💴",
      "💶",      "💷",      "💳",    "💎",       "⚖️", "🔧",      "🔨",
      "🔩",      "⚙️", "🔫",    "💣",       "🔪",      "🗡",   "🚬",
      "🔮",      "📿",   "💈",    "⚗️",  "🔭",      "🔬",      "🕳",
      "💊",      "💉",      "🌡", "🚽",       "🚰",      "🛁",      "🛎",
      "🗝",   "🚪",      "🛋", "🛏",    "🖼",   "🛍",   "🛒",
      "🎁",      "🎈",      "🎀",    "🎉",       "✉️", "📦",      "🏷",
      "📫",      "📯",      "📜",    "📆",       "📅",      "📇",      "🗃",
      "🗄",   "📋",      "📂",    "🗞",    "📓",      "📖",      "🔗",
      "📎",      "📐",      "📌",    "🏳️", "🌈",      "✂️", "🖌",
      "✏️", "🔍",      "🔒",    "🥄",    "🍴"};

  NSString* value = [((UITextField*)sender)text];
  const char* utf8value = [value UTF8String];

  // No password - display default emoji
  if ([value length] == 0) {
    self.emojiLabel.text = @"😬";
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

  self.emojiLabel.text = [NSString stringWithUTF8String:emoji_fingerprint];
}


- (IBAction)onSubmitPassword:(id)sender {
  [self performSegueWithIdentifier:@"ToApplications" sender:self];
}

@end
