//
//  AppDelegate.m
//  DerivePass
//
//  Created by Indutnyy, Fedor on 1/13/17.
//
//  This software is licensed under the MIT License.
//  Copyright © 2017 Indutny Inc. All rights reserved.
//

#import "AppDelegate.h"
#import "PasswordViewController.h"

@interface AppDelegate ()

@property UIView *previewBlocker;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  // Set global appearance of UIPageControl
  UIPageControl *pageControl = [UIPageControl appearance];
  pageControl.pageIndicatorTintColor = [UIColor lightGrayColor];
  pageControl.currentPageIndicatorTintColor = [UIColor blackColor];
  pageControl.backgroundColor = [UIColor whiteColor];

  return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
  if (self.previewBlocker != nil) return;

  UIView *view = [[UIView alloc] initWithFrame:self.window.frame];
  view.backgroundColor = [UIColor whiteColor];
  view.alpha = 1.0;

  [self.window addSubview:view];
  [self.window bringSubviewToFront:view];
  self.previewBlocker = view;
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
  if (self.previewBlocker == nil) return;

  [UIView animateWithDuration:0.2
      animations:^(void) {
        [self.previewBlocker setAlpha:0.0];
      }
      completion:^(BOOL finished) {
        [self.previewBlocker removeFromSuperview];
        self.previewBlocker = nil;
      }];
}


- (void)applicationProtectedDataWillBecomeUnavailable:
    (UIApplication *)application {
  UINavigationController *nav =
      (UINavigationController *)self.window.rootViewController;
  [nav popToRootViewControllerAnimated:YES];

  UIViewController *top = nav.topViewController;
  if ([top respondsToSelector:@selector(protectedDataWillBecomeUnavailable)]) {
    PasswordViewController *p = (PasswordViewController *)top;
    [p protectedDataWillBecomeUnavailable];
  }
}


- (void)applicationWillTerminate:(UIApplication *)application {
}

@end
