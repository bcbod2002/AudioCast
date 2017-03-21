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

@interface ViewController () {
    AVAudioPlayer *player;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
    [MPMediaLibrary requestAuthorization:^(MPMediaLibraryAuthorizationStatus status) {
        switch (status) {
            case MPMediaLibraryAuthorizationStatusDenied:
                NSLog(@"Deny");
                break;
            case MPMediaLibraryAuthorizationStatusRestricted:
                NSLog(@"Restricted");
                break;
            case MPMediaLibraryAuthorizationStatusAuthorized:
                NSLog(@"Authorized");
                break;
            case MPMediaLibraryAuthorizationStatusNotDetermined:
                NSLog(@"Not Determine");
                break;
                
            default:
                break;
        }
    }];
    
    MPMediaQuery *mediaQuery = [[MPMediaQuery alloc] init];
    NSArray<MPMediaItem *> *songsArray = [mediaQuery items];
    
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    MPMediaItem *mediaItem = [songsArray objectAtIndex:0];
    NSLog(@"mediaItem = %@", [mediaItem valueForProperty:MPMediaItemPropertyAssetURL]);
    NSError *error;
    player = [[AVAudioPlayer alloc] initWithContentsOfURL:[mediaItem assetURL] error:&error];

    [player play];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
