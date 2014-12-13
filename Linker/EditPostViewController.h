//
//  EditPostViewController.h
//  Linker
//
//  Created by Johannes Wärn on 30/11/14.
//  Copyright (c) 2014 Johannes Wärn. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EditPostViewController : UITableViewController

@property (nonatomic) AWSS3 *s3;
@property (nonatomic) AWSS3TransferManager *transferManager;
@property (nonatomic) AWSS3Bucket *bucket;
@property (nonatomic) AWSS3Object *object;

@end
