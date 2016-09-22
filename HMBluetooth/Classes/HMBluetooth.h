//
//  HMBluetooth.h
//  Pods
//
//  Created by 何霞雨 on 16/8/11.
//
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

#import "BMPParser.h"
#import "GLSParser.h"

#import "BMPParserPrt.h"//获取血压计数据的回调
#import "GLSParserPrt.h"//获取血糖计数据的回调
#import "HMBluetoothBlock.h"//block回调

#import "HMDevice.h"

typedef NS_ENUM( NSInteger,DEVICE) {
    UNKOWN_DEVICE=0,
    BMP_DEVICE=1,//血压计
    GLS_DEVICE=2,//血糖仪
};

static NSString * NotiValueChange = @"ValueChange";
static NSString * ReadValueChange = @"ValueChanged";

@interface HMBluetooth : NSObject<CBPeripheralDelegate, CBCentralManagerDelegate>
/**
 *  管理者
 */
@property (nonatomic, strong, readonly) CBCentralManager *manager;
/**
 *  是否蓝牙可用
 */
@property (nonatomic, assign, readonly, getter = isReady)  BOOL Ready;
/**
 *  是否连接
 */
@property (nonatomic, assign, readonly, getter = isConnection)  BOOL Connection;

/**
 *  单例
 *
 *  @return
 */
+ (instancetype)sharedInstance;

#pragma mark - Scan Devices
/**
 *  开始扫描
 *
 *  @param timeout 扫描的超时范围
 *  @param block   回调
 */
- (void)startScanDevicesWithInterval:(NSUInteger)timeout WithFilter:(NSString *)filter CompleteBlock:(ScanDevicesCompleteBlock)block;
/**
 *  停止扫描
 */
- (void)stopScanDevices;

#pragma mark - Connect Devices
/**
 *  连接设备
 *
 *  @param device  设备
 *  @param timeout 连接的超时范围
 *  @param block   回调
 */
- (void)connectionWithDeviceUUID:(NSString *)uuid TimeOut:(NSUInteger)timeout CompleteBlock:(ConnectionDeviceBlock)block;
- (void)connectionWithDevice:(HMDevice *)device TimeOut:(NSUInteger)timeout CompleteBlock:(ConnectionDeviceBlock)block;
//队列连接
- (void)runloopConnectionWithDevice:(HMDevice *)device TimeOut:(NSUInteger)timeout CompleteBlock:(ConnectionDeviceBlock)block ;
/**
 *  断开连接
 */
- (void)disconnectionDevice;
//断开队列循环，直到最后一个停止
-(void)disconnectRunloopDevice;
#pragma mark - Service And Character
/**
 *  扫描服务和特征
 *
 *  @param timeout 发现的时间范围
 *  @param block   回调
 */
- (void)discoverServiceAndCharacteristicWithInterval:(NSUInteger)time CompleteBlock:(ServiceAndCharacteristicBlock)block;
/**
 *  写数据到连接中的设备
 *
 *  @param sUUID 服务UUID
 *  @param cUUID 特征UUID
 *  @param data  数据
 */
- (void)writeCharacteristicWithServiceUUID:(NSString *)sUUID CharacteristicUUID:(NSString *)cUUID data:(NSData *)data CompleteBlock:(PeripheralWriteValueForCharacteristicsBlock)block;

- (void)writeCharacteristicWithService:(CBService *)service Characteristic:(CBCharacteristic *)characteristic data:(NSData *)data CompleteBlock:(PeripheralWriteValueForCharacteristicsBlock)block;
/**
 *  设置通知
 *
 *  @param sUUID  服务UUID
 *  @param cUUID  特征UUID
 *  @param enable
 */
- (void)setNotificationForCharacteristicWithServiceUUID:(NSString *)sUUID CharacteristicUUID:(NSString *)cUUID enable:(BOOL)enable CompleteBlock:(PeripheralNotifyValueForCharacteristicsBlock)block;
/**
 *  设置通知
 *
 *  @param service  服务
 *  @param characteristic  特征
 *  @param enable
 */
-(void)setNotificationForCharacteristicWithService:(CBService *)service Characteristic:(CBCharacteristic *)characteristic enable:(BOOL)enable CompleteBlock:(PeripheralNotifyValueForCharacteristicsBlock)block;
/**
 *  读取特征中的数据
 *
 *  @param sUUID  服务UUID
 *  @param cUUID  特征UUID
 *  @param enable
 */
-(void)readCharacteristicWithServiceUUID:(NSString *)sUUID CharacteristicUUID:(NSString *)cUUID CompleteBlock:(PeripheralReadValueForCharacteristicBlock)block;

-(void)readCharacteristicWithService:(CBService *)service Characteristic:(CBCharacteristic *)characteristic  CompleteBlock:(PeripheralReadValueForCharacteristicBlock)block;
/*!
 *  读取设备信号
 *
 *	@discussion While connected, retrieves the current RSSI of the link.
 *
 *  @see		MPPeripheralRedRSSIBlock
 */
- (void)readRSSI:(nullable PeripheralReadRSSIBlock)block;

/**
 *  获取某个设备的mac地址
 *
 *  @param hmDevice
 *  @param block    
 */
-(void)getMacAddress:(HMDevice *)hmDevice Characteristics:(NSArray *)characteristicArray Block:(GetAddressCompleteBlock)block;
/*- (void)getMacAddress1:(HMDevice *)hmDevice Block:(GetAddressCompleteBlock)block;*/
#pragma mark - Load Parser
-(DEVICE )loadParserWithCharacteristic:(CBCharacteristic *)characteristic;
@end
