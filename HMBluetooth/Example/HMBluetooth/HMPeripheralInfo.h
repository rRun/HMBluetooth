//
//  HMPeripheralInfo.h
//  HMBluetooth
//
//  Created by 何霞雨 on 16/8/12.
//  Copyright © 2016年 hexy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface HMPeripheralInfo : NSObject

@property (nonatomic,strong) CBUUID *serviceUUID;
@property (nonatomic,strong) NSMutableArray *characteristics;

@end
