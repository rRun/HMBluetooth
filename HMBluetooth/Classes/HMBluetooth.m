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
    NSMutableArray *connectionQueue;//连接队列
}

@property (nonatomic,strong)NSString *filter;

@property (nonatomic, assign)  CBCentralManagerState state;

@property (nonatomic, strong) NSMutableArray *DeviceArray;
@property (nonatomic, strong) NSMutableArray *ServiceArray;
@property (nonatomic, strong) NSMutableArray *CharacteristicArray;

@property (nonatomic, strong) HMDevice *connectionDevice;

@property (nonatomic, copy)  ScanDevicesCompleteBlock scanBlock;
@property (nonatomic, copy)  ConnectionDeviceBlock connectionBlock;
@property (nonatomic, copy)  ServiceAndCharacteristicBlock serviceAndcharBlock;
@property (nonatomic, copy)  PeripheralWriteValueForCharacteristicsBlock writeValueBlock;
@property (nonatomic, copy)  PeripheralReadValueForCharacteristicBlock readValueBlock;
@property (nonatomic, copy)  PeripheralNotifyValueForCharacteristicsBlock notifyValueBlock;
@property (nonatomic, copy)  PeripheralReadRSSIBlock readRSSIBlock;
@property (nonatomic, copy)  ListenDeviceStateBlock listenBlock;

@end

@implementation HMBluetooth{
    BOOL _isScaning;
    BOOL _isConnecting;
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
        
        connectionQueue  = [[NSMutableArray alloc] init];
        
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

/**
 *  监听蓝牙状态
 */
-(void)listenDeviceState:(ListenDeviceStateBlock)block{
    self.listenBlock = block;
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
    NSLog(@"开始设备连接");
    self.connectionBlock = block;
    [self performSelector:@selector(connectionTimeOut) withObject:nil afterDelay:timeout];
    for (HMDevice *device in self.DeviceArray) {
        if ([device.peripheral.identifier.UUIDString isEqualToString:uuid]) {
            self.connectionDevice = device;
            self.connectionDevice.peripheral.delegate =self;
            if (self.connectionDevice.peripheral.state != CBPeripheralStateConnecting && self.connectionDevice.peripheral.state != CBPeripheralStateConnected) {
                [self.manager connectPeripheral:device.peripheral options:@{ CBCentralManagerScanOptionAllowDuplicatesKey:@YES }];
            }
            break;
        }
    }
 
}

- (void)connectionWithDevice:(HMDevice *)device TimeOut:(NSUInteger)timeout CompleteBlock:(ConnectionDeviceBlock)block {
    NSLog(@"开始设备连接");
    self.connectionBlock = block;
    [self performSelector:@selector(connectionTimeOut) withObject:nil afterDelay:timeout];
    
    if (device && self.connectionDevice.peripheral.state != CBPeripheralStateConnecting && self.connectionDevice.peripheral.state != CBPeripheralStateConnected) {
        self.ConnectionDevice = device;
        self.connectionDevice.peripheral.delegate =self;
        [self.manager connectPeripheral:self.connectionDevice.peripheral options:@{ CBCentralManagerScanOptionAllowDuplicatesKey:@YES }];
    }
   
}
- (void)runloopConnectionWithDevice:(HMDevice *)device TimeOut:(NSUInteger)timeout CompleteBlock:(ConnectionDeviceBlock)block {
    NSLog(@"开始设备队列连接");
    NSDictionary *deviceAndBlockKey = [NSDictionary dictionaryWithObjectsAndKeys:device,@"device",[NSNumber numberWithInteger:timeout],@"timeout",nil];
    self.connectionBlock = block;
    [connectionQueue insertObject:deviceAndBlockKey atIndex:0];
    
    if (!_isConnecting) {
        _isConnecting = YES;
        [self connectLastDevice];
        
    }
}
-(void)connectLastDevice{
    NSDictionary *lastDic = [connectionQueue lastObject];
    [connectionQueue removeLastObject];
    
    self.ConnectionDevice = [lastDic objectForKey:@"device"];
    //self.connectionBlock = [lastDic objectForKey:@"block"];
    NSInteger tempTimeOut = [[lastDic objectForKey:@"timeout"] integerValue];
    
    
    NSLog(@"连接队列%d设备:%@",connectionQueue.count,lastDic);
    
    [self performSelector:@selector(connectionTimeOut) withObject:nil afterDelay:tempTimeOut];
    if (self.connectionDevice && self.connectionDevice.peripheral.state != CBPeripheralStateConnecting && self.connectionDevice.peripheral.state != CBPeripheralStateConnected) {
        self.connectionDevice.peripheral.delegate =self;
        [self.manager connectPeripheral:self.connectionDevice.peripheral options:@{ CBCentralManagerScanOptionAllowDuplicatesKey:@YES }];
        
    }
}
-(void)disconnectRunloopDevice{
    if (!_isConnecting) {
        return;
    }
    
    if (self.connectionDevice) {
        NSLog(@"停止连接队列%d设备",connectionQueue.count);
        
        [self.ServiceArray removeAllObjects];
        [self.CharacteristicArray removeAllObjects];
        
        HMDevice *currentEvice = self.connectionDevice;
        self.connectionDevice.peripheral.delegate = nil;
        self.ConnectionDevice = nil;
        
        if (currentEvice && currentEvice.peripheral.state != CBPeripheralStateDisconnected && currentEvice.peripheral.state != CBPeripheralStateDisconnecting) {
            [self.manager cancelPeripheralConnection:currentEvice.peripheral];
        }
        
        if (_isConnecting) {
            if ([connectionQueue count]==0) {
                _isConnecting = NO;
                 self.connectionBlock = nil;
                self.notifyValueBlock =nil;
                self.readValueBlock=nil;
            }else
                [self performSelector:@selector(connectLastDevice) withObject:nil afterDelay:1];
        }
    }
}


- (void)disconnectionDevice {
    NSLog(@"断开设备连接");
    [self.ServiceArray removeAllObjects];
    [self.CharacteristicArray removeAllObjects];
    
    HMDevice *currentEvice = self.connectionDevice;
    self.connectionDevice.peripheral.delegate = nil;
    self.ConnectionDevice = nil;
    self.connectionBlock = nil;
    self.notifyValueBlock =nil;
    self.readValueBlock=nil;
    _isConnecting = NO;
    if (currentEvice && currentEvice.peripheral.state != CBPeripheralStateDisconnected && currentEvice.peripheral.state != CBPeripheralStateDisconnecting) {
        [self.manager cancelPeripheralConnection:currentEvice.peripheral];
    }
}

- (void)discoverServiceAndCharacteristicWithInterval:(NSUInteger)time CompleteBlock:(ServiceAndCharacteristicBlock)block {
    NSLog(@"开始扫描服务");
    [self.ServiceArray removeAllObjects];
    [self.CharacteristicArray removeAllObjects];
    self.serviceAndcharBlock = block;
    self.connectionDevice.peripheral.delegate = self;
    
    [self.connectionDevice.peripheral discoverServices:nil];
    
    [self performSelector:@selector(discoverServiceAndCharacteristicWithTime) withObject:nil afterDelay:time];
}

- (void)writeCharacteristicWithServiceUUID:(NSString *)sUUID CharacteristicUUID:(NSString *)cUUID data:(NSData *)data  CompleteBlock:(PeripheralWriteValueForCharacteristicsBlock)block{
     NSLog(@"开始写入蓝牙服务");
    self.writeValueBlock= block;
    
    for (CBService *service in self.connectionDevice.peripheral.services) {
        if ([service.UUID isEqual:[CBUUID UUIDWithString:sUUID]]) {
            for (CBCharacteristic *characteristic in service.characteristics) {
                if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:cUUID]]) {
                    [self.connectionDevice.peripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
                }
            }
        }
    }
}

- (void)writeCharacteristicWithService:(CBService *)service Characteristic:(CBCharacteristic *)characteristic data:(NSData *)data CompleteBlock:(PeripheralWriteValueForCharacteristicsBlock)block{
    NSLog(@"开始写入蓝牙服务");
    self.writeValueBlock= block;
    
    if (characteristic) {
        [self.connectionDevice.peripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
    }
    
}

- (void)setNotificationForCharacteristicWithServiceUUID:(NSString *)sUUID CharacteristicUUID:(NSString *)cUUID enable:(BOOL)enable CompleteBlock:(PeripheralNotifyValueForCharacteristicsBlock)block{
    NSLog(@"开始监听蓝牙服务");
    self.notifyValueBlock = block;
    for (CBService *service in self.ServiceArray) {
        if ([service.UUID isEqual:[CBUUID UUIDWithString:sUUID]]) {
            for (CBCharacteristic *characteristic in self.CharacteristicArray) {
                if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:cUUID]]) {
                    [self.connectionDevice.peripheral setNotifyValue:enable forCharacteristic:characteristic];
                }
            }
        }
    }
}
-(void)setNotificationForCharacteristicWithService:(CBService *)service Characteristic:(CBCharacteristic *)characteristic enable:(BOOL)enable CompleteBlock:(PeripheralNotifyValueForCharacteristicsBlock)block{
    NSLog(@"开始监听蓝牙服务");
    self.notifyValueBlock = block;
    
    if (service && characteristic) {
        service.peripheral.delegate = self;
        [self.connectionDevice.peripheral setNotifyValue:enable forCharacteristic:characteristic];
    }
    
}
-(void)readCharacteristicWithServiceUUID:(NSString *)sUUID CharacteristicUUID:(NSString *)cUUID  CompleteBlock:(PeripheralReadValueForCharacteristicBlock)block{
    NSLog(@"开始读取蓝牙服务");
    self.readValueBlock=block;
    for (CBService *service in self.ServiceArray) {
        if ([service.UUID isEqual:[CBUUID UUIDWithString:sUUID]]) {
            for (CBCharacteristic *characteristic in self.CharacteristicArray) {
                if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:cUUID]]) {
                    [self.connectionDevice.peripheral readValueForCharacteristic:characteristic];
                }
            }
        }
    }
}

-(void)readCharacteristicWithService:(CBService *)service Characteristic:(CBCharacteristic *)characteristic  CompleteBlock:(PeripheralReadValueForCharacteristicBlock)block{
    NSLog(@"开始读取蓝牙服务");
    self.readValueBlock=block;
    if (characteristic) {
        [self.connectionDevice.peripheral readValueForCharacteristic:characteristic];
    }
    
}
- (void)readRSSI:(nullable PeripheralReadRSSIBlock)block{
    NSLog(@"开始读取蓝牙信号");
    _readRSSIBlock = block;
    [self.connectionDevice.peripheral readRSSI];
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
-(void)getMacAddress:(HMDevice *)hmDevice Characteristics:(NSArray *)characteristicArray Block:(GetAddressCompleteBlock)block{
    CBUUID *macServiceUUID = [CBUUID UUIDWithString:@"180A"];
    CBUUID *macCharcteristicUUID = [CBUUID UUIDWithString:@"2A23"];
    
    CBCharacteristic *hcharacteristic = nil;
    for (CBCharacteristic *characteristic in characteristicArray) {
        if ([characteristic.UUID isEqual:macCharcteristicUUID] && [characteristic.service.UUID isEqual:macServiceUUID]) {
            hcharacteristic = characteristic;
            break;
        }
    }
    if (!hcharacteristic) {
        [self disconnectionDevice];
        return ;
    }
    
     __weak typeof(self) weakSelf = self;
    
    [self readCharacteristicWithServiceUUID:hcharacteristic.service.UUID.UUIDString CharacteristicUUID:hcharacteristic.UUID.UUIDString CompleteBlock:^(HMDevice *peripheral, CBCharacteristic *characteristic, NSError *error, NSData *value) {
        
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
        block(hmDevice);
    }];
    
}
- (void)getMacAddress1:(HMDevice *)hmDevice Block:(GetAddressCompleteBlock)block
{
    
    
    __weak typeof(self) weakSelf = self;
    

        CBUUID *macServiceUUID = [CBUUID UUIDWithString:@"180A"];
        CBUUID *macCharcteristicUUID = [CBUUID UUIDWithString:@"2A23"];

    
        [self connectionWithDevice:hmDevice.peripheral TimeOut:15 CompleteBlock:^(HMDevice *device, NSError *err) {
            if (err.code == 401) {
                [weakSelf discoverServiceAndCharacteristicWithInterval:2 CompleteBlock:^(NSArray *serviceArray, NSArray *characteristicArray, NSError *err) {
                    
                    hmDevice.services=[NSArray arrayWithArray:serviceArray];
                    hmDevice.charaters = [NSArray arrayWithArray:characteristicArray];
                    
                    CBCharacteristic *hcharacteristic = nil;
                    for (CBCharacteristic *characteristic in characteristicArray) {
                        if ([characteristic.UUID isEqual:macCharcteristicUUID] && [characteristic.service.UUID isEqual:macServiceUUID]) {
                            hcharacteristic = characteristic;
                            break;
                        }
                    }
                    if (!hcharacteristic||err.code != 400) {
                        [weakSelf disconnectionDevice];
                        return ;
                    }
                    
                    [weakSelf readCharacteristicWithServiceUUID:hcharacteristic.service.UUID.UUIDString CharacteristicUUID:hcharacteristic.UUID.UUIDString CompleteBlock:^(HMDevice *peripheral, CBCharacteristic *characteristic, NSError *error, NSData *value) {
                        
                        [weakSelf discoverServiceAndCharacteristicWithTime];
                        [weakSelf disconnectionDevice];
                        
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
                        block(hmDevice);
                    }];
                    
                }];
            }else{
                [weakSelf discoverServiceAndCharacteristicWithTime];
                [weakSelf disconnectionDevice];
                return ;
            }
        }];
    
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    NSLog(@"当前的设备状态:%ld", (long)central.state);
    self.state = central.state;
    
    if (self.listenBlock) {
        self.listenBlock(self,central.state);
    }
}


- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
	if ([peripheral.name length]<=0) {
		return;
	}
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
        }else
            return;
        
        //__weak typeof(self) weakSelf = self;
        
        [self.DeviceArray addObject:hdevice];
        if (self.scanBlock) {
            self.scanBlock(self.DeviceArray,nil,1);
        }
        
       /* [self getMacAddress:hdevice Block:^(HMDevice *device) {
            
            [weakSelf.DeviceArray addObject:device];
            if (weakSelf.scanBlock) {
                weakSelf.scanBlock(weakSelf.DeviceArray,nil,1);
            }
            

        }];*/
        
    }
    
}

/*-(void)getMacADdress{
    if (isGetMacing) {
        return;
    }
    isGetMacing = YES;
    while (isGetMacing) {
        
        sleep(1);
        
        if (getMacAddressLock) {
            return;
        }
        
        if (!getMacAddressLock) {
            getMacAddressLock = [[NSLock alloc]init];
        }
        
        HMDevice *hdevice = [getMacAddressArr lastObject];

        
        __weak typeof(self) weakSelf = self;
        dispatch_async(getMacAddressqueue, ^{
            [weakSelf getMacAddress:hdevice Block:^(HMDevice *device) {
                
                [weakSelf.DeviceArray addObject:device];
                if (weakSelf.scanBlock) {
                    weakSelf.scanBlock(weakSelf.DeviceArray,nil,1);
                }
                [getMacAddressArr removeObject:hdevice];
                getMacAddressLock = nil;
                
                if ([getMacAddressArr count]==0) {
                    getMacAddressArr = nil;
                    isGetMacing =NO;
                }
            }];
        });
        
      
    }
    }*/
//连接Peripherals－成功
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(connectionTimeOut) object:nil];
    NSLog(@"连接设备成功:%@", peripheral);

    if (self.connectionBlock) {
        self.connectionBlock(self.connectionDevice, [self wrapperError:@"连接成功!" Code:401]);
    }
    
}
//连接到Peripherals-失败
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@"连接设备失败:%@",peripheral);
    if (self.connectionBlock) {
        self.connectionBlock(self.connectionDevice, error);
    }
}
//Peripherals断开连接
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"连接设备断开:%@",peripheral);
    //检查并重新连接需要重连的设备
    if (self.connectionDevice !=nil) {
       [self.manager connectPeripheral:self.connectionDevice.peripheral options:@{ CBCentralManagerScanOptionAllowDuplicatesKey:@YES }];
    }else{
        
    }
    
    
}

- (void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary<NSString *, id> *)dict{
     NSLog(@"连接设备状态重置:%@",dict);
}

#pragma mark - CBPeripheralDelegate
//扫描到服务
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    if (error) {
        NSLog(@"搜索服务发生错误,错误信息:%@", error);
    }
    for (CBService *service in peripheral.services) {
        [self.ServiceArray addObject:service];
        [self.connectionDevice.peripheral discoverCharacteristics:nil forService:service];
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
        self.writeValueBlock(self.connectionDevice,characteristic,error);
    }
    
    if (error) {
        NSLog(@"didWriteValueForCharacteristic接收数据发生错误,%@", error);
        return;
    }
    NSLog(@"didWriteValueForCharacteristic写入值发生改变,%@", error);
}

//读取Characteristics的值
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error {
    
    if (self.notifyValueBlock) {
        self.notifyValueBlock(self.connectionDevice,characteristic,error,characteristic.value);
    }
    
    if (self.readValueBlock) {
        self.readValueBlock(self.connectionDevice,characteristic,error,characteristic.value);
    }
    self.readValueBlock = nil;
    
    
    if (error) {
        NSLog(@"didUpdateValueForCharacteristic接收数据发生错误,%@", error);
        return;
    }
    
    NSString *string=[[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    NSLog(@"didUpdateNotificationStateForCharacteristic收到的数据为%@", string);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ReadValueChange object:characteristic];
    
}

//获取状态变化的数据
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error {
    if (self.notifyValueBlock) {
        self.notifyValueBlock(self.connectionDevice,characteristic,error,nil);
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
        self.readRSSIBlock(self.connectionDevice,RSSI,error);
        self.readRSSIBlock = nil;
    }
}

#pragma mark - getter
- (BOOL)isReady {
    return self.state == CBCentralManagerStatePoweredOn ? YES : NO;
}

- (BOOL)isConnection {
    return self.connectionDevice.peripheral.state == CBPeripheralStateConnected ? YES : NO;
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
