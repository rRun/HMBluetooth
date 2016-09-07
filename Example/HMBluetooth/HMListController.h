//
//  HMListController.h
//  HMBluetooth
//
//  Created by 何霞雨 on 16/8/12.
//  Copyright © 2016年 hexy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HMBluetooth.h"
@interface HMListController : UIViewController

@property (nonatomic,strong)HMBluetooth *hmB;
@property (nonatomic,strong)CBPeripheral *cb;

@end
