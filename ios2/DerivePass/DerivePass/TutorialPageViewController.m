//
//  TutorialPageViewController.m
//  DerivePass
//
//  Created by Indutnyy, Fedor on 1/16/17.
//
//  This software is licensed under the MIT License.
//  Copyright © 2017 Indutny Inc. All rights reserved.
//

#import "TutorialPageViewController.h"
#import "TutorialFinalViewController.h"
#import "TutorialViewController.h"

#include <string.h>

#define ARRAY_SIZE(a) (sizeof(a) / sizeof((a)[0]))

@interface TutorialPageViewController ()

@property NSMutableArray<UIViewController *> *pages;

@end

@implementation TutorialPageViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.pages = [NSMutableArray array];

  NSArray<NSString *> *kTexts[] = {
    @[
      @"Welcome to DerivePass",
      @"This app\nsecurely creates passwords\nout of a single\nMaster Password",
      @"Master Password goes here"
    ],
    @[
      @"These Emojis represent your Master Password",
      @"Use them to check that you typed the right password"
    ],
    @[
      @"There are millions of different Emoji combinations",
      @"Each combo corresponds\nto 10^146 passwords",
      @"That's bigger than\nnumber of atoms\nin Universe",
      @"Your Master Password is safe\neven if someone has seen\nthe combo",
    ],
    @[ @"Increment revision\nif you need a new password" ],
    @[
      @"Tap application row\nto copy password",
      @"Passwords are computed\non the fly",
      @"No password is stored\nin the cloud",
      @"We store just\nAES-256 encrypted\napplication info\nand emojis"
    ]
  };
  static NSString *kImages[] = {
    @"tutorial-1.png",
    @"tutorial-2.png",
    @"tutorial-3.png",
    @"tutorial-4.png",
    @"tutorial-5.png"
  };
  NSAssert(ARRAY_SIZE(kTexts) == ARRAY_SIZE(kImages),
           @"Mismatch in count of images/texts");

  for (unsigned int i = 0; i < ARRAY_SIZE(kTexts); i++) {
    TutorialViewController *t = [self.storyboard
        instantiateViewControllerWithIdentifier:@"TutorialPage"];
    t.texts = kTexts[i];
    if (kImages[i] != nil) t.image = [UIImage imageNamed:kImages[i]];
    [self.pages addObject:t];
  }

  TutorialFinalViewController * final = [self.storyboard
      instantiateViewControllerWithIdentifier:@"TutorialFinalPage"];
  final.delegate = self;
  [self.pages addObject:final];

  [self setViewControllers:@[ self.pages[0] ]
                 direction:UIPageViewControllerNavigationDirectionForward
                  animated:NO
                completion:^(BOOL finished){
                }];

  self.dataSource = self;
  self.view.backgroundColor = [UIColor whiteColor];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
}


- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self.navigationController setNavigationBarHidden:YES];
}


- (UIViewController *)pageViewController:
                          (UIPageViewController *)pageViewController
      viewControllerBeforeViewController:(UIViewController *)viewController {
  NSUInteger index = [self.pages indexOfObject:viewController];
  if (index < 1) return nil;
  return self.pages[index - 1];
}


- (UIViewController *)pageViewController:
                          (UIPageViewController *)pageViewController
       viewControllerAfterViewController:(UIViewController *)viewController {
  NSUInteger index = [self.pages indexOfObject:viewController];
  if (index + 1 == self.pages.count) return nil;
  return self.pages[index + 1];
}


- (NSInteger)presentationCountForPageViewController:
    (UIPageViewController *)pageViewController {
  return (NSInteger)self.pages.count;
}


- (NSInteger)presentationIndexForPageViewController:
    (UIPageViewController *)pageViewController {
  return 0;
}


- (void)finishReached {
  NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
  [def setBool:YES forKey:@"seenTutorial"];
  [self.navigationController popViewControllerAnimated:YES];
}

@end
