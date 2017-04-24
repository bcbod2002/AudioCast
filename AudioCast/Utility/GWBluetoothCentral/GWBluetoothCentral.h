//
//  GWBluetoothCentral.h
//  AudioCast
//
//  Created by Goston on 03/04/2017.
//  Copyright © 2017 Goston. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@class GWBluetoothCentral;
@protocol GWBluetoothCentralDelegate <NSObject>

@optional
-(void)didReceiveData:(NSData *)data FromDevice:(NSString *)deviceName;
-(void)didConnectDevice:(NSString *)deviceName;
@end

@interface GWBluetoothCentral : NSObject

@property (nonatomic, weak) id <GWBluetoothCentralDelegate> delegate;

-(instancetype)initWithDelegate:(id)delegate;

@end
