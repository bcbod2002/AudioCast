//
//  MCManagerModel.m
//  AudioCast
//
//  Created by Goston on 21/03/2017.
//  Copyright © 2017 Goston. All rights reserved.
//

#import "MCManagerModel.h"

#define ServiceType @"audioshare"

@interface MCManagerModel() {
    NSInteger timeStampCounter;
}

@end

@implementation MCManagerModel

-(instancetype)init {
    self = [super init];
    if (self) {
//        _peerId = nil;
//        _session = nil;
//        _serviceAdvertiser = nil;
        [self setupPeerSessionWithName:[[UIDevice currentDevice] name]];
        timeStampCounter = 0;
        _averageTimeStamp = 0;
    }
    
    return self;
}

-(void)setupPeerSessionWithName: (NSString *) displayName {
    _peerId = [[MCPeerID alloc] initWithDisplayName:displayName];
    _session = [[MCSession alloc] initWithPeer:_peerId securityIdentity:nil encryptionPreference:MCEncryptionRequired];
    [_session setDelegate:self];
    
    // Initial MCNearbyServiceAdvertiser
    _serviceAdvertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:_peerId discoveryInfo:nil serviceType:ServiceType];
    [_serviceAdvertiser setDelegate:self];
    
    // Initial MCNearbyServiceBrowser
    _serviceBrowser = [[MCNearbyServiceBrowser alloc] initWithPeer:_peerId serviceType:ServiceType];
    [_serviceBrowser setDelegate:self];
    
    [_serviceAdvertiser startAdvertisingPeer];
    [_serviceBrowser startBrowsingForPeers];
}

-(void)startBrowserAdvertiser {
    [_serviceAdvertiser startAdvertisingPeer];
    [_serviceBrowser startBrowsingForPeers];
}

-(void)stopBrowserAdvertiser {
    [_serviceAdvertiser stopAdvertisingPeer];
    [_serviceBrowser stopBrowsingForPeers];
}

-(void)sendString:(NSString *)string {
    if ([[_session connectedPeers] count] > 0) {
        NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error;
        [_session sendData:data toPeers:[_session connectedPeers] withMode:MCSessionSendDataReliable error:&error];
        NSLog(@"Send error = %@", [error description]);
    }
    else {
        NSLog(@"Not connected yet");
    }
}

-(void)sendMediaData:(NSData *)mediaData {
    if ([[_session connectedPeers] count] > 0) {
        NSError *error;
        [_session sendData:mediaData toPeers:[_session connectedPeers] withMode:MCSessionSendDataReliable error:&error];
        NSLog(@"Send error = %@", [error description]);
    }
    else {
        NSLog(@"Not connected yet");
    }
}

-(void)sendMediaStreamWithData:(NSData *)mediaData {
    if ([[_session connectedPeers] count] > 0) {
        NSError *error;
        NSOutputStream *outputStream = [_session startStreamWithName:@"MediaStream" toPeer:[[_session connectedPeers] objectAtIndex:0] error:&error];
        
        const uint8_t *bytes = (const uint8_t *)[mediaData bytes];
        [outputStream write:bytes maxLength:[mediaData length]];
        
        NSLog(@"Stream error = %@", [error description]);
    }
}

-(void)sendTenTimeStamp {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        for (int i = 0; i < 9; ++i) {
            long double timeStamp = [[NSDate date] timeIntervalSince1970];
            NSData *timeStampData = [NSData dataWithBytes:&timeStamp length:sizeof(long double)];
            
            NSError *sendDataError;
            [_session sendData:timeStampData toPeers:[_session connectedPeers] withMode:MCSessionSendDataUnreliable error:&sendDataError];
            [NSThread sleepForTimeInterval:0.1];
        }
    });
}


#pragma mark - MCSessionDelegate
-(void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state {
    NSLog(@"Did change peerID = %@", [peerID displayName]);
    if ([_delegate respondsToSelector:@selector(manager:didConnectPeers:)]) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [_delegate manager:self didConnectPeers:[session connectedPeers]];
        }];
    }
    [self sendTenTimeStamp];
}

-(void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID {
    
    if ([data length] <= 8) {
        long double timeStamp;
        [data getBytes:&timeStamp length:sizeof(timeStamp)];
        timeStamp = [[NSDate date] timeIntervalSinceDate:[NSDate dateWithTimeIntervalSince1970:timeStamp]];
        _averageTimeStamp += timeStamp;
        if (timeStampCounter > 1) {
            _averageTimeStamp = _averageTimeStamp / 2;
        }
        NSLog(@"_averageTimeStamp = %Lf", _averageTimeStamp);
    }
    else {
        if ([_delegate respondsToSelector:@selector(manager:didReceiveData:fromPeer:)]) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [_delegate manager:self didReceiveData:data fromPeer:[peerID displayName]];
            }];
        }
    }
}

-(void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress {
    NSLog(@"Did start receiving resource with name = %@", resourceName);
}

-(void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error {
    NSLog(@"Did finish receiving resource with name = %@", resourceName);
}

-(void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID {
    if ([_delegate respondsToSelector:@selector(manager:didReceiveData:fromPeer:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_delegate manager:self didReceiveStream:stream fromPeer:[peerID displayName]];
        });
    }
}


#pragma mark - MCNeerServiceAdvertiser
-(void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didNotStartAdvertisingPeer:(NSError *)error {
    NSLog(@"Did not start advertising peer = %@", [error description]);
}

-(void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void (^)(BOOL, MCSession * _Nullable))invitationHandler {
    NSLog(@"Did receive invitation from peer = %@", [peerID displayName]);
    invitationHandler(YES, _session);
}


#pragma mark -  MCNearbyServiceBrowserDelegate
-(void)browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error {
    NSLog(@"Did not start browsing for peers = %@", [error description]);
}

-(void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary<NSString *,NSString *> *)info {
    NSLog(@"Found Peer id = %@", [peerID displayName]);
    [browser invitePeer:peerID toSession:_session withContext:nil timeout:10];
    if ([_delegate respondsToSelector:@selector(manager:foundPeer:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_delegate manager:self foundPeer:peerID];
        });
    }
}

-(void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID {
    NSLog(@"Lost peer = %@", [peerID displayName]);
}

@end
