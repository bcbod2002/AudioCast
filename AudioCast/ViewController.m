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
#import "GBPing.h"

@interface ViewController () <NSStreamDelegate, GBPingDelegate> {
    AVAudioPlayer *player;
    SimplePing *ping;
    GBPing *gPing;
    
    GWSimplePlayer *simplePlayer;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
//    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//    [dateFormatter setDateFormat:@"yyyyMMddHHmmssss"];
//    NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
//    NSLog(@"dateString = %@", dateString);
//    
//    long double time1 = ([[NSDate date] timeIntervalSince1970] * 1000);
////    [NSThread sleepForTimeInterval:0.5];
//    long double time2 = ([[NSDate date] timeIntervalSince1970] * 1000);
////    [NSThread sleepForTimeInterval:0.5];
//    long double time3 = ([[NSDate date] timeIntervalSince1970] * 1000);
////    [NSThread sleepForTimeInterval:0.5];
//    long double time4 = ([[NSDate date] timeIntervalSince1970] * 1000);
////    [NSThread sleepForTimeInterval:0.5];
//    long double time5 = ([[NSDate date] timeIntervalSince1970] * 1000);
//    
//    NSLog(@"ReferenceDate = %Lf",time1);
//    NSLog(@"ReferenceDate = %Lf",time2);
//    NSLog(@"ReferenceDate = %Lf",time2 - time1);
//    NSLog(@"ReferenceDate = %Lf",time3 - time2);
//    NSLog(@"ReferenceDate = %Lf",time4 - time3);
//    NSLog(@"ReferenceDate = %Lf",time5 - time4);
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
    NSLog(@"DID appear QQ");
    // Simple Ping
//    ping = [[SimplePing alloc] initWithHostName:@"192.168.50.1"];
//    [ping setAddressStyle:SimplePingAddressStyleICMPv4];
//    [ping setDelegate:self];
//    [ping start];
    
    // GWSimplePlayer
//    NSURL *streamURL = [[NSURL alloc] initWithString:@"http://picosong.com/cdn/5db14bc849fca52f661dec94a0cd55dc.mp3"];
//    NSURL *streamURL = [[NSURL alloc] initWithString:@"http://picosong.com/cdn/a063a24a5ee7e4bc3c580c9ae0c8a26c.mp3"];
//    NSURL *streamURL = [[NSURL alloc] initWithString:@"http://www.iwant-music.com/music/icd2_10_1.mp3"];
    NSURL *streamURL = [[NSURL alloc] initWithString:@"http://picosong.com/cdn/f33bd2cf027b74d163ed2ec90d769787.mp3"];
//    simplePlayer = [[GWSimplePlayer alloc] initWithURL:streamURL];
//    [simplePlayer play];
    
//    gPing = [[GBPing alloc] init];
//    [gPing setDelegate:self];
//    [gPing setHost:@"168.95.1.1"];
//    [gPing setTimeout:10];
//    [gPing setPingPeriod:0.9];
//    [gPing setupWithBlock:^(BOOL success, NSError *error) {
//        if (success) {
//            [gPing startPinging];
//        }
//        else {
//            NSLog(@"Setup failed");
//        }
//    }];
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


#pragma mark - GBPing
-(void)ping:(GBPing *)pinger didFailWithError:(NSError *)error {
    NSLog(@"Did fail with = %@", [error description]);
}

-(void)ping:(GBPing *)pinger didSendPingWithSummary:(GBPingSummary *)summary {
//    NSLog(@"Send = host = %@, sequence number = %ld, rtt = %f", [summary host], [summary sequenceNumber], [summary rtt]);
}

-(void)ping:(GBPing *)pinger didReceiveReplyWithSummary:(GBPingSummary *)summary {
//    NSLog(@"Reply = host = %@, sequence number = %ld, rtt = %f ms", [summary host], [summary sequenceNumber], [summary rtt] * 1000);
    NSLog(@"Summary = %@", summary);
}
@end
