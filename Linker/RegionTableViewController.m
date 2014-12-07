//
//  RegionTableViewController.m
//  Linker
//
//  Created by Johannes Wärn on 06/12/14.
//  Copyright (c) 2014 Johannes Wärn. All rights reserved.
//

#import <AWSiOSSDKv2/S3.h>

#import "RegionTableViewController.h"

@interface RegionTableViewController ()

@property (nonatomic) NSArray *endpoints;

@end

@implementation RegionTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSMutableArray *endpoints = [[NSMutableArray alloc] init];
    AWSEndpoint *endpoint;
    int n = 0;
    while (endpoint.regionName != nil || n < 2) {
        endpoint = [AWSEndpoint endpointWithRegion:n service:AWSServiceS3];
        if (endpoint.regionName != nil) {
            [endpoints addObject:endpoint];
        }
        n++;
    }
    self.endpoints = [NSArray arrayWithArray:endpoints];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.endpoints.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"region" forIndexPath:indexPath];
    AWSEndpoint *endpoint = [self.endpoints objectAtIndex:indexPath.row];
    
    NSArray *components = [endpoint.regionName componentsSeparatedByString:@"-"];
    NSString *continent = [[components objectAtIndex:0] uppercaseString];
    NSString *location = [[components objectAtIndex:1] capitalizedString];
    NSString *number = [components objectAtIndex:2];
    NSString *name = [NSString stringWithFormat:@"%@ %@ %@", continent, location, number];
    cell.textLabel.text = name;
    
    return cell;
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
