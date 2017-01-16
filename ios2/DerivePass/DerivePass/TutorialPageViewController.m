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

@interface TutorialPageViewController ()

@property NSMutableArray<UIViewController *> *pages;

@end

@implementation TutorialPageViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.pages = [NSMutableArray array];

  for (int i = 0; i < 2; i++) {
    TutorialViewController *t = [self.storyboard
        instantiateViewControllerWithIdentifier:@"TutorialPage"];
    [self.pages insertObject:t atIndex:i];
  }

  TutorialFinalViewController * final = [self.storyboard
      instantiateViewControllerWithIdentifier:@"TutorialFinalPage"];
  final.delegate = self;
  [self.pages insertObject:final atIndex:self.pages.count];

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
