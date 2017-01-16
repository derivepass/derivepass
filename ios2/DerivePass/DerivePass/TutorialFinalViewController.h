//
//  TutorialFinalViewController.h
//  DerivePass
//
//  Created by Indutnyy, Fedor on 1/16/17.
//
//  This software is licensed under the MIT License.
//  Copyright © 2017 Indutny Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TutorialFinalViewControllerDelegate

- (void)finishReached;

@end

@interface TutorialFinalViewController : UIViewController

@property(weak) id<TutorialFinalViewControllerDelegate> delegate;

@end
