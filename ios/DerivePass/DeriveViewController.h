//
//  DeriveViewController.h
//  DerivePass
//
//  Created by Fedor Indutny on 08/06/15.
//  Copyright (c) 2015 Fedor Indutny. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DeriveViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextField* DomainTextField;
@property (weak, nonatomic) IBOutlet UITextField* MasterSecretTextField;
@property (weak, nonatomic) IBOutlet UITextField* RepeatSecretTextField;
@property (weak, nonatomic) IBOutlet UIButton* DeriveButton;
@property (weak, nonatomic) IBOutlet UITextView* DerivedKeyTextField;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView* ActivityIndicator;

@end
