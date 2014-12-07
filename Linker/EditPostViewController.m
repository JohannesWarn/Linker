//
//  EditPostViewController.m
//  Linker
//
//  Created by Johannes Wärn on 30/11/14.
//  Copyright (c) 2014 Johannes Wärn. All rights reserved.
//

#import <AWSiOSSDKv2/S3.h>
#import <AWSiOSSDKv2/AWSCore.h>

#import "EditPostViewController.h"
#import "ProgressNavigationBar.h"

@interface EditPostViewController () <UIScrollViewDelegate, UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UITextField *filenameField;
@property (weak, nonatomic) IBOutlet UITextField *mediaTypeField;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation EditPostViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.filename != nil) {
        self.title = self.filename;
        self.filenameField.text = self.filename;
        [self download];
    }
    
    ProgressNavigationBar *progressNavigationBar = (ProgressNavigationBar *)self.navigationController.navigationBar;
    [progressNavigationBar setProgress:0 animated:NO];
    
    /*
    [_scrollView setDelegate:self];
    [_textView setDelegate:self];
    [self setupKeyboardNotifications];
     */
}

- (void)viewDidAppear:(BOOL)animated
{
    if (self.filename == nil) {
        [_textView becomeFirstResponder];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    ProgressNavigationBar *progressNavigationBar = (ProgressNavigationBar *)self.navigationController.navigationBar;
    [progressNavigationBar hideProgressView:YES];
}

- (void)download
{
    // Construct the NSURL for the download location.
    NSString *downloadingFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"downloaded-myImage.jpg"];
    NSURL *downloadingFileURL = [NSURL fileURLWithPath:downloadingFilePath];
    
    // Construct the download request.
    AWSS3TransferManagerDownloadRequest *downloadRequest = [AWSS3TransferManagerDownloadRequest new];
    
    downloadRequest.bucket = self.bucket.name;
    downloadRequest.key = self.filename;
    downloadRequest.downloadingFileURL = downloadingFileURL;
    downloadRequest.downloadProgress = ^(int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite){
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"%@ of %@ bytes written", @(totalBytesWritten), @(totalBytesExpectedToWrite));
            
            if (totalBytesWritten == totalBytesExpectedToWrite) {
                self.textView.text = [NSString stringWithContentsOfFile:downloadingFilePath usedEncoding:nil error:nil];
                self.imageView.image = [UIImage imageWithContentsOfFile:downloadingFilePath];
            }
        });
    };
    
    [self.transferManager download:downloadRequest];
}

- (IBAction)publish:(UIBarButtonItem *)sender
{
    typeof(self) __weak weakSelf = self;
    
    AWSS3TransferManagerUploadRequest *uploadRequest = [[AWSS3TransferManagerUploadRequest alloc] init];
    uploadRequest.bucket = self.bucket.name;
    uploadRequest.key = [self key];
    uploadRequest.body = [self urlWithBody];
    uploadRequest.contentType = [self mediaType];
    
    uploadRequest.uploadProgress = ^(int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite){
        // update progress
        dispatch_sync(dispatch_get_main_queue(), ^{
            ProgressNavigationBar *progressNavigationBar = (ProgressNavigationBar *)weakSelf.navigationController.navigationBar;
            
            float uploadProgress = (float)totalBytesWritten / (float)totalBytesExpectedToWrite;
            float baseProgress = 0.05;
            float progress = baseProgress + uploadProgress * (1 - baseProgress);
            [progressNavigationBar setProgress:progress animated:YES];
        });
    };
    
    [[self.transferManager upload:uploadRequest] continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
        
        return nil;
    }];
}

- (NSString *)mediaType
{
    if (self.mediaTypeField.text != nil) {
        return self.mediaTypeField.text;
    }
    return self.defaultMediaType;
}

- (NSString *)defaultMediaType
{
    return @"text/plain";
}

- (NSString *)key
{
    if (self.filenameField.text.length > 0) {
        return self.filenameField.text;
    }
    
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity:6];
    for (int i = 0; i < 6; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random_uniform((unsigned int)[letters length])]];
    }
    
    return randomString;
}

- (NSURL *)tempURL
{
    return [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[self key]]];
}

- (NSURL *)urlWithBody
{
    NSURL *url = [self tempURL];
    NSError *error;
    
    [self.textView.text writeToURL:url
                        atomically:YES
                          encoding:NSUTF8StringEncoding
                             error:&error];
    
    if (error) {
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle: @"Error"
                                              message: error.localizedDescription
                                              preferredStyle: UIAlertControllerStyleAlert];
        [self presentViewController:alertController animated:YES completion:nil];
        
        return nil;
    }
    
    return url;
}

#pragma mark - Table view data source

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    for (UIView *subview in [cell.contentView subviews]) {
        if ([subview canBecomeFirstResponder]) {
            [subview becomeFirstResponder];
            return;
        }
    }
}

/*
 - (void)setupKeyboardNotifications
 {
 [[NSNotificationCenter defaultCenter] addObserver:self
 selector:@selector(keyboardDidShow:)
 name:UIKeyboardDidShowNotification
 object:nil];
 
 [[NSNotificationCenter defaultCenter] addObserver:self
 selector:@selector(keyboardWillBeHidden:)
 name:UIKeyboardWillHideNotification
 object:nil];
 }
 */


/*
#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    if (velocity.y < -0.6) {
        [_textView endEditing:YES];
    }
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView
{
    // Bug workaround: If the text carrot is at the end, add a space and remove it to force a scroll.
    if (textView.selectedRange.location == textView.text.length && textView.selectedRange.length == 0) {
        textView.text = [textView.text stringByAppendingString:@"*"];
        textView.text = [textView.text substringToIndex:[textView.text length] - 1];
    }
}

#pragma mark - Keyboard

- (void)keyboardDidShow:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    CGRect keyboardRect = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    keyboardRect = [self.view convertRect:keyboardRect fromView:nil];
    
    UIEdgeInsets contentInsets = _scrollView.contentInset;
    contentInsets.bottom = keyboardRect.size.height;
    _scrollView.contentInset = contentInsets;
    _scrollView.scrollIndicatorInsets = contentInsets;
    
    [self forceTextViewToScrollToCarrot:_textView];
}

- (void)keyboardWillBeHidden:(NSNotification *)notification
{
    UIEdgeInsets contentInsets = _scrollView.contentInset;
    contentInsets.bottom = 0;
    _scrollView.contentInset = contentInsets;
    _scrollView.scrollIndicatorInsets = contentInsets;
}

#pragma mark - Helper

- (void)forceTextViewToScrollToCarrot:(UITextView *)textView
{
    if (textView.selectedRange.length == 0) {
        [textView insertText:@"*"];
        [textView deleteBackward];
    }
}
 */

@end
