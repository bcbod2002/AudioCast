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

@interface ConnectionsViewController () <NSURLConnectionDataDelegate>

@property (strong, nonatomic) NSMutableArray<MCPeerID *> *arrConnectedDevices;
@property (strong, nonatomic) MPMediaModel *mediaModel;
@property (strong, nonatomic) NSData *mediaData;
@property (strong, nonatomic) NSURLConnection *connection;
@property (strong, nonatomic) NSMutableData *mp3Data;
@property (strong, nonatomic) GWSimplePlayer *simplePlayer;

@end

@implementation ConnectionsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _manager = [[MCManagerModel alloc] init];
    [_manager setDelegate:self];
    
    _arrConnectedDevices = [[NSMutableArray alloc] init];
//    [self initialMPMdeia];
    
    // Load Mp3 from url
    _mp3Data = [[NSMutableData alloc] init];
    NSURL *mp3URL = [NSURL URLWithString:@"http://picosong.com/cdn/a2b022865d185c4a8508a4212865413f.mp3"];
//    _connection = [[NSURLConnection alloc] initWithRequest:[NSURLRequest requestWithURL:mp3URL] delegate:self];
//    _mediaData = [NSData dataWithContentsOfURL:mp3URL];
    
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *myFile = [mainBundle pathForResource:@"Rythem" ofType:@"mp3"];
    NSLog(@"myFile = %@", myFile);
    _mediaData = [NSData dataWithContentsOfFile:myFile];
    
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
    NSLog(@"_media lenfht = %ld", [_mediaData length]);
    NSUInteger dataLength = [_mediaData length];
    NSMutableArray *dataArray = [[NSMutableArray alloc] init];
    NSUInteger splitedSize = 10 * 1024;
    NSUInteger dataCount = (dataLength / splitedSize) + 1;
    for (NSUInteger i = 0; i < dataCount; ++i) {
        
        NSUInteger offset = i * splitedSize;
        NSUInteger dataSize = dataLength - offset > splitedSize ? splitedSize : dataLength - offset;
        
        NSData *splitData = [NSData dataWithBytesNoCopy:(uint8_t *)[_mediaData bytes] + (i * splitedSize) length:dataSize freeWhenDone:NO];
        [dataArray addObject:splitData];
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        for (NSData *splitedData in dataArray) {
            [_manager sendMediaData:splitedData];
            dispatch_async(dispatch_get_main_queue(), ^{
                static dispatch_once_t onceToken;
                dispatch_once(&onceToken, ^{
                    usleep([_manager averageTimeStamp] * 1000);
                });
                [_simplePlayer playAudioWithData:splitedData];
            });
        }
    });
    
    [_receiveTextView setText:[NSString stringWithFormat:@"%ld", [_mp3Data length]]];
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
    [_simplePlayer playAudioWithData:data];
    [_receiveTextView setText:[NSString stringWithFormat:@"%ld", [data length]]];
}

-(void)manager:(MCManagerModel *)manager didReceiveStream:(NSInputStream *)stream fromPeer:(NSString *)peerName {
    
    uint8_t buffer[1024];
    NSInteger bufferLength = [stream read:buffer maxLength:1024];
    if (bufferLength > 0) {
        NSData *data = [NSData dataWithBytes:(const void *)buffer length:bufferLength];
        [_simplePlayer playAudioWithData:data];
    }
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


#pragma mark - NSURLConnectionDataDelegate
-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        if ([(NSHTTPURLResponse *) response statusCode] != 200) {
            NSLog(@"Http code = %ld", [(NSHTTPURLResponse *) response statusCode]);
            [connection cancel];
        }
    }
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    printf("Mp333 data = %ld\n", [data length]);
    [_mp3Data appendData:data];
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
