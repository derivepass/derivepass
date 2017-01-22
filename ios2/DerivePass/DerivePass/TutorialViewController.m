//
//  TutorialViewController.m
//  DerivePass
//
//  Created by Indutnyy, Fedor on 1/16/17.
//
//  This software is licensed under the MIT License.
//  Copyright © 2017 Indutny Inc. All rights reserved.
//

#import "TutorialViewController.h"

#include <dispatch/dispatch.h>

@interface TutorialViewController ()

@property(weak, nonatomic) IBOutlet UIImageView *imageView;
@property(weak, nonatomic) IBOutlet UILabel *label;

@end

@implementation TutorialViewController {
  NSInteger current_;
  NSInteger next_;
  BOOL sliding_;
  BOOL can_reset_;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  self.label.numberOfLines = 0;

  current_ = 0;
  if (self.image == nil) {
    // No image - show just label
    self.label.alpha = 1.0;
    self.imageView.alpha = 0.0;
    self.label.text = self.texts[0];
  } else {
    // Show just image
    self.label.alpha = 0.0;
    self.imageView.alpha = 1.0;

    [self.imageView setImage:self.image];
  }

  can_reset_ = YES;
}


- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}


- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
}


- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];

  if (!can_reset_) return;
  can_reset_ = NO;

  if (self.image == nil)
    next_ = current_ == 1 ? 2 : 1;
  else
    next_ = 1;
  [self doSlide];
}


- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];
  can_reset_ = YES;
}


- (void)doSlide {
  if (sliding_) return;

  __block NSInteger next = next_++;

  if (next > self.texts.count + 1) return;
  sliding_ = YES;

  void (^done)(void) = ^{
    sliding_ = NO;
    current_ = next;

    [self doSlide];
  };

  dispatch_queue_t queue = dispatch_get_main_queue();

  // Sleep a bit first
  int64_t sleepTime = (current_ == 0 ? 750 : 1200) * NSEC_PER_MSEC;
  if (next < current_) sleepTime = 250 * NSEC_PER_MSEC;

  dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, sleepTime);
  dispatch_after(delay, queue, ^{
    // Current == image slide, slightly dim it and show text
    if (current_ == 0) {
      self.label.text = self.texts[next - 1];
      [UIView animateWithDuration:0.75
          animations:^{
            self.imageView.alpha = 0.3;
            self.label.alpha = 1.0;
          }
          completion:^(BOOL finished) {
            done();
          }];
      return;
    }

    // Current == text, dim image and hide text
    [UIView animateWithDuration:current_ == 0 ? 1.4 : 0.75
        animations:^{
          self.imageView.alpha = 0.3;
          self.label.alpha = 0.0;
        }
        completion:^(BOOL finished) {
          NSTimeInterval dur;

          // Last slide
          if (next == self.texts.count + 1) {
            dur = 3.0;
            self.label.text = @"Please swipe to continue...";
          } else {
            dur = 0.3;
            if (next > 0) self.label.text = self.texts[next - 1];
          }

          // Either show image or show text
          [UIView animateWithDuration:dur
              animations:^{
                if (next == 0)
                  self.imageView.alpha = 1.0;
                else
                  self.label.alpha = 1.0;
              }
              completion:^(BOOL finished) {
                done();
              }];
        }];
  });
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little
preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
