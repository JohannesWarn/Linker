//
//  PostsTableViewController.h
//  Linker
//
//  Created by Johannes Wärn on 29/11/14.
//  Copyright (c) 2014 Johannes Wärn. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PostsTableViewController : UITableViewController

@property (nonatomic) NSString *bucketName;

@property (nonatomic) AWSS3 *s3;
@property (nonatomic) AWSS3TransferManager *transferManager;

@end
