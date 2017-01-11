//
//  GLSManager.h
//  Pods
//
//  Created by 何霞雨 on 16/8/11.
//
//

#import <Foundation/Foundation.h>

#import "GlucoseRecord.h"
#import "GLSParserPrt.h"

/** Glucose service UUID */
static NSString * GLS_SERVICE_UUID = @"1808";
/** Glucose Measurement characteristic UUID */
static NSString * GM_CHARACTERISTIC = @"2A18";
/** Glucose Measurement Context characteristic UUID */
static NSString * GM_CONTEXT_CHARACTERISTIC = @"2A34";
/** Glucose Feature characteristic UUID */
static NSString * GF_CHARACTERISTIC = @"2A51";
/** Record Access Control Point characteristic UUID */
static NSString * RACP_CHARACTERISTIC = @"2A52";

@class HMBluetooth;
@class CBCharacteristic;

@interface GLSParser : NSObject

@property (nonatomic,weak)id <GLSParserPrt> delegate;

-(instancetype)initWithMeasurementCharacteristic:(CBCharacteristic *)mGlucoseMeasurementCharacteristic  MeasurementContextCharacteristic:(CBCharacteristic *)mGlucoseMeasurementContextCharacteristic AccessControlPointCharacteristic:(CBCharacteristic *)mRecordAccessControlPointCharacteristic;

#pragma mark - GLS Value

-(void)parseGLSValueWithCharacteristic:(CBCharacteristic *)characteristic;//解析
-(void)parseGLSValue:(NSData*)data withCharacteristic:(NSString *)characteristicUUID;//解析返回值

-(void)parseGLSOpValue:(NSData*)data withCharacteristic:(NSString *)characteristicUUID;//解析操作后状态的返回值

-(NSDictionary<NSString *, GlucoseRecord *>*) getRecords;//获取所有记录

#pragma mark - record
-(void)refreshRecords;

-(void)getAllRecords;
-(void)getFirstRecord;
-(void)getLastRecord;

-(void)deleteAllRecords;
-(void)clear;
-(void)abort;

@end
