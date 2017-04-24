//
//  GWBluetoothPeripheral.m
//  AudioCast
//
//  Created by Goston on 03/04/2017.
//  Copyright © 2017 Goston. All rights reserved.
//

#import "GWBluetoothPeripheral.h"
#import <CoreBluetooth/CoreBluetooth.h>

#define TRANSFER_SERVICE_UUID           @"E20A39F4-73F5-4BC4-A12F-17D1AD07A961"
#define TRANSFER_CHARACTERISTIC_UUID    @"08590F7E-DB05-467E-8757-72F6FAEB13D4"
#define NOTIFY_MTU      20

@interface GWBluetoothPeripheral () <CBPeripheralManagerDelegate> {
    CBPeripheralManager *peripheralManager;
    CBMutableCharacteristic *transferCharacteristic;
    NSData *sentData;
    NSInteger sentDataIndex;
}

@end

@implementation GWBluetoothPeripheral

-(instancetype)init {
    self = [super init];
    if (self) {
        peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
    }
    return self;
}

-(instancetype)initWithDelegate:(id)delegate {
    self = [self init];
    _delegate = delegate;
    
    return self;
}

-(void)dealloc {
    [peripheralManager stopAdvertising];
}

-(void)startAdvertisementData {
    [peripheralManager startAdvertising:@{ CBAdvertisementDataServiceUUIDsKey : @[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]] }];
}

-(void)sendData {
    static BOOL sendEOM = NO;
    if (sendEOM) {
        BOOL didSend = [peripheralManager updateValue:[@"EOM" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:transferCharacteristic onSubscribedCentrals:nil];
        if (didSend) {
            sendEOM = NO;
            
            NSLog(@"Sent : EOM");
        }
        return;
    }
    
    if (sentDataIndex > [sentData length]) {
        return;
    }
    
    BOOL didSend = YES;
    
    while (didSend) {
        NSInteger amountToSend = [sentData length] - sentDataIndex;
        
        if (amountToSend > NOTIFY_MTU) {
            amountToSend = NOTIFY_MTU;
        }
        NSData *chunk = [NSData dataWithBytes:sentData.bytes + sentDataIndex length:amountToSend];
        
        didSend = [peripheralManager updateValue:chunk forCharacteristic:transferCharacteristic onSubscribedCentrals:nil];
        
        if (!didSend) {
            return;
        }
        
        NSString *stringFromData = [[NSString alloc] initWithData:chunk encoding:NSUTF8StringEncoding];
        NSLog(@"Sent : %@", stringFromData);
        
        sentDataIndex += amountToSend;
        
        if (sentDataIndex >= [sentData length]) {
            sendEOM = YES;
            
            BOOL isSentEom = [peripheralManager updateValue:[@"EOM" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:transferCharacteristic onSubscribedCentrals:nil];
            if (isSentEom) {
                sendEOM = NO;
                NSLog(@"Sent : EOM");
            }
            return;
        }
    }
}

-(void)sendMediaData:(NSData *)mediaData {
    NSLog(@"mediaPath = %ld",[mediaData length]);
    BOOL isSuccess = [peripheralManager updateValue:mediaData
                 forCharacteristic:transferCharacteristic
              onSubscribedCentrals:nil];
    if (isSuccess) {
        NSLog(@"Send data Succed");
        return;
    }
    else {
        NSLog(@"Send data failed");
    }
}

#pragma mark - CBPeripheralManagerDelegate
-(void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    if ([peripheral state] != CBManagerStatePoweredOn) {
        return;
    }
    
    NSLog(@"Perpheral MAnager powered on");
    
    transferCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]
                                                                properties:CBCharacteristicPropertyNotify
                                                                     value:nil
                                                               permissions:CBAttributePermissionsReadable];
    
    CBMutableService *transferService = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]
                                                                       primary:YES];
    
    [transferService setCharacteristics:@[transferCharacteristic]];
    [peripheralManager addService:transferService];
    
    if ([_delegate respondsToSelector:@selector(didUpdateState)]) {
        [_delegate didUpdateState];
    }
}

-(void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic {
    NSLog(@"Central subscribed to characteristic");
    
//    sentData = [@"QWERT12333" dataUsingEncoding:NSUTF8StringEncoding];
//    sentDataIndex = 0;
//    
//    [self sendData];
}

-(void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic {
    NSLog(@"Central unsubscribed from characteristic");
}

-(void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral {
    NSLog(@"peripheralManagerIsReadyToUpdateSubscribers");
//    [self sendData];
}
@end
