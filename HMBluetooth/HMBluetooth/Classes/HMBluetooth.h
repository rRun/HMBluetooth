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

typedef NS_ENUM( NSInteger,DEVICE) {
    UNKOWN_DEVICE=0,
    BMP_DEVICE=1,//血压计
    GLS_DEVICE=2,//血糖仪
};

static NSString *const NotiValueChange = @"ValueChange";
/**
 *  扫描设备的回调
 *
 *  @param devices 设备数组
 */
typedef void (^ScanDevicesCompleteBlock)(NSArray *devices);
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
/**
 *  断开连接
 */
- (void)disconnectionDevice;

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
- (void)writeCharacteristicWithServiceUUID:(NSString *)sUUID CharacteristicUUID:(NSString *)cUUID data:(NSData *)data;
/**
 *  设置通知
 *
 *  @param sUUID  服务UUID
 *  @param cUUID  特征UUID
 *  @param enable
 */
- (void)setNotificationForCharacteristicWithServiceUUID:(NSString *)sUUID CharacteristicUUID:(NSString *)cUUID enable:(BOOL)enable;
/**
 *  读取特征中的数据
 *
 *  @param sUUID  服务UUID
 *  @param cUUID  特征UUID
 *  @param enable
 */
-(void)readCharacteristicWithServiceUUID:(NSString *)sUUID CharacteristicUUID:(NSString *)cUUID;

#pragma mark - Load Parser
-(DEVICE )loadParserWithCharacteristic:(CBCharacteristic *)characteristic;
@end
