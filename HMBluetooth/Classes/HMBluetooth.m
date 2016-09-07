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

#define channelOnPeropheralView @"peripheralView"

@interface HMBluetooth()

@property (nonatomic,strong)NSString *filter;

@property (nonatomic, assign)  CBCentralManagerState state;

@property (nonatomic, strong) NSMutableArray *DeviceArray;
@property (nonatomic, strong) NSMutableArray *ServiceArray;
@property (nonatomic, strong) NSMutableArray *CharacteristicArray;

@property (nonatomic, strong) CBPeripheral *ConnectionDevice;

@property (nonatomic, copy)  ScanDevicesCompleteBlock scanBlock;
@property (nonatomic, copy)  ConnectionDeviceBlock connectionBlock;
@property (nonatomic, copy)  ServiceAndCharacteristicBlock serviceAndcharBlock;

@end

@implementation HMBluetooth{
    BOOL _isScaning;
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
        self.scanBlock(self.DeviceArray);
    }
    
    self.scanBlock = nil;
}

- (void)connectionWithDeviceUUID:(NSString *)uuid TimeOut:(NSUInteger)timeout CompleteBlock:(ConnectionDeviceBlock)block {
    self.connectionBlock = block;
    [self performSelector:@selector(connectionTimeOut) withObject:nil afterDelay:timeout];
    for (CBPeripheral *device in self.DeviceArray) {
        if ([device.identifier.UUIDString isEqualToString:uuid]) {
            [self.manager connectPeripheral:device options:@{ CBCentralManagerScanOptionAllowDuplicatesKey:@YES }];
            break;
        }
    }
}

- (void)disconnectionDevice {
    NSLog(@"断开设备连接");
    [self.ServiceArray removeAllObjects];
    [self.CharacteristicArray removeAllObjects];
    
    self.ConnectionDevice = nil;
    
    [self.manager cancelPeripheralConnection:self.ConnectionDevice];
    
}

- (void)discoverServiceAndCharacteristicWithInterval:(NSUInteger)time CompleteBlock:(ServiceAndCharacteristicBlock)block {
    [self.ServiceArray removeAllObjects];
    [self.CharacteristicArray removeAllObjects];
    self.serviceAndcharBlock = block;
    self.ConnectionDevice.delegate = self;
    
    [self.ConnectionDevice discoverServices:nil];
    
    [self performSelector:@selector(discoverServiceAndCharacteristicWithTime) withObject:nil afterDelay:time];
}

- (void)writeCharacteristicWithServiceUUID:(NSString *)sUUID CharacteristicUUID:(NSString *)cUUID data:(NSData *)data {
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

- (void)setNotificationForCharacteristicWithServiceUUID:(NSString *)sUUID CharacteristicUUID:(NSString *)cUUID enable:(BOOL)enable {
    for (CBService *service in self.ConnectionDevice.services) {
        if ([service.UUID isEqual:[CBUUID UUIDWithString:sUUID]]) {
            for (CBCharacteristic *characteristic in service.characteristics) {
                if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:cUUID]]) {
                    [self.ConnectionDevice setNotifyValue:enable forCharacteristic:characteristic];
                }
            }
        }
    }
}
-(void)readCharacteristicWithServiceUUID:(NSString *)sUUID CharacteristicUUID:(NSString *)cUUID{
    for (CBService *service in self.ConnectionDevice.services) {
        if ([service.UUID isEqual:[CBUUID UUIDWithString:sUUID]]) {
            for (CBCharacteristic *characteristic in service.characteristics) {
                if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:cUUID]]) {
                    [self.ConnectionDevice readValueForCharacteristic:characteristic];
                }
            }
        }
    }
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
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(connectionTimeOut) object:nil];
    if (self.serviceAndcharBlock) {
        self.serviceAndcharBlock(self.ServiceArray, self.CharacteristicArray, [self wrapperError:@"发现服务和特征完成!" Code:400]);
    }
    self.connectionBlock = nil;
}

- (NSError *)wrapperError:(NSString *)msg Code:(NSInteger)code {
    NSError *error = [NSError errorWithDomain:msg code:code userInfo:nil];
    return error;
}

#pragma mark - CBCentralManagerDelegate代理方法

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    NSLog(@"当前的设备状态:%ld", (long)central.state);
    self.state = central.state;
}


- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    
    if ([peripheral.name rangeOfString:self.filter].length>0) {
        
        NSLog(@"发现设备:%@", peripheral);
        
        if (![self.DeviceArray containsObject:peripheral]) {
            [self.DeviceArray addObject:peripheral];
        }
        
        if (self.scanBlock) {
            self.scanBlock(self.DeviceArray);
        }
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
    if (error) {
        NSLog(@"didWriteValueForCharacteristic接收数据发生错误,%@", error);
        return;
    }
    NSLog(@"didWriteValueForCharacteristic写入值发生改变,%@", error);
}

//读取Characteristics的值
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        NSLog(@"didUpdateValueForCharacteristic接收数据发生错误,%@", error);
        return;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NotiValueChange object:characteristic];
    
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        NSLog(@"didUpdateNotificationStateForCharacteristic接收数据发生错误,%@", error);
        return;
    }
    NSString *string=[[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    NSLog(@"didUpdateNotificationStateForCharacteristic收到的数据为%@", string);
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
