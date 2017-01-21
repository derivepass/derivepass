//
//  ApplicationDataController+Cryptor.h
//  DerivePass
//
//  Created by Indutnyy, Fedor on 1/19/17.
//
//  This software is licensed under the MIT License.
//  Copyright © 2017 Indutny Inc. All rights reserved.
//

#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonHMAC.h>
#import <Foundation/Foundation.h>

// AES key + HMAC key
static int kCryptorKeySize = kCCKeySizeAES256;
static int kCryptorMacKeySize = CC_SHA256_BLOCK_BYTES;

@interface AESCryptor : NSObject

@property NSData* AESKey;
@property NSData* MACKey;

- (NSString*)encrypt:(NSString*)str;
- (NSString*)decrypt:(NSString*)str;

- (NSString*)encryptNumber:(int32_t)num;
- (int32_t)decryptNumber:(NSString*)str;

@end
