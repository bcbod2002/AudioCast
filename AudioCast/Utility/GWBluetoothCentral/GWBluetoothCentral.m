//
//  GWBluetoothCentral.m
//  AudioCast
//
//  Created by Goston on 03/04/2017.
//  Copyright © 2017 Goston. All rights reserved.
//


//http://cms.35g.tw/coding/藍牙-ble-corebluetooth-初探/
//http://cms.35g.tw/coding/corebluetooth-central-7/


#import "GWBluetoothCentral.h"

#define TRANSFER_SERVICE_UUID           @"E20A39F4-73F5-4BC4-A12F-17D1AD07A961"
#define TRANSFER_CHARACTERISTIC_UUID    @"08590F7E-DB05-467E-8757-72F6FAEB13D4"

@interface GWBluetoothCentral() <CBCentralManagerDelegate, CBPeripheralDelegate> {
    CBCentralManager *bluetoothCentral;
    CBPeripheral *discoveredPeriphral;
//    NSMutableData *mutableData;
}

@end

@implementation GWBluetoothCentral

-(instancetype)init {
    self = [super init];
    if (self) {
        bluetoothCentral = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
//        mutableData = [[NSMutableData alloc] init];
    }
    
    return self;
}

-(instancetype)initWithDelegate:(id)delegate {
    self = [self init];
    _delegate = delegate;
    return self;
}

-(void)scanOtherDevices {
    [bluetoothCentral scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]] options:@{CBCentralManagerScanOptionAllowDuplicatesKey: @YES}];
    NSLog(@"Start scan");
}

-(void)cleanUp {
    if ([discoveredPeriphral services] != nil) {
        for (CBService *service in [discoveredPeriphral services]) {
            if ([service characteristics] != nil) {
                for (CBCharacteristic *characteristic in [service characteristics]) {
                    if ([[characteristic UUID] isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]]) {
                        if ([characteristic isNotifying]) {
                            [discoveredPeriphral setNotifyValue:NO forCharacteristic:characteristic];
                            return;
                        }
                    }
                }
            }
        }
    }
}

-(void)sendMediaData:(NSData *)mediaData {
    
}

#pragma mark - CBCentralManagerDelegate
-(void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if ([central state] != CBManagerStatePoweredOn) {
        return;
    }
    
    [self scanOtherDevices];
}

-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
    NSLog(@"Discovered !!!!");
    if ([RSSI integerValue] > -15) {
        return;
    }
    if ([RSSI integerValue] < -35) {
        return;
    }
    
    NSLog(@"Discovered %@ at %@", [peripheral name], RSSI);
    
    if (discoveredPeriphral != peripheral) {
        discoveredPeriphral = peripheral;

        NSLog(@"Connecting to peripheral %@", peripheral);
        
        [bluetoothCentral connectPeripheral:peripheral options:nil];
    }
}

-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"Failed to connect to %@. (%@)", peripheral, [error localizedDescription]);
    [self cleanUp];
}

-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"Peripheral Connected");
    
    [bluetoothCentral stopScan];
    NSLog(@"Stop scan");
    
//    [mutableData setLength:0];
    
    [peripheral setDelegate:self];
    
    [peripheral discoverServices:@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]]];
    if ([_delegate respondsToSelector:@selector(didConnectDevice:)]) {
        [_delegate didConnectDevice:[peripheral name]];
    }
}

#pragma mark - CBPeripheralDelegate
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    if (error) {
        NSLog(@"Error discovering services : %@", [error localizedDescription]);
        [self cleanUp];
        return;
    }
    
    for (CBService *service in [peripheral services]) {
        [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]] forService:service];
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if (error) {
        NSLog(@"Error discovering characteristics : %@", [error localizedDescription]);
        [self cleanUp];
        return;
    }
    
    for (CBCharacteristic *characteristic in [service characteristics]) {
        if ([[characteristic UUID] isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]]) {
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        NSLog(@"error discovering characteristics : %@", [error localizedDescription]);
    }
    
    NSString *stringFromData = [[NSString alloc] initWithData:[characteristic value] encoding:NSUTF8StringEncoding];
    if ([stringFromData isEqualToString:@"EOM"]) {
//        NSString *receiveString = [[NSString alloc] initWithData:mutableData encoding:NSUTF8StringEncoding];
//        NSLog(@"receive string = %@", receiveString);
        
        [peripheral setNotifyValue:NO forCharacteristic:characteristic];
        
        [bluetoothCentral cancelPeripheralConnection:peripheral];
    }
    
    if ([_delegate respondsToSelector:@selector(didReceiveData:FromDevice:)]) {
        [_delegate didReceiveData:[characteristic value] FromDevice:[peripheral name]];
    }
//    [mutableData appendData:[characteristic value]];
    
    NSLog(@"Received : %@", stringFromData);
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        NSLog(@"Error changing notification state : %@", [error localizedDescription]);
    }
    
    if (![[characteristic UUID] isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]]) {
        return;
    }
    
    
    if ([characteristic isNotifying]) {
        NSLog(@"Notification began on %@", characteristic);
    }
    else {
        NSLog(@"Notification stopped on %@. Disconnectiong", characteristic);
        [bluetoothCentral cancelPeripheralConnection:peripheral];
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didModifyServices:(NSArray<CBService *> *)invalidatedServices {
    NSLog(@"Modify service = %@", invalidatedServices);
}

-(void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"Peripheral Disconnected");
    discoveredPeriphral = nil;
    
    [self scanOtherDevices];
}

@end
