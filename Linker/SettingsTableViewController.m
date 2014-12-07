//
//  SettingsTableViewController.m
//  Linker
//
//  Created by Johannes Wärn on 06/12/14.
//  Copyright (c) 2014 Johannes Wärn. All rights reserved.
//

#import "SettingsTableViewController.h"
#import "PostsTableViewController.h"

@interface SettingsTableViewController ()

@property (nonatomic) NSArray *buckets;
@property (nonatomic) NSString *errorMessage;

@property (weak, nonatomic) UITextField *accessKeyTextField;
@property (weak, nonatomic) UITextField *secretKeyTextField;
@property (weak, nonatomic) UILabel *regionLabel;

@end

@implementation SettingsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self setupS3];
    [self findBuckets];
}

- (void)setupS3
{
    if ([self.accessKeyTextField.text isEqualToString:@""] || [self.secretKeyTextField.text isEqualToString:@""]) {
        return;
    }
    
    AWSStaticCredentialsProvider *credentials = [AWSStaticCredentialsProvider
                                                 credentialsWithAccessKey: self.accessKeyTextField.text
                                                 secretKey: self.secretKeyTextField.text];
    AWSServiceConfiguration *configuration = [AWSServiceConfiguration
                                              configurationWithRegion: AWSRegionEUWest1
                                              credentialsProvider: credentials];
    
    self.s3 = [[AWSS3 alloc] initWithConfiguration:configuration];
    self.transferManager = [[AWSS3TransferManager alloc] initWithConfiguration:configuration identifier:@"main"];
}

- (void)findBuckets
{
    if (self.s3 == nil) { return; }
    typeof(self) __weak weakSelf = self;
    
    AWSRequest *request = [[AWSRequest alloc] init];
    
    BFTask *task = [self.s3 listBuckets:request];
    [task continueWithBlock:^id(BFTask *task) {
        if ([task.result isKindOfClass:[AWSS3ListBucketsOutput class]]) {
            AWSS3ListBucketsOutput *output = (AWSS3ListBucketsOutput *)task.result;
            self.buckets = output.buckets;
        }
        if (task.error != nil) {
            self.errorMessage = [task.error.userInfo objectForKey:@"Message"];
        } else {
            self.errorMessage = nil;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
        });
        
        return nil;
    }];
}

- (IBAction)didPressReturn:(UITextField *)sender {
    if ([sender isEqual:self.accessKeyTextField]) {
        [self.secretKeyTextField becomeFirstResponder];
    } else {
        [sender endEditing:YES];
    }
}

- (IBAction)didEndKeyEdit:(id)sender
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:self.accessKeyTextField.text forKey:@"accessKey"];
    [defaults setObject:self.secretKeyTextField.text forKey:@"secretKey"];
    
    [self setupS3];
    [self findBuckets];
}

- (IBAction)refresh:(UIBarButtonItem *)sender {
    [self findBuckets];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [self.view endEditing:NO];
    if ([segue.destinationViewController isKindOfClass:[PostsTableViewController class]]) {
        PostsTableViewController *postsTableViewController = (PostsTableViewController *)segue.destinationViewController;
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        AWSS3Bucket *bucket = [self.buckets objectAtIndex:indexPath.row];
        if (indexPath.section != 1) { return; }
        
        postsTableViewController.s3 = self.s3;
        postsTableViewController.transferManager = self.transferManager;
        postsTableViewController.bucket = bucket;
    }
}

- (IBAction)unwind:(UIStoryboardSegue *)unwindSegue
{
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 1 && self.buckets != nil) {
        return @"Choose a Buckets";
    }
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section == 0) {
        return self.errorMessage;
    }
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 3;
    } else if (self.buckets != nil) {
        return self.buckets.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    if (indexPath.section == 0) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        switch (indexPath.row) {
            case 0:
                cell = [tableView dequeueReusableCellWithIdentifier:@"access key" forIndexPath:indexPath];
                for (UIView *subview in cell.contentView.subviews) {
                    if ([subview isKindOfClass:[UITextField class]]) {
                        self.accessKeyTextField = (UITextField *)subview;
                        self.accessKeyTextField.text = [defaults objectForKey:@"accessKey"];
                    }
                }
                break;
            case 1:
                cell = [tableView dequeueReusableCellWithIdentifier:@"secret key" forIndexPath:indexPath];
                for (UIView *subview in cell.contentView.subviews) {
                    if ([subview isKindOfClass:[UITextField class]]) {
                        self.secretKeyTextField = (UITextField *)subview;
                        self.secretKeyTextField.text = [defaults objectForKey:@"secretKey"];
                    }
                }
                break;
            case 2:
                cell = [tableView dequeueReusableCellWithIdentifier:@"region" forIndexPath:indexPath];
                for (UIView *subview in cell.contentView.subviews) {
                    if ([subview isKindOfClass:[UILabel class]]) {
                        self.regionLabel = (UILabel *)subview;
                    }
                }
                break;
            default:
                break;
        }
    } else {
        AWSS3Bucket *bucket = [self.buckets objectAtIndex:indexPath.row];
        cell = [tableView dequeueReusableCellWithIdentifier:@"bucket" forIndexPath:indexPath];
        cell.textLabel.text = bucket.name;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    if (indexPath.section == 0) {
        if (indexPath.row < 2) {
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            for (UIView *subview in [cell.contentView subviews]) {
                if ([subview canBecomeFirstResponder]) {
                    [subview becomeFirstResponder];
                    return;
                }
            }
        }
    }
}

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

@end
