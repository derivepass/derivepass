//
//  ValidationErrorButton.m
//  DerivePass
//
//  Created by Indutnyy, Fedor on 1/22/17.
//
//  This software is licensed under the MIT License.
//  Copyright © 2017 Indutny Inc. All rights reserved.
//

#import "ValidationErrorButton.h"
#import "ValidationPopOverController.h"

@interface ValidationErrorButton ()<UIPopoverPresentationControllerDelegate>

@property(weak) UIViewController* viewController;
@property(weak) UIPopoverPresentationController* popoverController;

@end

@implementation ValidationErrorButton {
  NSString* msg_;
}

- (ValidationErrorButton*)initWithMessage:(NSString*)msg
                  andParentViewController:(UIViewController*)vc {
  self = [super initWithFrame:CGRectMake(0.0, 0.0, 24.0, 32.0)];

  msg_ = msg;
  self.viewController = vc;

  [self setTitle:@"❗️" forState:UIControlStateNormal];
  [self addTarget:self
                action:@selector(onTap:)
      forControlEvents:UIControlEventTouchUpInside];
  return self;
}


- (IBAction)onTap:(id)sender {
  UIStoryboard* sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
  ValidationPopOverController* vc =
      [sb instantiateViewControllerWithIdentifier:@"ValidationPopOver"];

  vc.modalPresentationStyle = UIModalPresentationPopover;
  vc.preferredContentSize = CGSizeMake(240.0, 64.0);
  vc.message = msg_;

  UIPopoverPresentationController* pc = [vc popoverPresentationController];
  [pc setPermittedArrowDirections:UIPopoverArrowDirectionRight];
  pc.sourceView = self;
  pc.sourceRect = CGRectMake(0.0, 0.0, 24.0, 32.0);
  pc.delegate = self;

  self.popoverController = pc;

  UITapGestureRecognizer* gesture =
      [[UITapGestureRecognizer alloc] initWithTarget:self
                                              action:@selector(onPopOverTap:)];
  [vc.view addGestureRecognizer:gesture];

  [self.viewController presentViewController:vc animated:YES completion:nil];
}


- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:
    (UIPresentationController*)controller {
  return UIModalPresentationNone;
}


- (void)onPopOverTap:(UITapGestureRecognizer*)gesture {
  [self.popoverController.presentingViewController
      dismissViewControllerAnimated:YES
                         completion:nil];
}

@end
