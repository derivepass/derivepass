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

#import <CommonCrypto/CommonHMAC.h>

static NSString* kDecryptFailureString = @"<decrypt failure>";
static NSString* kAESCryptorV1Prefix = @"v1:";
static unsigned int kAESIVSize = kCCBlockSizeAES128;
static unsigned int kMACSize = CC_SHA256_DIGEST_LENGTH;

typedef enum { kAESCryptorV0, kAESCryptorV1 } AESCryptorDataVersion;

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


- (NSData*)fromHex:(NSString*)str getVersion:(AESCryptorDataVersion*)version {
  if ([str hasPrefix:kAESCryptorV1Prefix]) {
    *version = kAESCryptorV1;
    str = [str substringFromIndex:kAESCryptorV1Prefix.length];
  } else {
    *version = kAESCryptorV0;
  }

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


- (NSString*)toHex:(NSData*)data withVersion:(AESCryptorDataVersion)version {
  NSMutableString* res = [NSMutableString stringWithCapacity:data.length * 2];

  if (version == kAESCryptorV1) [res appendString:kAESCryptorV1Prefix];

  const uint8_t* bytes = (const uint8_t*)data.bytes;
  for (int i = 0; i < (int)data.length; i++) {
    [res appendFormat:@"%02x", bytes[i]];
  }

  return res;
}


- (void)hmac:(NSData*)data
        withLength:(NSUInteger)len
    andDestination:(void*)res {
  CCHmac(kCCHmacAlgSHA256, self.MACKey.bytes, self.MACKey.length, data.bytes,
         len, res);
}


- (NSString*)encrypt:(NSString*)str {
  NSAssert(self.AESKey.length == kCryptorKeySize, @"Invalid AES key length");

  // [iv] [string] [some possible alignment and padding] [digest]
  NSMutableData* res = [NSMutableData
      dataWithLength:kAESIVSize + str.length + kCCBlockSizeAES128 + kMACSize];
  NSAssert(res != nil, @"Failed to allocated mutable output for encrypt");

  void* iv = res.mutableBytes;
  void* content = res.mutableBytes + kAESIVSize;
  NSUInteger content_len = res.length - kAESIVSize - kMACSize;

  // Set IV
  int err = SecRandomCopyBytes(kSecRandomDefault, kAESIVSize, iv);
  if (err != 0) {
    NSLog(@"SecRandomCopyBytes failure");
    abort();
  }

  size_t bytes;
  CCCryptorStatus st;
  st = CCCrypt(kCCEncrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding,
               self.AESKey.bytes, self.AESKey.length, iv, (void*)str.UTF8String,
               str.length, content, content_len, &bytes);
  NSAssert(st == kCCSuccess, @"CCCrypt encrypt failure");

  // Encrypt-then-MAC
  void* digest = res.mutableBytes + kAESIVSize + bytes;
  [self hmac:res withLength:kAESIVSize + bytes andDestination:digest];
  res.length = kCCBlockSizeAES128 + bytes + kMACSize;

  return [self toHex:res withVersion:kAESCryptorV1];
}


- (NSString*)decrypt:(NSString*)str {
  NSAssert(self.AESKey.length == kCryptorKeySize, @"Invalid AES key length");

  AESCryptorDataVersion version;
  NSData* data = [self fromHex:str getVersion:&version];
  if (data == nil) return kDecryptFailureString;

  // Check MAC in v1
  if (version == kAESCryptorV1) {
    if (data.length <= kMACSize) {
      NSLog(@"No data, but just digest in encrypted string");
      return kDecryptFailureString;
    }

    NSData* head =
        [data subdataWithRange:NSMakeRange(0, data.length - kMACSize)];
    NSData* digest = [data
        subdataWithRange:NSMakeRange(head.length, data.length - head.length)];
    data = head;

    NSMutableData* actualDigest = [NSMutableData dataWithLength:kMACSize];

    [self hmac:data
            withLength:data.length
        andDestination:actualDigest.mutableBytes];
    if (digest != nil && ![actualDigest isEqualToData:digest]) {
      NSLog(@"Failed to decrypt data, digest mismatch");
      return kDecryptFailureString;
    }
  }

  if (data.length <= kCCBlockSizeAES128) {
    NSLog(@"No data, but just IV in encrypted string");
    return kDecryptFailureString;
  }

  NSMutableData* res = [NSMutableData dataWithLength:data.length];
  NSAssert(res != nil, @"Failed to allocated mutable output for decrypt");

  const void* iv = data.bytes;
  const void* content = data.bytes + kAESIVSize;
  NSUInteger content_len = data.length - kAESIVSize;

  size_t bytes;
  CCCryptorStatus err;
  err = CCCrypt(kCCDecrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding,
                self.AESKey.bytes, self.AESKey.length, iv, content, content_len,
                res.mutableBytes, res.length, &bytes);
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
