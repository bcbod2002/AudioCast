//
//  GWSimplePlayer.h
//  AudioCast
//
//  Created by Goston on 27/03/2017.
//  Copyright © 2017 Goston. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface GWSimplePlayer : NSObject

/**
 <#Description#>

 @return <#return value description#>
 */
-(instancetype)init;

/**
 <#Description#>

 @param url <#url description#>
 @return <#return value description#>
 */
-(instancetype)initWithURL:(NSURL *)url;

/**
 <#Description#>
 */
-(void)play;

/**
 <#Description#>

 @param data <#data description#>
 */
-(void)playAudioWithData:(NSData *)data;

/**
 <#Description#>
 */
-(void)pause;

@property (readonly, getter=isStopped) BOOL stopped;

@end
