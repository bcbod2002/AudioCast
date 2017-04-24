//
//  GWBluetoothPeripheral.h
//  AudioCast
//
//  Created by Goston on 03/04/2017.
//  Copyright © 2017 Goston. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GWBluetoothPeripheral;
@protocol GWBluetoothPeripheralDelegate <NSObject>

@optional
-(void)didUpdateState;

@end

@interface GWBluetoothPeripheral : NSObject

@property (nonatomic, weak) id <GWBluetoothPeripheralDelegate> delegate;

-(instancetype)initWithDelegate:(id)delegate;

-(void)startAdvertisementData;
-(void)sendMediaData:(NSData *)mediaData;

@end
