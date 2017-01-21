//
//  DerivePassTests.m
//  DerivePassTests
//
//  Created by Indutnyy, Fedor on 1/20/17.
//  Copyright © 2017 Indutny Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "AESCryptor.h"
#import "Helpers.h"

@interface DerivePassTests : XCTestCase

@end

@implementation DerivePassTests

- (void)setUp {
  [super setUp];
}


- (void)tearDown {
  [super tearDown];
}


- (void)testEmoji {
  XCTAssertEqualObjects([Helpers passwordToEmoji:@""], kDefaultEmoji);
  XCTAssertEqualObjects([Helpers passwordToEmoji:@"hello"],
                        @"😻"
                        @"👇🐛🍳🔫");
}


- (void)testAESKeyGeneration {
  XCTestExpectation *completion =
      [self expectationWithDescription:@"AES key completion"];
  [Helpers
      passwordToAESKey:@"hello"
        withCompletion:^(NSData *key) {
          uint8_t bytes[] = {0xdb, 0xc6, 0x2b, 0x97, 0xc8, 0x6f, 0x90, 0x61,
                             0xe6, 0xf1, 0x78, 0x7b, 0xb4, 0xc6, 0x69, 0x12,
                             0x5b, 0x4f, 0x68, 0xea, 0xcb, 0x6e, 0xa9, 0x1e,
                             0x8e, 0x04, 0xd7, 0x98, 0x02, 0x20, 0x66, 0xf5};
          NSData *expected = [NSData dataWithBytes:bytes length:sizeof(bytes)];
          XCTAssertEqualObjects(key, expected);
          [completion fulfill];
        }];

  [self waitForExpectationsWithTimeout:5.0
                               handler:^(NSError *_Nullable error) {
                                 XCTAssertNil(error);
                               }];
}


- (void)testAppPasswordGeneration {
  XCTestExpectation *completion1 =
      [self expectationWithDescription:@"App password completion"];
  [Helpers passwordFromMaster:@"hello"
                       domain:@"gmail.com"
                        login:@"test"
                  andRevision:1
               withCompletion:^(NSString *password) {
                 XCTAssertEqualObjects(password, @"b4r5cMNCdcLJZ5aroCo5CGM7");
                 [completion1 fulfill];
               }];

  XCTestExpectation *completion2 =
      [self expectationWithDescription:@"App password completion #2"];
  [Helpers passwordFromMaster:@"hello"
                       domain:@"gmail.com"
                        login:@"test"
                  andRevision:2
               withCompletion:^(NSString *password) {
                 XCTAssertEqualObjects(password, @".Tzt73chSH7xCo_dvz_eraC_");
                 [completion2 fulfill];
               }];

  [self waitForExpectationsWithTimeout:5.0
                               handler:^(NSError *_Nullable error) {
                                 XCTAssertNil(error);
                               }];
}


- (void)testAppPasswordGenerationWithARC {
  XCTestExpectation *completion =
      [self expectationWithDescription:@"App password completion"];

  NSString *master = [NSString stringWithUTF8String:"hello"];
  NSString *domain = [NSString stringWithUTF8String:"gmail.com"];
  NSString *login = [NSString stringWithUTF8String:"test"];
  [Helpers passwordFromMaster:master
                       domain:domain
                        login:login
                  andRevision:1
               withCompletion:^(NSString *password) {
                 XCTAssertEqualObjects(password, @"b4r5cMNCdcLJZ5aroCo5CGM7");
                 [completion fulfill];
               }];
  master = nil;
  domain = nil;
  login = nil;


  [self waitForExpectationsWithTimeout:5.0
                               handler:^(NSError *_Nullable error) {
                                 XCTAssertNil(error);
                               }];
}


- (void)testAESCycle {
  AESCryptor *cryptor = [[AESCryptor alloc] init];

  uint8_t bytes1[] = {0xe3, 0x3b, 0x22, 0x21, 0xd5, 0x1d, 0xe5, 0xb5,
                      0x92, 0x17, 0xd9, 0xea, 0x05, 0x83, 0x25, 0xa5,
                      0x1d, 0x3b, 0x32, 0x93, 0x06, 0xcd, 0x1c, 0x98,
                      0x61, 0xaa, 0x5e, 0x17, 0xee, 0xef, 0x16, 0x71};
  XCTAssertEqual(sizeof(bytes1), kCryptorKeySize);
  NSData *key1 = [NSData dataWithBytes:bytes1 length:sizeof(bytes1)];

  cryptor.AESKey = key1;

  // Regular cycles
  XCTAssertEqualObjects([cryptor decrypt:[cryptor encrypt:@"hello"]], @"hello");

  NSString *longStr = @"very long string that should span several AES blocks";
  XCTAssertEqualObjects([cryptor decrypt:[cryptor encrypt:longStr]], longStr);

  XCTAssertEqual([cryptor decryptNumber:[cryptor encryptNumber:13589]], 13589);

  XCTAssertEqualObjects([cryptor decrypt:[cryptor encrypt:longStr]], longStr);

  // Decrypt failure
  uint8_t bytes2[] = {0xf3, 0x3b, 0x22, 0x21, 0xd5, 0x1d, 0xe5, 0xb5,
                      0x92, 0x17, 0xd9, 0xfa, 0x05, 0x83, 0x25, 0xa5,
                      0x1d, 0x3b, 0x32, 0xf3, 0x06, 0xcd, 0x1c, 0x98,
                      0x61, 0xaa, 0x5e, 0xf7, 0xee, 0xef, 0x16, 0x71};
  XCTAssertEqual(sizeof(bytes2), kCryptorKeySize);
  NSData *key2 = [NSData dataWithBytes:bytes2 length:sizeof(bytes2)];

  NSString *encrypted = [cryptor encrypt:@"ohai"];
  cryptor.AESKey = key2;
  NSString *decrypted = [cryptor decrypt:encrypted];
  cryptor.AESKey = key1;
  XCTAssertNotEqualObjects(decrypted, @"ohai");

  encrypted = [cryptor encryptNumber:42];
  cryptor.AESKey = key2;
  int32_t decryptedNum = [cryptor decryptNumber:encrypted];
  cryptor.AESKey = key1;
  XCTAssertNotEqual(decryptedNum, 42);
}

@end
