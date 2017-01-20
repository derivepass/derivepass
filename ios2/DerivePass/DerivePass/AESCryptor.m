//
//  ApplicationDataController+Cryptor.m
//  DerivePass
//
//  Created by Indutnyy, Fedor on 1/19/17.
//
//  This software is licensed under the MIT License.
//  Copyright © 2017 Indutny Inc. All rights reserved.
//

#import "AESCryptor.h"

static NSString* kDecryptFailureString = @"<decrypt failure>";

@implementation AESCryptor

- (uint8_t)hexDigit:(char)digit withError:(BOOL*)err {
  if ('0' <= digit && digit <= '9')
    return digit - '0';
  else if ('a' <= digit && digit <= 'f')
    return (digit - 'a') + 0xa;
  else if ('A' <= digit && digit <= 'F')
    return (digit - 'A') + 0xa;
  *err = YES;
  return 0;
}


- (NSData*)fromHex:(NSString*)str {
  const char* bytes = str.UTF8String;
  int len = (int)str.length;

  if (len % 2 != 0) {
    NSLog(@"Invalid HEX string");
    return nil;
  }

  NSMutableData* res = [NSMutableData dataWithLength:len / 2];
  uint8_t* o = (uint8_t*)res.mutableBytes;
  for (int i = 0; i < len; i += 2) {
    char h = bytes[i];
    char l = bytes[i + 1];

    BOOL err = NO;
    o[i / 2] = ([self hexDigit:h withError:&err] << 4) |
               [self hexDigit:l withError:&err];
    if (err) {
      NSLog(@"Invalid HEX digit");
      return nil;
    }
  }
  return res;
}


- (NSString*)toHex:(NSData*)data {
  NSMutableString* res = [NSMutableString stringWithCapacity:data.length * 2];

  const uint8_t* bytes = (const uint8_t*)data.bytes;
  for (int i = 0; i < (int)data.length; i++) {
    [res appendFormat:@"%02x", bytes[i]];
  }

  return res;
}


- (NSString*)encrypt:(NSString*)str {
  NSAssert(self.AESKey.length == kCryptorKeySize, @"Invalid AES key length");

  NSMutableData* res =
      [NSMutableData dataWithLength:kCCBlockSizeAES128 * 2 + str.length];
  NSAssert(res != nil, @"Failed to allocated mutable output for encrypt");

  // Set IV
  int err = SecRandomCopyBytes(kSecRandomDefault, kCCBlockSizeAES128,
                               res.mutableBytes);
  NSAssert(err == 0, @"SecRandomCopyBytes failure");

  size_t bytes;
  CCCryptorStatus st;
  st = CCCrypt(kCCEncrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding,
               self.AESKey.bytes, self.AESKey.length, res.bytes,
               (void*)str.UTF8String, str.length,
               res.mutableBytes + kCCBlockSizeAES128,
               res.length - kCCBlockSizeAES128, &bytes);
  NSAssert(st == kCCSuccess, @"CCCrypt encrypt failure");

  res.length = kCCBlockSizeAES128 + bytes;

  return [self toHex:res];
}


- (NSString*)decrypt:(NSString*)str {
  NSAssert(self.AESKey.length == kCryptorKeySize, @"Invalid AES key length");

  NSData* data = [self fromHex:str];
  if (data == nil) return kDecryptFailureString;
  if (data.length <= kCCBlockSizeAES128) {
    NSLog(@"No data, but just IV in encrypted string");
    return kDecryptFailureString;
  }

  NSMutableData* res = [NSMutableData dataWithLength:data.length];
  NSAssert(res != nil, @"Failed to allocated mutable output for decrypt");

  size_t bytes;
  CCCryptorStatus err;
  err = CCCrypt(
      kCCDecrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding, self.AESKey.bytes,
      self.AESKey.length, data.bytes, data.bytes + kCCBlockSizeAES128,
      data.length - kCCBlockSizeAES128, res.mutableBytes, res.length, &bytes);
  if (err != kCCSuccess) {
    NSLog(@"Failed to decrypt data, err=%d", err);
    return kDecryptFailureString;
  }

  return [NSString stringWithFormat:@"%.*s", (int)bytes, res.bytes];
}


- (NSString*)encryptNumber:(int32_t)num {
  return [self encrypt:[NSString stringWithFormat:@"%d", num]];
}


- (int32_t)decryptNumber:(NSString*)str {
  NSString* res = [self decrypt:str];
  if (res == kDecryptFailureString) return 1;
  return atoi(res.UTF8String);
}

@end
