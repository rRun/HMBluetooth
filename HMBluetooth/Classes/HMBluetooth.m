//
//  HMBluetooth.m
//  Pods
//
//  Created by 何霞雨 on 16/8/11.
//
//

#import "HMBluetooth.h"

#import "BMPParser.h"
#import "GLSParser.h"

#import "HMDevice.h"

#define channelOnPeropheralView @"peripheralView"



@interface HMBluetooth(){
    NSLock *getMacAddressLock;
}

@property (nonatomic,strong)NSString *filter;

@property (nonatomic, assign)  CBCentralManagerState state;

@property (nonatomic, strong) NSMutableArray *DeviceArray;
@property (nonatomic, strong) NSMutableArray *ServiceArray;
@property (nonatomic, strong) NSMutableArray *CharacteristicArray;

@property (nonatomic, strong) CBPeripheral *ConnectionDevice;

@property (nonatomic, copy)  ScanDevicesCompleteBlock scanBlock;
@property (nonatomic, copy)  ConnectionDeviceBlock connectionBlock;
@property (nonatomic, copy)  ServiceAndCharacteristicBlock serviceAndcharBlock;
@property (nonatomic, copy)  PeripheralWriteValueForCharacteristicsBlock writeValueBlock;
@property (nonatomic, copy)  PeripheralReadValueForCharacteristicBlock readValueBlock;
@property (nonatomic, copy)  PeripheralNotifyValueForCharacteristicsBlock notifyValueBlock;
@property (nonatomic, copy)  PeripheralReadRSSIBlock readRSSIBlock;

@end

@implementation HMBluetooth{
    BOOL _isScaning;
    dispatch_queue_t getMacAddressqueue;
}


#pragma mark - 自定义方法
static id _instance;
+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _manager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];
        
        _ServiceArray = [[NSMutableArray alloc] init];
        _CharacteristicArray = [[NSMutableArray alloc] init];
        _DeviceArray = [[NSMutableArray alloc] init];
        
        getMacAddressqueue = dispatch_queue_create("com.cdfortis.getmac", DISPATCH_QUEUE_SERIAL);
        
    }
    return self;
}

- (void)startScanDevicesWithInterval:(NSUInteger)timeout WithFilter:(NSString *)filter CompleteBlock:(ScanDevicesCompleteBlock)block {
    NSLog(@"开始扫描设备");
    
    self.filter = filter;
    [self.DeviceArray removeAllObjects];
    [self.ServiceArray removeAllObjects];
    [self.CharacteristicArray removeAllObjects];
    
    self.scanBlock = block;
    [self.manager scanForPeripheralsWithServices:nil options:nil];
    [self performSelector:@selector(stopScanDevices) withObject:nil afterDelay:timeout];
}

- (void)stopScanDevices {
    
    NSLog(@"扫描设备结束");
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(stopScanDevices) object:nil];
    
    [self.manager stopScan];
    if (self.scanBlock) {
        self.scanBlock(self.DeviceArray,nil,0);
    }
    
    self.scanBlock = nil;
}

- (void)connectionWithDeviceUUID:(NSString *)uuid TimeOut:(NSUInteger)timeout CompleteBlock:(ConnectionDeviceBlock)block {
    
    self.connectionBlock = block;
    [self performSelector:@selector(connectionTimeOut) withObject:nil afterDelay:timeout];
    for (HMDevice *device in self.DeviceArray) {
        if ([device.peripheral.identifier.UUIDString isEqualToString:uuid]) {
            [self.manager connectPeripheral:device.peripheral options:@{ CBCentralManagerScanOptionAllowDuplicatesKey:@YES }];
            break;
        }
    }
 
}

- (void)connectionWithDevice:(CBPeripheral *)device TimeOut:(NSUInteger)timeout CompleteBlock:(ConnectionDeviceBlock)block {
    self.connectionBlock = block;
    [self performSelector:@selector(connectionTimeOut) withObject:nil afterDelay:timeout];
    if (device) {
        [self.manager connectPeripheral:device options:@{ CBCentralManagerScanOptionAllowDuplicatesKey:@YES }];
    }
   
}
- (void)disconnectionDevice {
    NSLog(@"断开设备连接");
    [self.ServiceArray removeAllObjects];
    [self.CharacteristicArray removeAllObjects];
    
    CBPeripheral *currentEvice = self.ConnectionDevice;
    self.ConnectionDevice = nil;
    
    if (currentEvice) {
        [self.manager cancelPeripheralConnection:currentEvice];
    }
    
    self.connectionBlock = nil;

}

- (void)discoverServiceAndCharacteristicWithInterval:(NSUInteger)time CompleteBlock:(ServiceAndCharacteristicBlock)block {
    [self.ServiceArray removeAllObjects];
    [self.CharacteristicArray removeAllObjects];
    self.serviceAndcharBlock = block;
    self.ConnectionDevice.delegate = self;
    
    [self.ConnectionDevice discoverServices:nil];
    
    [self performSelector:@selector(discoverServiceAndCharacteristicWithTime) withObject:nil afterDelay:time];
}

- (void)writeCharacteristicWithServiceUUID:(NSString *)sUUID CharacteristicUUID:(NSString *)cUUID data:(NSData *)data  CompleteBlock:(PeripheralWriteValueForCharacteristicsBlock)block{
    
    self.writeValueBlock= block;
    
    for (CBService *service in self.ConnectionDevice.services) {
        if ([service.UUID isEqual:[CBUUID UUIDWithString:sUUID]]) {
            for (CBCharacteristic *characteristic in service.characteristics) {
                if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:cUUID]]) {
                    [self.ConnectionDevice writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
                }
            }
        }
    }
}

- (void)writeCharacteristicWithService:(CBService *)service Characteristic:(CBCharacteristic *)characteristic data:(NSData *)data CompleteBlock:(PeripheralWriteValueForCharacteristicsBlock)block{
    self.writeValueBlock= block;
    
    if (characteristic) {
        [self.ConnectionDevice writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
    }
    
}

- (void)setNotificationForCharacteristicWithServiceUUID:(NSString *)sUUID CharacteristicUUID:(NSString *)cUUID enable:(BOOL)enable CompleteBlock:(PeripheralNotifyValueForCharacteristicsBlock)block{
    self.readValueBlock = block;
    for (CBService *service in self.ServiceArray) {
        if ([service.UUID isEqual:[CBUUID UUIDWithString:sUUID]]) {
            for (CBCharacteristic *characteristic in self.CharacteristicArray) {
                if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:cUUID]]) {
                    [self.ConnectionDevice setNotifyValue:enable forCharacteristic:characteristic];
                }
            }
        }
    }
}
-(void)setNotificationForCharacteristicWithService:(CBService *)service Characteristic:(CBCharacteristic *)characteristic enable:(BOOL)enable CompleteBlock:(PeripheralNotifyValueForCharacteristicsBlock)block{
    
    self.readValueBlock = block;
    
    if (service && characteristic) {
        [self.ConnectionDevice setNotifyValue:enable forCharacteristic:characteristic];
    }
    
}
-(void)readCharacteristicWithServiceUUID:(NSString *)sUUID CharacteristicUUID:(NSString *)cUUID  CompleteBlock:(PeripheralReadValueForCharacteristicBlock)block{
    self.readValueBlock=block;
    for (CBService *service in self.ServiceArray) {
        if ([service.UUID isEqual:[CBUUID UUIDWithString:sUUID]]) {
            for (CBCharacteristic *characteristic in self.CharacteristicArray) {
                if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:cUUID]]) {
                    [self.ConnectionDevice readValueForCharacteristic:characteristic];
                }
            }
        }
    }
}

- (void)readRSSI:(nullable PeripheralReadRSSIBlock)block{
    _readRSSIBlock = block;
    [self.ConnectionDevice readRSSI];
}
#pragma mark - 私有方法

- (void)connectionTimeOut {
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(connectionTimeOut) object:nil];
    if (self.connectionBlock) {
        self.connectionBlock(nil, [self wrapperError:@"连接设备超时!" Code:400]);
    }
    self.connectionBlock = nil;
}

- (void)discoverServiceAndCharacteristicWithTime {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(discoverServiceAndCharacteristicWithTime) object:nil];
    if (self.serviceAndcharBlock) {
        self.serviceAndcharBlock(self.ServiceArray, self.CharacteristicArray, [self wrapperError:@"发现服务和特征完成!" Code:400]);
    }
    self.serviceAndcharBlock = nil;
}

- (NSError *)wrapperError:(NSString *)msg Code:(NSInteger)code {
    NSError *error = [NSError errorWithDomain:msg code:code userInfo:nil];
    return error;
}

- (void)getMacAddress:(HMDevice *)hmDevice Block:(GetAddressCompleteBlock)block
{
    __weak typeof(self) weakSelf = self;
    
//    if (!getMacAddressqueue) {
//        getMacAddressqueue = dispatch_queue_create("com.cdfortis.getmac", DISPATCH_QUEUE_SERIAL);
//    }
    
//    dispatch_async(getMacAddressqueue, ^{
        CBUUID *macServiceUUID = [CBUUID UUIDWithString:@"180A"];
        CBUUID *macCharcteristicUUID = [CBUUID UUIDWithString:@"2A23"];
        
//        if (!getMacAddressLock) {
//            getMacAddressLock = [[NSLock alloc]init];
//        }
//        
//        [getMacAddressLock lock];
    
        [weakSelf connectionWithDeviceUUID:hmDevice.peripheral.identifier.UUIDString TimeOut:12 CompleteBlock:^(CBPeripheral *device, NSError *err) {
            if (err.code == 401) {
                [weakSelf discoverServiceAndCharacteristicWithInterval:2 CompleteBlock:^(NSArray *serviceArray, NSArray *characteristicArray, NSError *err) {
                    CBCharacteristic *hcharacteristic = nil;
                    for (CBCharacteristic *characteristic in characteristicArray) {
                        if ([characteristic.UUID isEqual:macCharcteristicUUID] && [characteristic.service.UUID isEqual:macServiceUUID]) {
                            hcharacteristic = characteristic;
                            break;
                        }
                    }
                    if (!hcharacteristic||err.code != 400) {
                        [weakSelf disconnectionDevice];
//                        [getMacAddressLock unlock];
                        return ;
                    }
                    
                    [weakSelf readCharacteristicWithServiceUUID:hcharacteristic.service.UUID.UUIDString CharacteristicUUID:hcharacteristic.UUID.UUIDString CompleteBlock:^(CBPeripheral *peripheral, CBCharacteristic *characteristic, NSError *error, NSData *value) {
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            //在主线程中更新UI代码
                            NSString *valueStr = [NSString stringWithFormat:@"%@",value];
                            NSMutableString *macString = [[NSMutableString alloc] init];
                            [macString appendString:[[valueStr substringWithRange:NSMakeRange(16, 2)] uppercaseString]];
                            [macString appendString:@":"];
                            [macString appendString:[[valueStr substringWithRange:NSMakeRange(14, 2)] uppercaseString]];
                            [macString appendString:@":"];
                            [macString appendString:[[valueStr substringWithRange:NSMakeRange(12, 2)] uppercaseString]];
                            [macString appendString:@":"];
                            [macString appendString:[[valueStr substringWithRange:NSMakeRange(5, 2)] uppercaseString]];
                            [macString appendString:@":"];
                            [macString appendString:[[valueStr substringWithRange:NSMakeRange(3, 2)] uppercaseString]];
                            [macString appendString:@":"];
                            [macString appendString:[[valueStr substringWithRange:NSMakeRange(1, 2)] uppercaseString]];
                            
                            NSLog(@"macString:%@",macString);
                            hmDevice.macAddress = macString;
                            [weakSelf discoverServiceAndCharacteristicWithTime];
                            [weakSelf disconnectionDevice];
                            block(hmDevice);
                        });
//                        [getMacAddressLock unlock];
                    }];
                    
                }];
            }else{
                [weakSelf discoverServiceAndCharacteristicWithTime];
                [weakSelf disconnectionDevice];
//                [getMacAddressLock unlock];
                return ;
            }
        }];
        
//    });
}

#pragma mark - CBCentralManagerDelegate代理方法

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    NSLog(@"当前的设备状态:%ld", (long)central.state);
    self.state = central.state;
}


- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    
    if ([peripheral.name rangeOfString:self.filter].location != NSNotFound || [self.filter length]==0 || self.filter == nil) {
        
        NSLog(@"发现设备:%@", peripheral);
        
        BOOL isExist = NO;
        HMDevice *hdevice = nil;
        for (HMDevice *device in self.DeviceArray) {
            if ([device.peripheral isEqual:peripheral]) {
                isExist = YES;
                hdevice =device;
                break;
            }
        }
        
        if (!isExist) {
            hdevice = [HMDevice new];
            hdevice.peripheral = peripheral;
            [self.DeviceArray addObject:hdevice];
        }else
            return;
        
        __weak typeof(self) weakSelf = self;
        [self getMacAddress:hdevice Block:^(HMDevice *device) {
            if (weakSelf.scanBlock) {
                weakSelf.scanBlock(weakSelf.DeviceArray,nil,1);
            }
        }];
    }
    
}

//连接Peripherals－成功
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(connectionTimeOut) object:nil];
    NSLog(@"连接设备成功:%@", peripheral);
    
    self.ConnectionDevice = peripheral;
    self.ConnectionDevice.delegate = self;
    
    if (self.connectionBlock) {
        self.connectionBlock(peripheral, [self wrapperError:@"连接成功!" Code:401]);
    }
}
//连接到Peripherals-失败
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@"连接设备失败:%@",peripheral);
    if (self.connectionBlock) {
        self.connectionBlock(peripheral, error);
    }
    
}
//Peripherals断开连接
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"连接设备断开:%@",peripheral);
    //检查并重新连接需要重连的设备
    if (self.ConnectionDevice !=nil) {
       [self.manager connectPeripheral:self.ConnectionDevice options:@{ CBCentralManagerScanOptionAllowDuplicatesKey:@YES }];
    }
}

//扫描到服务
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    if (error) {
        NSLog(@"搜索服务发生错误,错误信息:%@", error);
    }
    for (CBService *service in peripheral.services) {
        [self.ServiceArray addObject:service];
        [self.ConnectionDevice discoverCharacteristics:nil forService:service];
    }
    
}
//发现服务的Characteristics
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if (error) {
        NSLog(@"搜索特征发生错误,错误信息:%@", error);
    }
    for (CBCharacteristic *characteristic in service.characteristics) {
        [self.CharacteristicArray addObject:characteristic];
    }
}

//写入Characteristics数据
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    if (self.writeValueBlock) {
        self.writeValueBlock(peripheral,characteristic,error);
    }
    
    if (error) {
        NSLog(@"didWriteValueForCharacteristic接收数据发生错误,%@", error);
        return;
    }
    NSLog(@"didWriteValueForCharacteristic写入值发生改变,%@", error);
}

//读取Characteristics的值
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (self.readValueBlock) {
        self.readValueBlock(peripheral,characteristic,error,characteristic.value);
    }
    if (error) {
        NSLog(@"didUpdateValueForCharacteristic接收数据发生错误,%@", error);
        return;
    }
    
    NSString *string=[[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    NSLog(@"didUpdateNotificationStateForCharacteristic收到的数据为%@", string);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ReadValueChange object:characteristic];
    
}

//获取状态变化的数据
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (self.notifyValueBlock) {
        self.notifyValueBlock(peripheral,characteristic,error,characteristic.value);
    }
    if (error) {
        NSLog(@"didUpdateNotificationStateForCharacteristic接收数据发生错误,%@", error);
        return;
    }
    NSString *string=[[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    NSLog(@"didUpdateNotificationStateForCharacteristic收到的数据为%@", string);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NotiValueChange object:characteristic];
}

//获取信号
- (void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(NSError *)error
{
    if(self.readRSSIBlock){
        self.readRSSIBlock(self,RSSI,error);
        self.readRSSIBlock = nil;
    }
}

#pragma mark - getter
- (BOOL)isReady {
    return self.state == CBCentralManagerStatePoweredOn ? YES : NO;
}

- (BOOL)isConnection {
    return self.ConnectionDevice.state == CBPeripheralStateConnected ? YES : NO;
}

-(NSString *)filter{
    if ([_filter length]>0) {
        return _filter;
    }
    
    return @"";
}

#pragma mark - Load Parser
-(DEVICE )loadParserWithCharacteristic:(CBCharacteristic *)characteristic{
    if ([characteristic.service.UUID.UUIDString isEqualToString:BP_SERVICE_UUID]) {
        return BMP_DEVICE;
    }else if (([characteristic.service.UUID.UUIDString isEqualToString:GLS_SERVICE_UUID])){
        return GLS_DEVICE;
    }else{
        NSLog(@"other unkown device");
        return UNKOWN_DEVICE;
    }
}

@end
