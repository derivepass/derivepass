//
//  ApplicationDataController+Cryptor.h
//  DerivePass
//
//  Created by Indutnyy, Fedor on 1/19/17.
//
//  This software is licensed under the MIT License.
//  Copyright © 2017 Indutny Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ApplicationDataController.h"

@interface ApplicationDataController (Cryptor)

- (NSString*)_encrypt:(NSString*)str;
- (NSString*)_decrypt:(NSString*)str;

- (NSString*)_encryptNumber:(int32_t)num;
- (int32_t)_decryptNumber:(NSString*)str;

@end
