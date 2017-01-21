//
//  DerivePassUITests.m
//  DerivePassUITests
//
//  Created by Indutnyy, Fedor on 1/21/17.
//  Copyright © 2017 Indutny Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#include "scrypt.h"
#include "src/common.h"

static const int kApplicationCount = 3;

@interface DerivePassUITests : XCTestCase

@end

@implementation DerivePassUITests

- (void)setUp {
  [super setUp];
  self.continueAfterFailure = NO;
  [[[XCUIApplication alloc] init] launch];
}

- (void)tearDown {
  [super tearDown];
}

- (void)testMainFlow {
  uint64_t r;
  int err = SecRandomCopyBytes(kSecRandomDefault, 8, (void*)&r);
  XCTAssertEqual(err, 0);

  NSString* master = [NSString stringWithFormat:@"test/%llu", r];

  // Enter master password
  XCUIApplication* app = [[XCUIApplication alloc] init];
  XCUIElement* masterPasswordSecureTextField =
      app.secureTextFields[@"Master Password"];
  [masterPasswordSecureTextField tap];
  [masterPasswordSecureTextField typeText:master];

  XCUIElement* doneButton = app.buttons[@"Done"];
  [doneButton tap];

  XCUIElement* confirmPasswordSecureTextField =
      app.secureTextFields[@"Confirm Password"];
  [confirmPasswordSecureTextField typeText:master];
  [doneButton tap];

  XCUIElementQuery* tablesQuery = app.tables;
  XCUIElement* elem;

  // Create several applications with different domain name
  for (int i = 0; i < kApplicationCount; i++) {
    [app.navigationBars[@"Applications"].buttons[@"Add"] tap];

    elem = [[tablesQuery.cells containingType:XCUIElementTypeStaticText
                                   identifier:@"Domain"]
               childrenMatchingType:XCUIElementTypeTextField]
               .element;
    [elem tap];
    [elem typeText:[NSString stringWithFormat:@"%d-test.com", i]];

    elem = [[tablesQuery.cells containingType:XCUIElementTypeStaticText
                                   identifier:@"Login"]
               childrenMatchingType:XCUIElementTypeTextField]
               .element;
    [elem tap];
    [elem typeText:@"example"];

    elem = [[tablesQuery.cells containingType:XCUIElementTypeStaticText
                                   identifier:@"Revision"]
               childrenMatchingType:XCUIElementTypeTextField]
               .element;
    [elem tap];
    [elem typeText:@"3"];

    [app.navigationBars[@"Add"].buttons[@"Save"] tap];
  }

  // Tap on each of them and verify that copied password is correct
  NSPredicate* exists = [NSPredicate predicateWithFormat:@"exists == 1"];
  NSPredicate* notExists = [NSPredicate predicateWithFormat:@"exists == 0"];
  for (int i = 0; i < kApplicationCount; i++) {
    elem = [tablesQuery.cells
               containingType:XCUIElementTypeStaticText
                   identifier:[NSString stringWithFormat:@"%d-test.com", i]]
               .element;
    [elem tap];

    // Notification should flash and be gone
    XCUIElement* notification =
        app.staticTexts[@"Password copied to clipboard"];
    [self expectationForPredicate:exists
              evaluatedWithObject:notification
                          handler:nil];
    [self waitForExpectationsWithTimeout:30.0 handler:nil];
    [self expectationForPredicate:notExists
              evaluatedWithObject:notification
                          handler:nil];
    [self waitForExpectationsWithTimeout:30.0 handler:nil];


    // Generate expectation value
    scrypt_state_t state;

    state.n = kDeriveScryptN;
    state.r = kDeriveScryptR;
    state.p = kDeriveScryptP;

    NSString* domain = [NSString stringWithFormat:@"%d-test.com/example#13", i];

    NSString* expected =
        [NSString stringWithUTF8String:derive(&state, master.UTF8String,
                                              domain.UTF8String)];

    NSString* password = [UIPasteboard generalPasteboard].string;
    XCTAssertEqualObjects(password, expected);
  }

  // Get back to the main menu
  [[[[app.navigationBars[@"Applications"]
      childrenMatchingType:XCUIElementTypeButton] matchingIdentifier:@"Back"]
      elementBoundByIndex:0] tap];

  // Type master password again (this time once)
  [masterPasswordSecureTextField typeText:master];
  [masterPasswordSecureTextField typeText:@"\r"];

  // Check that it loads apps
  XCUIElement* domain = app.staticTexts[@"0-test.com"];
  [self expectationForPredicate:exists evaluatedWithObject:domain handler:nil];
  [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

@end
