//
//  ProgressNavigationBar.h
//  Linker
//
//  Created by Johannes Wärn on 07/12/14.
//  Copyright (c) 2014 Johannes Wärn. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ProgressNavigationBar : UINavigationBar

- (void)setProgress:(float)progress animated:(BOOL)animated;
- (void)hideProgressView:(BOOL)hidden;

@end
