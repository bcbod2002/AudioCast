//
//  MCManagerModel.h
//  AudioCast
//
//  Created by Goston on 21/03/2017.
//  Copyright © 2017 Goston. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>

@class MCManagerModel;
@protocol MCManagerModelDelegate <NSObject>

@optional
-(void) manager:(MCManagerModel *)manager foundPeer:(MCPeerID *)peerID;

-(void) manager:(MCManagerModel *)manager didConnectPeers:(NSArray<MCPeerID *>*)peerIDs;

-(void) manager:(MCManagerModel *)manager didReceiveData:(NSData *)data fromPeer:(NSString *)peerName;

-(void)manager:(MCManagerModel *)manager didReceiveStream:(NSInputStream *)stream fromPeer:(NSString *)peerName;

@end

@interface MCManagerModel : NSObject <MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate>

#pragma mark - Variables
@property (nonatomic, weak) id <MCManagerModelDelegate> delegate;
@property (nonatomic, strong) MCPeerID *peerId;
@property (nonatomic, strong) MCSession *session;
@property (nonatomic, strong) MCNearbyServiceAdvertiser *serviceAdvertiser;
@property (nonatomic, strong) MCNearbyServiceBrowser *serviceBrowser;

#pragma mark - Functions

/**
 Set up peer and session with dispplay name

 @param displayName String to set display name
 */
-(void)setupPeerSessionWithName: (NSString *) displayName;


/**
 Start browse and advertise peer
 */
-(void)startBrowserAdvertiser;


/**
 Stop browse and advertise peer
 */
-(void)stopBrowserAdvertiser;


/**
 Send string to others

 @param string Message string
 */
-(void)sendString:(NSString *)string;


/**
 Send media data to others

 @param string Media data
 */
-(void)sendMediaData:(NSData *)string;
@end
