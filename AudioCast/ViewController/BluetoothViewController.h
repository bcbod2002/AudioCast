//
//  BluetoothViewController.h
//  AudioCast
//
//  Created by Goston on 02/04/2017.
//  Copyright © 2017 Goston. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "GWBluetoothCentral.h"
#import "GWBluetoothPeripheral.h"

@interface BluetoothViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *modeLabel;
@property (weak, nonatomic) IBOutlet UITextView *receiveTextView;

@end
