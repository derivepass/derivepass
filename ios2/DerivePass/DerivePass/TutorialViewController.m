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
@property (weak, nonatomic) IBOutlet UILabel *label;

@end

@implementation TutorialViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.label.text = self.text;
  self.label.numberOfLines = 0;
  
  if (self.image == nil)
    return;
  
  self.label.alpha = 0.0;
  [self.imageView setImage: self.image];
}


- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}


- (void) viewWillAppear:(BOOL)animated {
  if (self.image == nil)
    return;

  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 750 * NSEC_PER_MSEC),
                 dispatch_get_main_queue(),
  ^{
    [UIView animateWithDuration: 0.7 animations: ^{
      self.label.alpha = 1.0;
      self.imageView.alpha = 0.1;
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
