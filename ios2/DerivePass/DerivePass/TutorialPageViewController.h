//
//  TutorialPageViewController.h
//  DerivePass
//
//  Created by Indutnyy, Fedor on 1/16/17.
//
//  This software is licensed under the MIT License.
//  Copyright © 2017 Indutny Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "TutorialFinalViewController.h"

@interface TutorialPageViewController
    : UIPageViewController<UIPageViewControllerDataSource,
                           TutorialFinalViewControllerDelegate>

@end
