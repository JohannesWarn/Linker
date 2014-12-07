//
//  SettingsTableViewController.h
//  Linker
//
//  Created by Johannes Wärn on 06/12/14.
//  Copyright (c) 2014 Johannes Wärn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AWSiOSSDKv2/S3.h>

@interface SettingsTableViewController : UITableViewController

@property (nonatomic) AWSS3 *s3;
@property (nonatomic) AWSS3TransferManager *transferManager;

@end
