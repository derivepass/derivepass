//
//  EditApplicationTableViewController.m
//  DerivePass
//
//  Created by Indutnyy, Fedor on 1/14/17.
//  Copyright © 2017 Indutny Inc. All rights reserved.
//

#import "EditApplicationTableViewController.h"

@interface EditApplicationTableViewController ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *saveButtonItem;
@property (weak, nonatomic) IBOutlet UITextField *domainField;
@property (weak, nonatomic) IBOutlet UITextField *loginField;
@property (weak, nonatomic) IBOutlet UITextField *revisionField;

@end

@implementation EditApplicationTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    self.navigationItem.rightBarButtonItem =
        self.saveButtonItem;
}

- (void) viewWillAppear:(BOOL)animated {
    self.domainField.text = [self.info valueForKey: @"domain"];
    self.loginField.text = [self.info valueForKey: @"login"];
    self.revisionField.text =
        [NSString stringWithFormat: @"%@", [self.info valueForKey: @"revision"]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


- (IBAction)onSave:(id)sender {
    [self.info setValue: self.domainField.text forKey: @"domain"];
    [self.info setValue: self.loginField.text forKey: @"login"];
    
    int rev = atoi([self.revisionField.text UTF8String]);
    [self.info setValue: [NSNumber numberWithInt: rev] forKey: @"revision"];
    [self.dataController save];
    
    [self.navigationController popViewControllerAnimated: YES];
}


- (IBAction)onFieldEdit:(id)sender {
    BOOL valid = YES;
    
    self.domainField.layer.borderWidth = 0.0;
    self.loginField.layer.borderWidth = 0.0;
    self.revisionField.layer.borderWidth = 0.0;
    
    if (self.domainField.text.length == 0) {
        valid = NO;
        
        self.domainField.layer.borderColor = [[UIColor redColor] CGColor];
        self.domainField.layer.borderWidth = 1.0;
    }
    
    if (self.loginField.text.length == 0) {
        valid = NO;
        
        self.loginField.layer.borderColor = [[UIColor redColor] CGColor];
        self.loginField.layer.borderWidth = 1.0;
    }
    
    if (self.revisionField.text.length == 0 ||
        atoi(self.revisionField.text.UTF8String) < 1) {
        valid = NO;
        
        self.revisionField.layer.borderColor = [[UIColor redColor] CGColor];
        self.revisionField.layer.borderWidth = 1.0;
    }
    
    self.saveButtonItem.enabled = valid;
}

@end
