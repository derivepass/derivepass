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
  NSInteger index_;
  BOOL sliding_;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  self.label.text = [self.texts objectAtIndex:0];
  self.label.numberOfLines = 0;

  if (self.image == nil) return;

  [self.imageView setImage:self.image];
}


- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}


- (void)viewWillAppear:(BOOL)animated {
  if (sliding_) return;

  if (self.image == nil) {
    index_ = 1;

    self.label.alpha = 1.0;
    self.imageView.alpha = 0.0;
    self.label.text = self.texts[0];
  } else {
    index_ = 0;

    self.label.alpha = 0.0;
    self.imageView.alpha = 1.0;
  }

  if (index_ < self.texts.count) [self doSlide];
}


- (void)doSlide {
  if (sliding_) {
    return;
  }
  sliding_ = YES;

  void (^done)(void) = ^{
    if (++index_ > self.texts.count) return;

    // No return
    sliding_ = NO;
    [self doSlide];
  };

  dispatch_time_t delay = dispatch_time(
      DISPATCH_TIME_NOW, (index_ == 0 ? 750 : 1200) * NSEC_PER_MSEC);
  dispatch_queue_t queue = dispatch_get_main_queue();
  dispatch_after(delay, queue, ^{
    if (index_ == 0) {
      [UIView animateWithDuration:0.75
          animations:^{
            self.label.alpha = 1.0;
            self.imageView.alpha = 0.3;
          }
          completion:^(BOOL finished) {
            done();
          }];
      return;
    }

    [UIView animateWithDuration:1.4
        animations:^{
          self.label.alpha = 0.0;
        }
        completion:^(BOOL finished) {
          if (index_ == self.texts.count) {
            self.label.text = @"Please swipe to continue...";

            dispatch_time_t end_delay =
                dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC);
            dispatch_after(end_delay, queue, ^{
              [UIView animateWithDuration:1.2
                               animations:^{
                                 self.label.alpha = 0.4;
                               }];
            });
            return;
          }

          self.label.text = self.texts[index_];

          [UIView animateWithDuration:0.33
              animations:^{
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
