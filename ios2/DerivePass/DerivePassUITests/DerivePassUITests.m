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

  // Put setup code here. This method is called before the invocation of each
  // test method in the class.

  // In UI tests it is usually best to stop immediately when a failure occurs.
  self.continueAfterFailure = NO;
  // UI tests must launch the application that they test. Doing this in setup
  // will make sure it happens for each test method.
  [[[XCUIApplication alloc] init] launch];

  // In UI tests it’s important to set the initial state - such as interface
  // orientation - required for your tests before they run. The setUp method is
  // a good place to do this.
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each
  // test method in the class.
  [super tearDown];
}

- (void)testExample {
  uint64_t r;
  int err = SecRandomCopyBytes(kSecRandomDefault, 8, (void*)&r);
  XCTAssertEqual(err, 0);

  NSString* master = [NSString stringWithFormat:@"test/%llu", r];

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

  for (int i = 0; i < kApplicationCount; i++) {
    elem = [tablesQuery.cells
               containingType:XCUIElementTypeStaticText
                   identifier:[NSString stringWithFormat:@"%d-test.com", i]]
               .element;
    [elem tap];

    XCUIElement* notification =
        app.staticTexts[@"Password copied to clipboard"];
    NSPredicate* pred = [NSPredicate predicateWithFormat:@"exists == 1"];
    [self expectationForPredicate:pred
              evaluatedWithObject:notification
                          handler:nil];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];

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
}

@end
