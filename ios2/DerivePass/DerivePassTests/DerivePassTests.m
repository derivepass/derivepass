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
      passwordToAESAndMACKey:@"hello"
              withCompletion:^(NSData *aes, NSData *mac) {
                uint8_t aes_bytes[] = {0xdb, 0xc6, 0x2b, 0x97, 0xc8, 0x6f, 0x90,
                                       0x61, 0xe6, 0xf1, 0x78, 0x7b, 0xb4, 0xc6,
                                       0x69, 0x12, 0x5b, 0x4f, 0x68, 0xea, 0xcb,
                                       0x6e, 0xa9, 0x1e, 0x8e, 0x04, 0xd7, 0x98,
                                       0x02, 0x20, 0x66, 0xf5};
                NSData *expected_aes =
                    [NSData dataWithBytes:aes_bytes length:sizeof(aes_bytes)];
                XCTAssertEqualObjects(aes, expected_aes);

                uint8_t mac_bytes[] = {
                    0x8a, 0x41, 0x93, 0x94, 0x8b, 0xcd, 0x65, 0x34, 0x76, 0xba,
                    0x6e, 0xc4, 0x1b, 0x28, 0x02, 0xed, 0x41, 0xd4, 0x3e, 0x03,
                    0x2f, 0x87, 0x90, 0x9a, 0xf0, 0xc4, 0x3e, 0x0c, 0x2d, 0x25,
                    0xaa, 0x83, 0x1c, 0xb2, 0x1a, 0xe0, 0x82, 0x54, 0xf3, 0x09,
                    0x4c, 0x81, 0xe1, 0xe2, 0x57, 0xf5, 0x26, 0xf8, 0xed, 0xbb,
                    0xdb, 0x60, 0x99, 0xcf, 0xb0, 0xa0, 0xc5, 0x55, 0x6c, 0x0b,
                    0x22, 0x8a, 0x96, 0xf2};
                NSData *expected_mac =
                    [NSData dataWithBytes:mac_bytes length:sizeof(mac_bytes)];
                XCTAssertEqualObjects(mac, expected_mac);

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

  uint8_t aes_bytes1[] = {0xe3, 0x3b, 0x22, 0x21, 0xd5, 0x1d, 0xe5, 0xb5,
                          0x92, 0x17, 0xd9, 0xea, 0x05, 0x83, 0x25, 0xa5,
                          0x1d, 0x3b, 0x32, 0x93, 0x06, 0xcd, 0x1c, 0x98,
                          0x61, 0xaa, 0x5e, 0x17, 0xee, 0xef, 0x16, 0x71};
  uint8_t mac_bytes1[] = {
      0x8a, 0x41, 0x93, 0x94, 0x8b, 0xcd, 0x65, 0x34, 0x76, 0xba, 0x6e,
      0xc4, 0x1b, 0x28, 0x02, 0xed, 0x41, 0xd4, 0x3e, 0x03, 0x2f, 0x87,
      0x90, 0x9a, 0xf0, 0xc4, 0x3e, 0x0c, 0x2d, 0x25, 0xaa, 0x83, 0x1c,
      0xb2, 0x1a, 0xe0, 0x82, 0x54, 0xf3, 0x09, 0x4c, 0x81, 0xe1, 0xe2,
      0x57, 0xf5, 0x26, 0xf8, 0xed, 0xbb, 0xdb, 0x60, 0x99, 0xcf, 0xb0,
      0xa0, 0xc5, 0x55, 0x6c, 0x0b, 0x22, 0x8a, 0x96, 0xf2};
  XCTAssertEqual(sizeof(aes_bytes1), kCryptorKeySize);
  XCTAssertEqual(sizeof(mac_bytes1), kCryptorMacKeySize);
  NSData *aes1 = [NSData dataWithBytes:aes_bytes1 length:sizeof(aes_bytes1)];
  NSData *mac1 = [NSData dataWithBytes:mac_bytes1 length:sizeof(mac_bytes1)];

  cryptor.AESKey = aes1;
  cryptor.MACKey = mac1;

  // Regular cycles
  XCTAssertEqualObjects([cryptor decrypt:[cryptor encrypt:@"hello"]], @"hello");

  NSString *longStr = @"very long string that should span several AES blocks";
  XCTAssertEqualObjects([cryptor decrypt:[cryptor encrypt:longStr]], longStr);

  XCTAssertEqual([cryptor decryptNumber:[cryptor encryptNumber:13589]], 13589);

  XCTAssertEqualObjects([cryptor decrypt:[cryptor encrypt:longStr]], longStr);

  // IV must be random
  XCTAssertNotEqualObjects([cryptor encrypt:longStr],
                           [cryptor encrypt:longStr]);

  // Decrypt failure
  uint8_t aes_bytes2[] = {0xf3, 0x3b, 0x22, 0x21, 0xd5, 0x1d, 0xe5, 0xb5,
                          0x92, 0x17, 0xd9, 0xfa, 0x05, 0x83, 0x25, 0xa5,
                          0x1d, 0x3b, 0x32, 0xf3, 0x06, 0xcd, 0x1c, 0x98,
                          0x61, 0xaa, 0x5e, 0xf7, 0xee, 0xef, 0x16, 0x71};
  uint8_t mac_bytes2[] = {
      0xfa, 0x41, 0x93, 0x94, 0x8b, 0xcd, 0x65, 0x34, 0x76, 0xba, 0xfe,
      0xc4, 0x1b, 0x28, 0x02, 0xed, 0x41, 0xd4, 0x3e, 0x03, 0xff, 0x87,
      0x90, 0x9a, 0xf0, 0xc4, 0x3e, 0x0c, 0x2d, 0x25, 0xfa, 0x83, 0x1c,
      0xb2, 0x1a, 0xe0, 0x82, 0x54, 0xf3, 0x09, 0xfc, 0x81, 0xe1, 0xe2,
      0x57, 0xf5, 0x26, 0xf8, 0xed, 0xbb, 0xfb, 0x60, 0x99, 0xcf, 0xb0,
      0xa0, 0xc5, 0x55, 0x6c, 0x0b, 0xf2, 0x8a, 0x96, 0xf2};
  XCTAssertEqual(sizeof(aes_bytes2), kCryptorKeySize);
  XCTAssertEqual(sizeof(mac_bytes2), kCryptorMacKeySize);
  NSData *aes2 = [NSData dataWithBytes:aes_bytes2 length:sizeof(aes_bytes2)];
  NSData *mac2 = [NSData dataWithBytes:mac_bytes2 length:sizeof(mac_bytes2)];

  // Wrong AES key
  NSString *encrypted = [cryptor encrypt:@"ohai"];
  cryptor.AESKey = aes2;
  NSString *decrypted = [cryptor decrypt:encrypted];
  cryptor.AESKey = aes1;
  XCTAssertNotEqualObjects(decrypted, @"<decrypt failure>");

  // Wrong MAC key
  cryptor.MACKey = mac2;
  decrypted = [cryptor decrypt:encrypted];
  cryptor.MACKey = mac1;
  XCTAssertEqualObjects(decrypted, @"<decrypt failure>");

  // Wrong AES key (number)
  encrypted = [cryptor encryptNumber:42];
  cryptor.AESKey = aes2;
  int32_t decryptedNum = [cryptor decryptNumber:encrypted];
  cryptor.AESKey = aes1;
  XCTAssertNotEqual(decryptedNum, 1);

  // Wrong MAC key (number)
  cryptor.MACKey = mac2;
  decryptedNum = [cryptor decryptNumber:encrypted];
  cryptor.MACKey = mac1;
  XCTAssertEqual(decryptedNum, 1);

  // Compatibility
  cryptor.AESKey = aes1;
  cryptor.MACKey = mac1;
  NSString *encrypted_old =
      @"7bc85a06f6cbc315e27696c4e648c46e217c12946299522583773907c6bf32b4";
  XCTAssertEqualObjects([cryptor decrypt:encrypted_old], @"ohai");
}

@end
