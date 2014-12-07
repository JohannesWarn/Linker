//
//  ProgressNavigationBar.m
//  Linker
//
//  Created by Johannes Wärn on 07/12/14.
//  Copyright (c) 2014 Johannes Wärn. All rights reserved.
//

#import "ProgressNavigationBar.h"

@interface ProgressNavigationBar ()

@property (nonatomic, weak) IBOutlet UIProgressView *progressView;

@property (nonatomic) float progressViewHeight;

@end

@implementation ProgressNavigationBar

- (void)awakeFromNib
{
    self.progressViewHeight = 3.0;
    
    [self addSubview:self.progressView];
    [self setProgress:0 animated:NO];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self.progressView setFrame:CGRectMake(0,
                                           self.frame.size.height + 0.5 - self.progressViewHeight,
                                           self.frame.size.width,
                                           self.progressViewHeight)];
}

- (void)setProgress:(float)progress animated:(BOOL)animated
{
    [self hideProgressView:NO];
    [self.progressView setProgress:progress animated:animated];
}

- (void)hideProgressView:(BOOL)hidden
{
    [self.progressView setHidden:hidden];
}

@end
