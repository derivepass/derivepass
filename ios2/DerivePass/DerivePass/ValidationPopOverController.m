//
//  ValidationPopOverController.m
//  DerivePass
//
//  Created by Indutnyy, Fedor on 1/22/17.
//
//  This software is licensed under the MIT License.
//  Copyright © 2017 Indutny Inc. All rights reserved.
//

#import "ValidationPopOverController.h"

@interface ValidationPopOverController ()

@property(weak, nonatomic) IBOutlet UILabel *label;

@end

@implementation ValidationPopOverController

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view.
  self.label.text = self.message;
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
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
