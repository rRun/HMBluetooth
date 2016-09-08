//
//  HMDevice.h
//  Pods
//
//  Created by 何霞雨 on 16/9/8.
//
//

#import <CoreBluetooth/CoreBluetooth.h>

@interface HMDevice : NSObject

@property (nonatomic,strong)CBPeripheral *peripheral;
@property (nonatomic,strong)NSString * macAddress;

@end
