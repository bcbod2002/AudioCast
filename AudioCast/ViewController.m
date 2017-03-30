//
//  ViewController.m
//  AudioCast
//
//  Created by Goston on 21/03/2017.
//  Copyright © 2017 Goston. All rights reserved.
//

#import "ViewController.h"
#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import <MediaPlayer/MPMediaQuery.h>
#import <MediaPlayer/MPMediaLibrary.h>
#import <AVFoundation/AVFoundation.h>

#include <sys/socket.h>
#include <netdb.h>

#import "GWSimplePlayer.h"

@interface ViewController () <NSStreamDelegate> {
    AVAudioPlayer *player;
    SimplePing *ping;
    
    GWSimplePlayer *simplePlayer;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
//    [MPMediaLibrary requestAuthorization:^(MPMediaLibraryAuthorizationStatus status) {
//        switch (status) {
//            case MPMediaLibraryAuthorizationStatusDenied:
//                NSLog(@"Deny");
//                break;
//            case MPMediaLibraryAuthorizationStatusRestricted:
//                NSLog(@"Restricted");
//                break;
//            case MPMediaLibraryAuthorizationStatusAuthorized:
//                NSLog(@"Authorized");
//                break;
//            case MPMediaLibraryAuthorizationStatusNotDetermined:
//                NSLog(@"Not Determine");
//                break;
//                
//            default:
//                break;
//        }
//    }];
//    
//    MPMediaQuery *mediaQuery = [[MPMediaQuery alloc] init];
//    NSArray<MPMediaItem *> *songsArray = [mediaQuery items];
//    
//    [[AVAudioSession sharedInstance] setActive:YES error:nil];
//    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
//    MPMediaItem *mediaItem = [songsArray objectAtIndex:0];
//    NSLog(@"mediaItem = %@", [mediaItem valueForProperty:MPMediaItemPropertyAssetURL]);
//    NSError *error;
//    player = [[AVAudioPlayer alloc] initWithContentsOfURL:[mediaItem assetURL] error:&error];
//
//    [player play];
//    [self playStreamMp3];
}

/*
 1. 建立 Parser 與網路連線
 2. 收到部分資料並 parse packet
 3. 收到 parser 分析出的檔案格式資料，建立 Audio Queue
 4. 收到 parser 分析出的 packet，保存 packet
 5. packet 數量夠多的時候，enqueue buffer
 6. 收到 Audio Queue 播放完畢的通知，繼續 enqueue
*/
-(void)audioRelation {
    MPMediaQuery *mediaQuery = [[MPMediaQuery alloc] init];
    NSArray<MPMediaItem *> *songArray = [mediaQuery items];
    
    NSURL *songURL = [[songArray objectAtIndex:0] assetURL];
    
    NSError *error;
    NSDictionary *outputSetting;
    AVURLAsset *asset = [AVURLAsset assetWithURL:songURL];
    AVAssetReader *assetReader = [AVAssetReader assetReaderWithAsset:asset error:&error];
    AVAssetReaderTrackOutput *trackOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:[[asset tracks] objectAtIndex:0] outputSettings:outputSetting];
    
    [assetReader addOutput:trackOutput];
    [assetReader startReading];
    
    
    CMSampleBufferRef sampleBuffer = [trackOutput copyNextSampleBuffer];
    CMBlockBufferRef blockBuffer;
    AudioBufferList audioBufferList;
    
    CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer, NULL, &audioBufferList, sizeof(AudioBufferList), NULL, NULL, kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment, &blockBuffer);
    
    CFRelease(blockBuffer);
    CFRelease(sampleBuffer);
    
    
    
}

-(void)playStreamMp3 {
//    NSURL *streamURL = [[NSURL alloc] initWithString:@"http://picosong.com/pA3t"];
    NSURL *streamURL = [[NSURL alloc] initWithString:@"http://picosong.com/cdn/5db14bc849fca52f661dec94a0cd55dc.mp3"];
    simplePlayer = [[GWSimplePlayer alloc] initWithURL:streamURL];
//    [simplePlayer play];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSLog(@"DID appear");
    // Simple Ping
//    ping = [[SimplePing alloc] initWithHostName:@"192.168.50.1"];
//    [ping setAddressStyle:SimplePingAddressStyleICMPv4];
//    [ping setDelegate:self];
//    [ping start];
    
    // GWSimplePlayer
//    NSURL *streamURL = [[NSURL alloc] initWithString:@"http://picosong.com/cdn/5db14bc849fca52f661dec94a0cd55dc.mp3"];
//    NSURL *streamURL = [[NSURL alloc] initWithString:@"http://picosong.com/cdn/a063a24a5ee7e4bc3c580c9ae0c8a26c.mp3"];
//    NSURL *streamURL = [[NSURL alloc] initWithString:@"http://www.iwant-music.com/music/icd2_10_1.mp3"];
    NSURL *streamURL = [[NSURL alloc] initWithString:@"https://www.dropbox.com/s/hzmqkdby6a743jo/Rythem%20-%20ホウキ雲.mp3?dl=0#"];
    simplePlayer = [[GWSimplePlayer alloc] initWithURL:streamURL];
    [simplePlayer play];
}

-(void)sendPing {
    [ping sendPingWithData:nil];
}


#pragma mark - SimplePingDelegate
-(void)simplePing:(SimplePing *)pinger didStartWithAddress:(NSData *)address {
    NSLog(@"Did start with address = %@", [pinger hostName]);
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(sendPing) userInfo:nil repeats:YES];
}

-(void)simplePing:(SimplePing *)pinger didFailWithError:(NSError *)error {
    NSLog(@"Did failed wit error = %@", [error description]);
}

-(void)simplePing:(SimplePing *)pinger didReceivePingResponsePacket:(NSData *)packet sequenceNumber:(uint16_t)sequenceNumber {
    
    ICMPHeader icmp;
    [packet getBytes:&icmp length:sizeof(ICMPHeader)];
    
    NSLog(@"Did receive ping = %@, number = %d, code = %hhu", [pinger hostName], sequenceNumber, icmp.code);
    
    
}

-(void)simplePing:(SimplePing *)pinger didReceiveUnexpectedPacket:(NSData *)packet {
    NSLog(@"Did receive unexpect = %@", [pinger hostName]);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
