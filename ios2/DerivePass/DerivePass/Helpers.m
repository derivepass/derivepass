//
//  Helpers.m
//  DerivePass
//
//  Created by Indutnyy, Fedor on 1/20/17.
//
//  This software is licensed under the MIT License.
//  Copyright © 2017 Indutny Inc. All rights reserved.
//

#import "Helpers.h"
#import "AESCryptor.h"

#import <CommonCrypto/CommonDigest.h>
#import <dispatch/dispatch.h>  // dispatch_queue_t

#include <stdint.h>
#include <string.h>

#include "src/common.h"


#define ARRAY_SIZE(a) (sizeof(a) / sizeof((a)[0]))

static const char* kScryptAES = "derivepass/aes";

@implementation Helpers

+ (NSString*)passwordToEmoji:(NSString*)password {
  // NOTE: Inspired by some unknown application on the internet
  static char* smile[] = {
      "😀",    "😃",      "😄",    "😆", "😅",    "😂",    "☺️", "😊",
      "😇",    "🙂",   "🙃", "😉", "😌",    "😍",    "😘",      "😗",
      "😙",    "😚",      "😋",    "😜", "😝",    "😛",    "🤑",   "🤗",
      "🤓", "😎",      "😏",    "😒", "😞",    "😔",    "😟",      "😬",
      "🙁", "☹️", "😣",    "😖", "😫",    "😩",    "😤",      "😕",
      "😡",    "😶",      "😐",    "😑", "😯",    "😦",    "😧",      "😮",
      "😲",    "😵",      "😳",    "😨", "😰",    "😢",    "😥",      "😁",
      "😭",    "😓",      "😪",    "😴", "🙄", "🤔", "😠",      "🤐",
      "😷",    "🤒",   "🤕", "😈", "👿",    "👻",    "💀",      "☠️",
      "👽",    "👾",      "🤖", "🎃", "😺",    "😸",    "😹",      "😻",
      "😼",    "😽",      "😿",    "😾"};
  static char* gesture[] = {"👐", "👌",      "👏", "🙏",    "👍", "👎", "👊",
                            "✊", "✌️", "🙌", "🤘", "👈", "👉", "👆",
                            "👇", "☝️", "✋", "🖖", "👋", "💪"};
  static char* animal[] = {
      "🐶",    "🐱",    "🐭",    "🐹", "🐰",    "🐻",    "🐼",   "🐨", "🐯", "🦁",
      "🦃", "🐷",    "🐮",    "🐵", "🐒",    "🐔",    "🐧",   "🐦", "🐤", "🐣",
      "🐥",    "🐺",    "🐗",    "🐴", "🦄", "🐝",    "🐛",   "🐌", "🐚", "🐞",
      "🐜",    "🕷", "🐢",    "🐍", "🦂", "🦀", "🐙",   "🐠", "🐟", "🐡",
      "🐬",    "🐳",    "🐋",    "🐊", "🐆",    "🐅",    "🐃",   "🐂", "🐄", "🐪",
      "🐫",    "🐘",    "🐎",    "🐖", "🐐",    "🐏",    "🐑",   "🐕", "🐩", "🐈",
      "🐓",    "🐽",    "🕊", "🐇", "🐁",    "🐀",    "🐿"};
  static char* food[] = {
      "🍏", "🍎", "🍐",      "🍊", "🍋", "🍌",    "🍉", "🍇", "🍓",    "🍈",    "🍒",
      "🍑", "🍍", "🍅",      "🍆", "🌽", "🌶", "🍠", "🌰", "🍯",    "🍞",    "🧀",
      "🍳", "🍤", "🍗",      "🍖", "🍕", "🌭", "🍔", "🍟", "🌮", "🌯", "🍝",
      "🍜", "🍲", "🍥",      "🍣", "🍱", "🍛",    "🍚", "🍙", "🍘",    "🍢",    "🍡",
      "🍧", "🍨", "🍦",      "🍺", "🎂", "🍮",    "🍭", "🍬", "🍫",    "🍿", "🍩",
      "🍪", "🍰", "☕️", "🍵", "🍶", "🍼",    "🍻", "🍷", "🍸",    "🍹",    "🍾"};
  static char* object[] = {
      "⌚️", "📱",      "💻",       "⌨️", "🖥",   "🖨", "🖱",
      "🖲",   "🕹",   "🗜",    "💾",      "💿",      "📼",    "📷",
      "🗑",   "🎞",   "📞",       "☎️", "📟",      "📠",    "📺",
      "📻",      "🎙",   "⏱",       "⌛️", "📡",      "🔋",    "🔌",
      "💡",      "🔦",      "🕯",    "💷",      "🛢",   "💵",    "💴",
      "🎥",      "💶",      "💳",       "💎",      "⚖️", "🔧",    "🔨",
      "🔩",      "⚙️", "🔫",       "💣",      "🔪",      "🗡", "🚬",
      "🔮",      "📿",   "💈",       "⚗️", "🔭",      "🔬",    "🕳",
      "💊",      "💉",      "🌡",    "🚽",      "🚰",      "🛁",    "🛎",
      "🗝",   "🚪",      "🛋",    "🛏",   "🖼",   "🛍", "🎁",
      "🎈",      "🎀",      "🎉",       "✉️", "📦",      "🏷", "📫",
      "📯",      "📜",      "📆",       "📅",      "📇",      "🗃", "🗄",
      "📋",      "📂",      "🗞",    "📓",      "📖",      "🔗",    "📎",
      "📐",      "📌",      "🏳️", "🌈",      "✂️", "🖌", "✏️",
      "🔍",      "🔒",      "🍴"};

  NSString* value = [NSString stringWithFormat:@"derivepass/%@", password];
  const char* utf8value = value.UTF8String;

  // No password - display default emoji
  if (password.length == 0) return kDefaultEmoji;

  unsigned char digest[CC_SHA512_DIGEST_LENGTH];
  CC_SHA512(utf8value, (CC_LONG)strlen(utf8value), digest);

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
  return res;
}


+ (void)passwordToAESKey:(NSString*)password
          withCompletion:(void (^)(NSData*))completion {
  __block NSString* origin = password;

  dispatch_queue_t queue =
      dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  dispatch_async(queue, ^{
    scrypt_state_t state;

    state.n = kDeriveScryptN;
    state.r = kDeriveScryptR;
    state.p = kDeriveScryptP;

    uint8_t aes_key[kCryptorKeySize];
    int err;

    err = scrypt_state_init(&state);
    assert(err == 0);

    scrypt(&state, (const uint8_t*)origin.UTF8String, origin.length,
           (const uint8_t*)kScryptAES, sizeof(kScryptAES) - 1, aes_key,
           sizeof(aes_key));
    scrypt_state_destroy(&state);

    __block NSData* out_data =
        [NSData dataWithBytes:aes_key length:sizeof(aes_key)];

    dispatch_async(dispatch_get_main_queue(), ^{
      completion(out_data);
    });
  });
}


+ (void)passwordFromMaster:(NSString*)master
                    domain:(NSString*)domain
                     login:(NSString*)login
               andRevision:(int32_t)revision
            withCompletion:(void (^)(NSString*))completion {
  __block NSString* masterCopy = master;
  __block NSString* domainCopy = domain;
  __block NSString* loginCopy = login;

  dispatch_queue_t queue =
      dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

  dispatch_async(queue, ^{
    scrypt_state_t state;
    __block char* out;

    char tmp[1024];
    if (revision <= 1) {
      snprintf(tmp, sizeof(tmp), "%s/%s", domainCopy.UTF8String,
               loginCopy.UTF8String);
    } else {
      snprintf(tmp, sizeof(tmp), "%s/%s#%d", domainCopy.UTF8String,
               loginCopy.UTF8String, revision);
    }

    state.n = kDeriveScryptN;
    state.r = kDeriveScryptR;
    state.p = kDeriveScryptP;

    out = derive(&state, masterCopy.UTF8String, tmp);
    NSAssert(out != NULL, @"Failed to derive");

    dispatch_async(dispatch_get_main_queue(), ^{
      NSString* res = [NSString stringWithUTF8String:out];
      free(out);

      completion(res);
    });
  });
}

@end
