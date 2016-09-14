//
//  HMBluetoothBlock.h
//  Pods
//
//  Created by 何霞雨 on 16/9/8.
//
//

#import <Foundation/Foundation.h>


@class HMBluetooth;
@class HMDevice;

#pragma mark - about central blocks

/**
 *  扫描设备的回调
 *
 *  @param device state [0=正常结束,1=搜索中,-1=错误]
 *  @param devices 设备数组
 */
typedef void (^ScanDevicesCompleteBlock)(NSArray<HMDevice *> *devices,NSError *err,NSInteger state);

/**
 *  连接设备的回调
 *
 *  @param device 设备
 *  @param err 错误信息
 */
typedef void (^ConnectionDeviceBlock)(CBPeripheral *device, NSError *err);

/**
 *  发现服务和特征的回调
 *
 *  @param serviceArray        服务数组
 *  @param characteristicArray 特征数组
 *  @param err                 错误信息
 */
typedef void (^ServiceAndCharacteristicBlock)(NSArray *serviceArray, NSArray *characteristicArray, NSError *err);


#pragma mark - about peripheral blocks

/**
 *  从Characteristic读取数据的回调
 *
 *  @param peripheral
 *  @param characteristic
 *  @param error
 */
typedef void (^PeripheralReadValueForCharacteristicBlock)(CBPeripheral *peripheral,CBCharacteristic *characteristic,NSError *error,NSData *value);

/**
 *  向Characteristic写入数据的回调
 *
 *  @param peripheral
 *  @param characteristic
 *  @param error
 *
 *  @return
 */
typedef void (^PeripheralWriteValueForCharacteristicsBlock)(CBPeripheral *peripheral,CBCharacteristic *characteristic,NSError *error);

/**
 *  从Characteristic监听数据的回调
 *
 *  @param peripheral
 *  @param characteristic
 *  @param error
 */
typedef void (^PeripheralNotifyValueForCharacteristicsBlock)(CBPeripheral *peripheral,CBCharacteristic *characteristic,NSError *error,NSData *value);


/**
 *  读取当前的信号的回调
 *
 *  @param peripheral
 *  @param RSSI
 *  @param error
 */
typedef void (^PeripheralReadRSSIBlock)(CBPeripheral *peripheral,NSNumber *RSSI, NSError *error);

/**
 *  获取当前mac地址
 */
typedef void (^GetAddressCompleteBlock)(HMDevice *device);

