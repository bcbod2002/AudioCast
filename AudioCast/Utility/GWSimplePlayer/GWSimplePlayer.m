//
//  GWSimplePlayer.m
//  AudioCast
//
//  Created by Goston on 27/03/2017.
//  Copyright © 2017 Goston. All rights reserved.
//

#import "GWSimplePlayer.h"

static void GWAudioFileStreamPropertyListener(void * inClientData,
                                              AudioFileStreamID inAudioFileStream,
                                              AudioFileStreamPropertyID inPropertyID,
                                              UInt32 *ioFlags);

static void GWAudioFileStreamPacketsCallback(void * inClientData,
                                             UInt32 inNumberBytes,
                                             UInt32 inNumberPackets,
                                             const void * inInputData,
                                             AudioStreamPacketDescription *inPacketDescriptions);

static void GWAudioQueueOutputCallback(void * inUserData,
                                       AudioQueueRef inAudioQueue,
                                       AudioQueueBufferRef inBuffer);

static void GWAudioQueueRunnungListener(void * inUserData,
                                        AudioQueueRef inAudioQueue,
                                        AudioQueuePropertyID inID);

@interface GWSimplePlayer() <NSURLConnectionDelegate, NSURLConnectionDataDelegate> {
//    NSURLSession *urlSession;
//    NSURLSessionDataTask *dataTask;

    NSURLConnection *urlConnection;
    
    struct {
        BOOL stopped;
        BOOL loaded;
    }PlayerStatus;
    
    AudioFileStreamID audioFileStreamID;
    AudioQueueRef outputQueue;
    AudioStreamBasicDescription streamDescription;
    NSMutableArray *packetsArray;
    size_t readHead;
}

-(double) packetPerSecond;

@end

@implementation GWSimplePlayer

-(instancetype)init {
    self = [super init];
    if (self) {
        NSError *audioSessionError = nil;
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&audioSessionError];
        [[AVAudioSession sharedInstance] setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&audioSessionError];
        PlayerStatus.stopped = NO;
        packetsArray = [[NSMutableArray alloc] init];
        
        AudioFileStreamOpen((__bridge void * _Nullable)(self), GWAudioFileStreamPropertyListener, GWAudioFileStreamPacketsCallback, 0, &audioFileStreamID);
    }
    return self;
}

-(instancetype)initWithURL:(NSURL *)url {
    self = [super init];
    if (self) {
        PlayerStatus.stopped = NO;
        packetsArray = [[NSMutableArray alloc] init];
        
//        AudioFileStreamOpen((__bridge void * _Nullable)(self), GWAudioFileStreamPropertyListener, GWAudioFileStreamPacketsCallback, kAudioFileMP3Type, &audioFileStreamID);
        AudioFileStreamOpen((__bridge void * _Nullable)(self), GWAudioFileStreamPropertyListener, GWAudioFileStreamPacketsCallback, kAudioFileM4AType, &audioFileStreamID);
        urlConnection = [[NSURLConnection alloc] initWithRequest:[NSURLRequest requestWithURL:url] delegate:self];
    }
    
    return self;
}

- (void)dealloc {
    AudioQueueReset(outputQueue);
    AudioFileClose(audioFileStreamID);
    [urlConnection cancel];
}

-(double)packetPerSecond {
    if (streamDescription.mFramesPerPacket) {
        return streamDescription.mSampleRate / streamDescription.mFramesPerPacket;
    }
    
    return 48000.0 / 1152.0;
}

-(void)play {
    AudioQueueStart(outputQueue, NULL);
}

-(void)playAudioWithData:(NSData *)data {
//    NSLog(@"Audio Length = %lu", (unsigned long)[data length]);
    AudioFileStreamParseBytes(audioFileStreamID, (UInt32)[data length], [data bytes], 0);
//    OSStatus status = AudioFileStreamParseBytes(audioFileStreamID, (UInt32)[data length], [data bytes], kAudioFileStreamParseFlag_Discontinuity);
//    assert(status = noErr);
}

-(void)pause {
    AudioQueuePause(outputQueue);
}

#pragma mark - NSURLConnectionDataDelegate

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        if ([(NSHTTPURLResponse *) response statusCode] != 200) {
            NSLog(@"Http code = %ld", [(NSHTTPURLResponse *) response statusCode]);
            [connection cancel];
            PlayerStatus.stopped = YES;
        }
    }
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    printf("GWSimplePlayer Audio Length = %lu\n", (unsigned long)[data length]);
    AudioFileStreamParseBytes(audioFileStreamID, (UInt32)[data length], [data bytes], 0);
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection {
    PlayerStatus.loaded = YES;
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"Failed to load dada = %@", [error description]);
    PlayerStatus.stopped = YES;
}

#pragma mark - Audio parser and audio queue callbacks
- (void)_enqueueDataWithPacketsCount: (size_t) inPacketCount {
    NSLog(@"%s", __PRETTY_FUNCTION__ );
    if (!outputQueue) {
        return;
    }
    
    if (readHead == [packetsArray count]) {
        AudioQueueStop(outputQueue, false);
        PlayerStatus.stopped = YES;
        return;
    }
    
    if (readHead + inPacketCount >= [packetsArray count]) {
        inPacketCount = [packetsArray count] - readHead;
    }
    
    UInt32 totalSize = 0;
    UInt32 index;
    
    for (index = 0; index < inPacketCount; ++index) {
        NSData *packet = packetsArray[index + readHead];
        totalSize += packet.length;
    }
    
    OSStatus status = 0;
    AudioQueueBufferRef buffer;
    status = AudioQueueAllocateBuffer(outputQueue, totalSize, &buffer);
    assert(status == noErr);
    buffer->mAudioDataByteSize = totalSize;
    buffer->mUserData = (__bridge void * _Nullable)(self);
    
    AudioStreamPacketDescription *packetDescription = calloc(inPacketCount, sizeof(AudioStreamPacketDescription));
    totalSize = 0;
    
    for (index = 0; index < inPacketCount; ++index) {
        size_t readIndex = index + readHead;
        NSData *packet = packetsArray[readIndex];
        memcpy(buffer->mAudioData + totalSize, packet.bytes, packet.length);
        
        AudioStreamPacketDescription description;
        description.mStartOffset = totalSize;
        description.mDataByteSize = (UInt32)packet.length;
        description.mVariableFramesInPacket = 0;
        totalSize += packet.length;
        memcpy(&(packetDescription[index]), &description, sizeof(AudioStreamPacketDescription));
    }
    
    status = AudioQueueEnqueueBuffer(outputQueue, buffer, (UInt32)inPacketCount, packetDescription);
    free(packetDescription);
    readHead += inPacketCount;
}

- (void) _createAudioQueueWithAudioStreamDescription:(AudioStreamBasicDescription *)audioStreamBasicDescription {
    NSLog(@"OOOO");
    memcpy(&streamDescription, audioStreamBasicDescription, sizeof(audioStreamBasicDescription));
    OSStatus status = AudioQueueNewOutput(audioStreamBasicDescription, GWAudioQueueOutputCallback, (__bridge void * _Nullable)(self), CFRunLoopGetCurrent(), kCFRunLoopCommonModes, 0, &outputQueue);
    assert(status == noErr);
    status = AudioQueueAddPropertyListener(outputQueue, kAudioQueueProperty_IsRunning, GWAudioQueueRunnungListener, (__bridge void * _Nullable)(self));
    AudioQueuePrime(outputQueue, 0, NULL);
    AudioQueueStart(outputQueue, NULL);
}

- (void) _storePacketsWithNumberOfBytes:(UInt32)inNumberBytes
                        numberOfPackets:(UInt32)inNumberPackets
                              inputData:(const void *)inInputData
                     packetDescriptions:(AudioStreamPacketDescription *)inPacketDescription {
    for (int i = 0; i < inNumberPackets; ++i) {
        SInt64 packetStart = inPacketDescription[i].mStartOffset;
        UInt32 packetSize = inPacketDescription[i].mDataByteSize;
        assert(packetSize > 0);
        NSData *packet = [NSData dataWithBytes:inInputData + packetStart length:packetSize];
        [packetsArray addObject:packet];
    }
    
    if (readHead == 0 && [packetsArray count] > (int)([self packetPerSecond] * 3)) {
        AudioQueueStart(outputQueue, NULL);
        [self _enqueueDataWithPacketsCount:(int)([self packetPerSecond] * 3)];
    }
}

- (void) _audioQueueDidStart {
    NSLog(@"Audio Queue did start");
}

- (void) _audiuoQueueDidStop {
    NSLog(@"Audio Queue did stop");
}


#pragma mark - Properties
-(BOOL)isStopped {
    return PlayerStatus.stopped;
}

@end


void GWAudioFileStreamPropertyListener(void * inClientData,
                                       AudioFileStreamID inAudioFileStream,
                                       AudioFileStreamPropertyID inPropertyID,
                                       UInt32 *ioFlags) {
    GWSimplePlayer *self = (__bridge GWSimplePlayer *)inClientData;
    if (inPropertyID == kAudioFileStreamProperty_DataFormat) {
    
        UInt32 dataSize = 0;
        OSStatus status = 0;
        AudioStreamBasicDescription audioStreamDescription;
        Boolean writable = false;
        status = AudioFileStreamGetPropertyInfo(inAudioFileStream, kAudioFileStreamProperty_DataFormat, &dataSize, &writable);
        status = AudioFileStreamGetProperty(inAudioFileStream, kAudioFileStreamProperty_DataFormat, &dataSize, &audioStreamDescription);
        
        NSLog(@"mSampleRate: %f", audioStreamDescription.mSampleRate);
        NSLog(@"mFormatID: %u", audioStreamDescription.mFormatID);
        NSLog(@"mFormatFlags: %u", audioStreamDescription.mFormatFlags);
        NSLog(@"mBytesPerPacket: %u", audioStreamDescription.mBytesPerPacket);
        NSLog(@"mFramesPerPacket: %u", audioStreamDescription.mFramesPerPacket);
        NSLog(@"mBytesPerFrame: %u", audioStreamDescription.mBytesPerFrame);
        NSLog(@"mChannelsPerFrame: %u", audioStreamDescription.mChannelsPerFrame);
        NSLog(@"mBitsPerChannel: %u", audioStreamDescription.mBitsPerChannel);
        NSLog(@"mReserved: %u", audioStreamDescription.mReserved);
        
        [self _createAudioQueueWithAudioStreamDescription:&audioStreamDescription];
    }
    else if (inPropertyID == kAudioFileStreamProperty_FileFormat) {
//        OSStatus status = 0;
//        UInt32 dataSize = 0;
//        AudioStreamBasicDescription audioStreamDescription;
//        status = AudioFileStreamGetProperty(inAudioFileStream, kAudioFileStreamProperty_FileFormat, &dataSize, &audioStreamDescription);
    }
}

void GWAudioFileStreamPacketsCallback(void * inClientData,
                                      UInt32 inNumberBytes,
                                      UInt32 inNumberPackets,
                                      const void * inInputData,
                                      AudioStreamPacketDescription *inPacketDescriptions) {
    GWSimplePlayer *self = (__bridge GWSimplePlayer *)inClientData;
    [self _storePacketsWithNumberOfBytes:inNumberBytes numberOfPackets:inNumberPackets inputData:inInputData packetDescriptions:inPacketDescriptions];
}

static void GWAudioQueueOutputCallback(void * inUserData,
                                       AudioQueueRef inAudioQueue,
                                       AudioQueueBufferRef inBuffer) {
    AudioQueueFreeBuffer(inAudioQueue, inBuffer);
    GWSimplePlayer *self = (__bridge GWSimplePlayer *)inUserData;
    [self _enqueueDataWithPacketsCount:(int)[self packetPerSecond] * 5];
}

static void GWAudioQueueRunnungListener(void * inUserData,
                                        AudioQueueRef inAudioQueue,
                                        AudioQueuePropertyID inID) {
    GWSimplePlayer *self = (__bridge GWSimplePlayer *)inUserData;
    UInt32 dataSize;
    OSStatus status = 0;
    status = AudioQueueGetPropertySize(inAudioQueue, inID, &dataSize);
    if (inID == kAudioQueueProperty_IsRunning) {
        UInt32 running;
        status = AudioQueueGetProperty(inAudioQueue, inID, &running, &dataSize);
        running ? [self _audioQueueDidStart] : [self _audiuoQueueDidStop];
    }
}
