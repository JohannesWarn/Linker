//
//  EditPostViewController.m
//  Linker
//
//  Created by Johannes Wärn on 30/11/14.
//  Copyright (c) 2014 Johannes Wärn. All rights reserved.
//

#import <AWSiOSSDKv2/S3.h>

#import "EditPostViewController.h"

@interface EditPostViewController () <UIScrollViewDelegate, UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UITextField *titleField;
@property (weak, nonatomic) IBOutlet UITextField *linkField;
@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

@implementation EditPostViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [_scrollView setDelegate:self];
    [_textView setDelegate:self];
    
    [self setupKeyboardNotifications];
}

- (void)viewDidAppear:(BOOL)animated
{
    if ([_textView.text isEqualToString:@""]) {
        [_textView becomeFirstResponder];
    }
}

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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)publish:(UIBarButtonItem *)sender {
    AWSS3TransferManagerUploadRequest *request = [[AWSS3TransferManagerUploadRequest alloc] init];
    [request setBucket:self.bucketName];
    [request setKey:[self key]];
    [request setBody:[self bodyURL]];
    
    BFTask *task = [self.transferManager upload:request];
    [task continueWithBlock:^id(BFTask *task) {
        return nil;
    }];
}

- (NSString *)key
{
    if (self.titleField.text.length > 0) {
        return self.titleField.text;
    }
    
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity:6];
    for (int i = 0; i < 6; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random_uniform((unsigned int)[letters length])]];
    }
    
    return randomString;
}

- (NSURL *)bodyURL
{
    NSURL *url = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[self key]]];
    NSError *error;
    
    [self.textView.text writeToURL:url
                        atomically:YES
                          encoding:NSUTF8StringEncoding
                             error:&error];
    
    if (error) {
        return nil;
    }
    
    return url;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

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

@end
