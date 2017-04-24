//
//  BluetoothViewController.m
//  AudioCast
//
//  Created by Goston on 02/04/2017.
//  Copyright © 2017 Goston. All rights reserved.
//

#import "BluetoothViewController.h"

#import "GWSimplePlayer.h"

@interface BluetoothViewController () <GWBluetoothCentralDelegate, GWBluetoothPeripheralDelegate> {
    GWBluetoothCentral *central;
    GWBluetoothPeripheral *peripheral;
    
    GWSimplePlayer *simplePlayer;
    NSData *mediaData;
}

@end

@implementation BluetoothViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
    
    [self loadMedia];
    
    simplePlayer = [[GWSimplePlayer alloc] init];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)loadMedia {
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *myFile = [mainBundle pathForResource:@"Rythem" ofType:@"mp3"];
    mediaData = [NSData dataWithContentsOfFile:myFile];
}


#pragma mark - IBOutlet Action
- (IBAction)centralButtonAction:(id)sender {
    central = [[GWBluetoothCentral alloc] initWithDelegate:self];
    [_modeLabel setText:@"Central Mode"];
}

- (IBAction)peripheralButtonAction:(id)sender {
    peripheral = [[GWBluetoothPeripheral alloc] initWithDelegate:self];
    [_modeLabel setText:@"Peropheral Mode"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        sleep(5);
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Start advertisement Data");
            [peripheral startAdvertisementData];
        });
    });
}

- (IBAction)senAudioButtonAction:(id)sender {
    NSLog(@"_media lenfht = %ld", [mediaData length]);
    NSUInteger dataLength = [mediaData length];
    NSMutableArray *dataArray = [[NSMutableArray alloc] init];
    NSUInteger splitedSize = 10 * 1024;
    NSUInteger dataCount = (dataLength / splitedSize) + 1;
    for (NSUInteger i = 0; i < dataCount; ++i) {
        
        NSUInteger offset = i * splitedSize;
        NSUInteger dataSize = dataLength - offset > splitedSize ? splitedSize : dataLength - offset;
        
        NSData *splitData = [NSData dataWithBytesNoCopy:(uint8_t *)[mediaData bytes] + (i * splitedSize) length:dataSize freeWhenDone:NO];
        [dataArray addObject:splitData];
    }
    
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        for (NSData *splitedData in dataArray) {
//            [_mediaData sendMediaData:splitedData];
//            [peripheral sendMediaData:splitedData];
            [peripheral sendMediaData:[@"QWERTTT" dataUsingEncoding:NSUTF8StringEncoding]];
            dispatch_async(dispatch_get_main_queue(), ^{
//                static dispatch_once_t onceToken;
//                dispatch_once(&onceToken, ^{
////                    usleep([mediaData averageTimeStamp] * 1000);
//                });
//                [simplePlayer playAudioWithData:splitedData];
            });
        }
//    });
}

#pragma mark - GWBluetoothCentralDelegate
-(void)didConnectDevice:(NSString *)deviceName {
    [_modeLabel setText:[NSString stringWithFormat:@"Central mode : connected %@", deviceName]];
    NSLog(@"Central Did connected to %@", deviceName);
}

-(void)didReceiveData:(NSData *)data FromDevice:(NSString *)deviceName {
    [simplePlayer playAudioWithData:data];
    [_receiveTextView setText:[NSString stringWithFormat:@"%@-----%ld", deviceName, [data length]]];
    NSLog(@"Central did receive data from = %@", deviceName);
    
}

#pragma mark - GWBluetoothPeripheralDelegate
-(void)didUpdateState {
    NSLog(@"Peropheral did update state");
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
