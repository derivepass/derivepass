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
#import <Foundation/Foundation.h>

static int kCryptorKeySize = kCCKeySizeAES256;

@interface AESCryptor : NSObject

@property NSData* AESKey;

- (NSString*)encrypt:(NSString*)str;
- (NSString*)decrypt:(NSString*)str;

- (NSString*)encryptNumber:(int32_t)num;
- (int32_t)decryptNumber:(NSString*)str;

@end
