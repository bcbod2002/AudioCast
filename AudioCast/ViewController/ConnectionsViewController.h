//
//  ConnectionsViewController.h
//  AudioCast
//
//  Created by Goston on 21/03/2017.
//  Copyright © 2017 Goston. All rights reserved.
//

#import "ViewController.h"
#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import "MCManagerModel.h"

@interface ConnectionsViewController : ViewController <MCManagerModelDelegate, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate>

#pragma mark - IBOutlet
@property (weak, nonatomic) IBOutlet UILabel *deviceNameLabel;
@property (weak, nonatomic) IBOutlet UITableView *connectedDevicesTableView;
@property (weak, nonatomic) IBOutlet UITextView *receiveTextView;


#pragma mark - Variables
@property (nonatomic, strong) MCManagerModel *manager;


#pragma mark - Functions
//-(void)peerDidChangeStateWithNotification:(NSNotification *)notification;

@end
