//
//  MPMediaModel.m
//  AudioCast
//
//  Created by Goston on 29/03/2017.
//  Copyright © 2017 Goston. All rights reserved.
//

#import "MPMediaModel.h"
#import <AVFoundation/AVFoundation.h>


@implementation MPMediaModel

-(instancetype)init {
    self = [super init];
    if (self) {
        MPMediaQuery *mediaQueary = [[MPMediaQuery alloc] init];
        _mediaItemsArray = [mediaQueary items];
        NSLog(@"_mediaItemsArray = %@", [_mediaItemsArray valueForKey:@"assetURL"]);
    }
    return self;
}

-(void)getMediaRawData:(MPMediaItem *)mediaItem :(void (^)(NSData* mediaData))success{
    AVAssetExportSession *exportSession = [self createSongExporter:mediaItem];
    if (exportSession) {
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            switch ([exportSession status]) {
                case AVAssetExportSessionStatusCompleted:
                    success([NSData dataWithContentsOfURL:[exportSession outputURL]]);
                    break;
                    
                default:
                    NSLog(@"exportSession status = %ld", (long)[exportSession status]);
                    break;
            }
        }];
    }
    else {
        NSLog(@"Exportsession is nil");
    }
}

-(AVAssetExportSession *)createSongExporter:(MPMediaItem *)mediaItem {
    if ([mediaItem assetURL]) {
        AVURLAsset *urlAsset = [[AVURLAsset alloc] initWithURL:[mediaItem assetURL] options:nil];
        AVAssetExportSession * exportSession = [[AVAssetExportSession alloc] initWithAsset:urlAsset presetName:AVAssetExportPresetAppleM4A];
        [exportSession setOutputFileType:@"com.apple.m4a-audio"];
        
        NSString *documentDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *fileName = [self createExportFileName];
        [exportSession setOutputURL:[[NSURL fileURLWithPath:documentDir] URLByAppendingPathComponent:fileName]];
        
        return exportSession;
    }
    else {
        return nil;
    }
}

-(NSString *)createExportFileName {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyMMddhhmmss"];
    NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
    
    return [NSString stringWithFormat:@"%@.m4a", dateString];
}

-(void)removeExportedFile:(NSURL *)url {
    NSFileManager *manager = [[NSFileManager alloc] init];
    NSError *error;
    [manager removeItemAtURL:url error:&error];
    
    NSLog(@"remove exported file error = %@", [error description]);
}

@end
