//
//  PostsTableViewController.m
//  Linker
//
//  Created by Johannes Wärn on 29/11/14.
//  Copyright (c) 2014 Johannes Wärn. All rights reserved.
//

#import <AWSiOSSDKv2/S3.h>

#import "PostsTableViewController.h"
#import "EditPostViewController.h"

@interface PostsTableViewController ()

@property (nonatomic) NSArray *bucketObjects;

@property (nonatomic) UIView *scrollIndicator;
@property (nonatomic) BOOL shouldCreateNewPost;

@end

@implementation PostsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setTitle:self.bucket.name];
    
    [self setupScrollIndicator];
    [self reloadBucket:self.bucket];
}

- (void)setupScrollIndicator
{
    CGFloat width = 42;
    CGFloat height = 42;
    CGRect scrollIndicatorRect = CGRectMake((self.view.frame.size.width - width) * 0.5,
                                            -(height + 10),
                                            width, height);
    self.scrollIndicator = [[UIView alloc] initWithFrame:scrollIndicatorRect];
    [self.scrollIndicator.layer setBackgroundColor:[[UIColor redColor] CGColor]];
    [self.scrollIndicator.layer setAffineTransform:CGAffineTransformMakeScale(0, 0)];
    
    [self.tableView addSubview:self.scrollIndicator];
    self.shouldCreateNewPost = NO;
}

- (void)reloadBucket:(AWSS3Bucket *)bucket
{
    typeof(self) __weak weakSelf = self;
    
    AWSS3ListObjectsRequest *request = [[AWSS3ListObjectsRequest alloc] init];
    [request setBucket:bucket.name];
    
    BFTask *task = [self.s3 listObjects:request];
    [task continueWithBlock:^id(BFTask *task) {
        if ([task.result isKindOfClass:[AWSS3ListObjectsOutput class]]) {
            AWSS3ListObjectsOutput *output = (AWSS3ListObjectsOutput *)task.result;
            weakSelf.bucketObjects = output.contents;
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.tableView reloadSections:[NSIndexSet indexSetWithIndex:0]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
            });
        }
        
        return nil;
    }];
}

- (void)createNewPost
{
    [self.tableView selectRowAtIndexPath:nil animated:YES scrollPosition:UITableViewScrollPositionNone];
    [self performSegueWithIdentifier:@"edit post" sender:self];
    self.shouldCreateNewPost = NO;
}

- (IBAction)refresh:(UIBarButtonItem *)sender {
    [self reloadBucket:self.bucket];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[EditPostViewController class]]) {
        EditPostViewController *editPostViewController = segue.destinationViewController;
        
        editPostViewController.bucket = self.bucket;
        editPostViewController.s3 = self.s3;
        editPostViewController.transferManager = self.transferManager;
        
        if ([sender isKindOfClass:[UITableViewCell class]]) {
            NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
            AWSS3Object *bucketObject = [self.bucketObjects objectAtIndex:indexPath.row];
            editPostViewController.filename = bucketObject.key;
        }
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return self.bucketObjects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    AWSS3Object *bucketObject = [self.bucketObjects objectAtIndex:indexPath.row];
    
    cell.textLabel.text = bucketObject.key;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (!self.shouldCreateNewPost) {
        CGFloat scale = - (20 + scrollView.contentInset.top + scrollView.contentOffset.y) / 50;
        scale = MAX(scale, 0);
        scale = MIN(scale, 1);
        
        [self.scrollIndicator.layer setAffineTransform:CGAffineTransformMakeScale(scale, scale)];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    CGFloat scale = - (20 + scrollView.contentInset.top + scrollView.contentOffset.y) / 50;
    self.shouldCreateNewPost = scale >= 1;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if (self.shouldCreateNewPost) {
        [self createNewPost];
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
