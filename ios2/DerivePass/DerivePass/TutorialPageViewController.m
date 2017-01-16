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
  
  static NSString* kTexts[] = {
    @"Welcome to\nDerivePass",
    @"This app\nsecurely creates\npasswords\nout of a single\nMaster Password",
    @"Enter\nMaster Password\nhere",
    @"Emojis\nrepresent your\nMaster Password",
    @"There are\nmillions of different\nEmoji combinations",
    @"Master Password\ncan't be guessed\nfrom them",
    @"Increment\nrevision\nif you need\nnew password",
    @"Tap\napplication row\nto copy password",
    @"Passwords\nare computed\non the fly"
  };
  static NSString* kImages[] = {
    nil, nil, @"tutorial-1.png", @"tutorial-2.png", @"tutorial-3.png", nil,
    @"tutorial-4.png", @"tutorial-5.png", nil
  };
  NSAssert(ARRAY_SIZE(kTexts) == ARRAY_SIZE(kImages),
           @"Mismatch in count of images/texts");

  for (unsigned int i = 0; i < ARRAY_SIZE(kTexts); i++) {
    TutorialViewController *t =
        [self.storyboard
            instantiateViewControllerWithIdentifier:@"TutorialPage"];
    t.text = kTexts[i];
    if (kImages[i] != nil)
      t.image = [UIImage imageNamed: kImages[i]];
    [self.pages addObject: t];
  }

  TutorialFinalViewController * final = [self.storyboard
      instantiateViewControllerWithIdentifier:@"TutorialFinalPage"];
  final.delegate = self;
  [self.pages addObject: final];
  
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
  // TODO(indutny): update user defaults
  [self.navigationController popViewControllerAnimated:YES];
}

@end
