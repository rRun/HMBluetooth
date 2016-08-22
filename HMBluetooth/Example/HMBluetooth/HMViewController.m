//
//  HMViewController.m
//  HMBluetooth
//
//  Created by hexy on 08/11/2016.
//  Copyright (c) 2016 hexy. All rights reserved.
//

#import "HMViewController.h"
#import "HMBluetooth.h"

#define BLOOD_PRESSURE @"1810"

@interface HMViewController ()<UITableViewDelegate,UITableViewDataSource,BMPParserPrt,GLSParserPrt>
@property (nonatomic,strong)HMBluetooth *hmB;
@property (nonatomic,strong)CBService *service;

@property (nonatomic,strong)NSArray *devices;
@end

@implementation HMViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.devices = [[NSMutableArray alloc]init];
	// Do any additional setup after loading the view, typically from a nib.
    self.hmB=[HMBluetooth sharedInstance];
    
}

- (IBAction)doScan:(id)sender {
    [self.hmB startScanDevicesWithInterval:50 WithFilter:@"Yuwell" CompleteBlock:^(NSArray *devices) {
        NSLog(@"%@",devices);
        self.devices = devices;
        [self.tableview reloadData];
    }];
}



- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.devices.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    CBPeripheral *cb=[self.devices objectAtIndex:indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CEll"];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"CEll"];
    }
    
    cell.textLabel.text = cb.name;
    cell.detailTextLabel.text= cb.identifier.UUIDString;
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [self.hmB stopScanDevices];
    
    CBPeripheral *cbp = [self.devices objectAtIndex:indexPath.row];
    
    [self.hmB connectionWithDeviceUUID:cbp.identifier.UUIDString TimeOut:1000 CompleteBlock:^(CBPeripheral *device, NSError *err) {
        if (device) {
            [self.hmB discoverServiceAndCharacteristicWithInterval:50 CompleteBlock:^(NSArray *serviceArray, NSArray *characteristicArray, NSError *err) {
                NSLog(@"查找服务和特征成功 %ld",serviceArray.count);
                
                __block CBService *tempService=nil;
                
                [serviceArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    CBService *ser = obj;
                    NSLog(@"%@:%@/n",ser,ser.UUID.UUIDString);
                    if ([ser.UUID.UUIDString isEqual:BLOOD_PRESSURE]) {
                        tempService = ser;
                        *stop = YES;
                    }
                }];
                
                self.service = tempService;
                [self.hmB setNotificationForCharacteristicWithServiceUUID:tempService.UUID.UUIDString CharacteristicUUID:BPM_CHARACTERISTIC_UUID enable:YES];
                
            }];
        }
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ValueChange:) name:NotiValueChange object:nil];
}


-(void)ValueChange:(NSNotification *)noti{
    //TODO:qweqweqwe
    CBCharacteristic *characteristic = noti.object;
    
    DEVICE device = [[HMBluetooth sharedInstance]loadParserWithCharacteristic:characteristic];
    switch (device) {
        case BMP_DEVICE:{
            BMPParser *bmpParser = [BMPParser new];
            bmpParser.delegate = self;
            [bmpParser parseBPMValueWithCharacteristic:characteristic];
        }
            break;
        case GLS_DEVICE:{
            GLSParser *glsParser = [GLSParser new];
            glsParser.delegate=self;
            [glsParser parseGLSValueWithCharacteristic:characteristic];
        }
            break;
            
        default:
            
            break;
    }
   

}


#pragma mark - Blood press

-(void)onBloodPressureMeasurementReadWithSystolic:(float)systolic Diastolic:(float)diastolic MeanArterialPressure:(float)meanArterialPressure Unit:(BMP_UNIT)unit{
    NSLog(@"onBloodPressureMeasurementReadWithSystolic value :%f,%f,%f,%ld",systolic,diastolic,meanArterialPressure,(long)unit);
    
}


-(void)onIntermediateCuffPressureReadWithCuffPressure:(float)cuffPressure Unit:(BMP_UNIT)unit{
    NSLog(@"onIntermediateCuffPressureReadWithCuffPressure value :%f,%ld",cuffPressure,(long)unit);
}


-(void)onPulseRateReadWithPulseRate:(float)pulseRate{
    NSLog(@"onPulseRateReadWithPulseRate value :%f",pulseRate);
}


-(void)onTimestampReadWithCalendar:(NSCalendar *)calendar{
    NSLog(@"onTimestampReadWithCalendar value :%@",calendar);
}

#pragma mark - 血糖
-(void)onOperationStarted{
    NSLog(@"op start");
}
-(void)onOperationCompleted{
    NSLog(@"op end");
}
-(void)onOperationFailed{
    NSLog(@"op fail");
}
-(void)onOperationAborted{
    NSLog(@"op abort");
}
-(void)onOperationNotSupported{
    NSLog(@"op not support");
}
-(void)onDatasetChanged:(GLSParser *)parser{
    NSLog(@"op value:%@",parser);
}
-(void)onNumberOfRecordsRequested:(int) value{
    NSLog(@"op record number:%d",value);
}
@end
