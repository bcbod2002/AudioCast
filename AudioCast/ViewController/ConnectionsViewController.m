//
//  ConnectionsViewController.m
//  AudioCast
//
//  Created by Goston on 21/03/2017.
//  Copyright © 2017 Goston. All rights reserved.
//

#import "ConnectionsViewController.h"
#import <AVFoundation/AVFoundation.h>

#import "GWSimplePlayer.h"
#import "MPMediaModel.h"

@interface ConnectionsViewController ()

@property (strong, nonatomic) NSMutableArray<MCPeerID *> *arrConnectedDevices;
@property (strong, nonatomic) MPMediaModel *mediaModel;
@property (strong, nonatomic) NSData *mediaData;
@property (strong, nonatomic) GWSimplePlayer *simplePlayer;

@end

@implementation ConnectionsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _manager = [[MCManagerModel alloc] init];
    [_manager setDelegate:self];
    
    _arrConnectedDevices = [[NSMutableArray alloc] init];
    [self initialMPMdeia];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    _simplePlayer = [[GWSimplePlayer alloc] init];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



#pragma mark - MPMediaModel
-(void)initialMPMdeia {
    _mediaModel = [[MPMediaModel alloc] init];
    [_mediaModel getMediaRawData:[[_mediaModel mediaItemsArray] objectAtIndex:0] :^(NSData *mediaData) {
        _mediaData = mediaData;
        NSLog(@"mediaData length = %ld", [mediaData length]);
    }];
}

#pragma mark - Buttons action
- (IBAction)connectAction:(id)sender {
    [_manager startBrowserAdvertiser];
}
- (IBAction)disconnectAction:(id)sender {
    [[_manager session] disconnect];
    [_manager stopBrowserAdvertiser];
}

- (IBAction)sendAction:(id)sender {
    NSInteger integer = rand();
    NSString *string = [NSString stringWithFormat:@"%ld", (long)integer];
//    [_manager sendString:string];

    
    [_manager sendMediaData:_mediaData];
    [_receiveTextView setText:[NSString stringWithFormat:@"%ld", [_mediaData length]]];
//    [_receiveTextView setText:string];
}

#pragma mark - MCManagerModelDelegate
-(void) manager:(MCManagerModel *)manager foundPeer:(MCPeerID *)peerID {
    [_arrConnectedDevices addObject:peerID];
    [_connectedDevicesTableView reloadData];
}

-(void)manager:(MCManagerModel *)manager didConnectPeers:(NSArray<MCPeerID *> *)peerIDs {
    NSString *devicesName = @"";
    for (NSString *deviceName in [peerIDs valueForKey:@"displayName"]) {
        devicesName = [devicesName stringByAppendingFormat:@"%@, ", deviceName];
    }
    
    [_deviceNameLabel setText:devicesName];
}

-(void)manager:(MCManagerModel *)manager didReceiveData:(NSData *)data fromPeer:(NSString *)peerName {
//    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//    NSLog(@"string = %@", string);
//    [_receiveTextView setText:string];
    
    [_simplePlayer play];
    [_simplePlayer playAudioWithData:data];
    [_receiveTextView setText:[NSString stringWithFormat:@"%ld", [data length]]];
}

-(void)manager:(MCManagerModel *)manager didReceiveStream:(NSInputStream *)stream fromPeer:(NSString *)peerName {
    
}


#pragma mark - UITableViewDataSource
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_arrConnectedDevices count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CellIdentifier"];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"CellIdentifier"];
    }
    NSString *displayName = [[_arrConnectedDevices objectAtIndex:[indexPath row]] displayName];
    [[cell textLabel] setText:displayName];
    
    return cell;
}

#pragma mark - UITableViewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MCNearbyServiceBrowser *browser = [_manager serviceBrowser];
    MCSession *session = [_manager session];
    MCPeerID *peerID = [_arrConnectedDevices objectAtIndex:[indexPath row]];
    
    [browser invitePeer:peerID toSession:session withContext:nil timeout:10];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
