//
//  HMPeripheralInfo.m
//  HMBluetooth
//
//  Created by 何霞雨 on 16/8/12.
//  Copyright © 2016年 hexy. All rights reserved.
//

#import "HMPeripheralInfo.h"


@implementation HMPeripheralInfo

-(instancetype)init{
    self = [super init];
    if (self) {
        _characteristics = [[NSMutableArray alloc]init];
    }
    return self;
}

@end
