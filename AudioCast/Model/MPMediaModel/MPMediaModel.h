//
//  MPMediaModel.h
//  AudioCast
//
//  Created by Goston on 29/03/2017.
//  Copyright © 2017 Goston. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MediaPlayer/MPMediaQuery.h>

@interface MPMediaModel : NSObject

@property(strong, nonatomic) NSArray<MPMediaItem *> *mediaItemsArray;

-(void)getMediaRawData:(MPMediaItem *)mediaItem :(void (^)(NSData* mediaData))success;

@end
