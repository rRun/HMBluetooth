//
//  GLSManager.m
//  Pods
//
//  Created by 何霞雨 on 16/8/11.
//
//

#import "GLSParser.h"
#import "HMBluetooth.h"

#import "NSData+HMParser.h"
#import "NSMutableData+HMParser.h"

#include <stdarg.h>


const static int OP_CODE_REPORT_STORED_RECORDS = 1;
const static int OP_CODE_DELETE_STORED_RECORDS = 2;
const static int OP_CODE_ABORT_OPERATION = 3;
const static int OP_CODE_REPORT_NUMBER_OF_RECORDS = 4;
const static int OP_CODE_NUMBER_OF_STORED_RECORDS_RESPONSE = 5;
const static int OP_CODE_RESPONSE_CODE = 6;

const static int RESPONSE_SUCCESS = 1;
const static int RESPONSE_OP_CODE_NOT_SUPPORTED = 2;
//const static int RESPONSE_INVALID_OPERATOR = 3;
//const static int RESPONSE_OPERATOR_NOT_SUPPORTED = 4;
//const static int RESPONSE_INVALID_OPERAND = 5;
const static int RESPONSE_NO_RECORDS_FOUND = 6;
const static int RESPONSE_ABORT_UNSUCCESSFUL = 7;
const static int RESPONSE_PROCEDURE_NOT_COMPLETED = 8;
//const static int RESPONSE_OPERAND_NOT_SUPPORTED = 9;

const static int OPERATOR_NULL = 0;
const static int OPERATOR_ALL_RECORDS = 1;
//const static int OPERATOR_LESS_THEN_OR_EQUAL = 2;
const static int OPERATOR_GREATER_THEN_OR_EQUAL = 3;
//const static int OPERATOR_WITHING_RANGE = 4;
const static int OPERATOR_FIRST_RECORD = 5;
const static int OPERATOR_LAST_RECORD = 6;

/**
 * The filter type is used for range operators ({@link #OPERATOR_LESS_THEN_OR_EQUAL}, {@link #OPERATOR_GREATER_THEN_OR_EQUAL}, {@link #OPERATOR_WITHING_RANGE}.<br/>
 * The syntax of the operand is: [Filter Type][Minimum][Maximum].<br/>
 * This filter selects the records by the sequence number.
 */
const static int FILTER_TYPE_SEQUENCE_NUMBER = 1;

@interface GLSParser(){
    BOOL mAbort;
}

@property(nonatomic,strong) NSMutableArray<GlucoseRecord *> *mRecords;
@property(nonatomic,strong) NSMutableData *opData;//操作的数据
@property(nonatomic,strong) CBCharacteristic *mGlucoseMeasurementCharacteristic;
@property(nonatomic,strong) CBCharacteristic *mGlucoseMeasurementContextCharacteristic;

@end

@implementation GLSParser
-(void)parseGLSValueWithCharacteristic:(CBCharacteristic *)characteristic{
    if ([characteristic.UUID.UUIDString isEqualToString:RACP_CHARACTERISTIC]) {
        [self parseGLSOpValue:characteristic.value withCharacteristic:characteristic.UUID.UUIDString];
    }else{
         [self parseGLSValue:characteristic.value withCharacteristic:characteristic.UUID.UUIDString];
    }
}
-(void)parseGLSValue:(NSData*)data withCharacteristic:(NSString *)characteristicUUID{
    
    if ([characteristicUUID isEqualToString:GM_CHARACTERISTIC]) {
        
        int offset = 0;
        int flags = [data getIntValueWith:FORMAT_UINT8 Offset:offset];
        offset += 1;
        
        BOOL timeOffsetPresent = (flags & 0x01) > 0;
        BOOL typeAndLocationPresent = (flags & 0x02) > 0;
        int concentrationUnit = (flags & 0x04) > 0 ? UNIT_molpl : UNIT_kgpl;
        BOOL sensorStatusAnnunciationPresent = (flags & 0x08) > 0;
        BOOL contextInfoFollows = (flags & 0x10) > 0;
        
        // create and fill the new record
        GlucoseRecord *record = [GlucoseRecord new];
        record.sequenceNumber = [data getIntValueWith:FORMAT_UINT16 Offset:offset];
        offset += 2;
        
        int year = [data getIntValueWith:FORMAT_UINT16 Offset:offset];
        int month = [data getIntValueWith:FORMAT_UINT8 Offset:offset+2]; // months are 1-based
        int day = [data getIntValueWith:FORMAT_UINT8 Offset:offset + 3];
        int hours = [data getIntValueWith:FORMAT_UINT8 Offset:offset + 4];
        int minutes = [data getIntValueWith:FORMAT_UINT8 Offset:offset + 5];
        int seconds = [data getIntValueWith:FORMAT_UINT8 Offset:offset + 6];
        offset += 7;
        
        //    先定义一个遵循某个历法的日历对象
        NSCalendar *greCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        
        //    定义一个NSDateComponents对象，设置一个时间点
        NSDateComponents *dateComponentsForDate = [[NSDateComponents alloc] init];
        [dateComponentsForDate setYear:year];
        [dateComponentsForDate setMonth:month];
        [dateComponentsForDate setDay:day];
        [dateComponentsForDate setHour:hours];
        [dateComponentsForDate setMinute:minutes];
        [dateComponentsForDate setSecond:seconds];
        
        greCalendar = [dateComponentsForDate calendar];
        
        if (timeOffsetPresent) {
            // time offset is ignored in the current release
            record.timeOffset = [data getIntValueWith:FORMAT_SINT16 Offset:offset];
            offset += 2;
        }
        
        if (typeAndLocationPresent) {
            record.glucoseConcentration = [data getFloatValueWithFormatType:FORMAT_SFLOAT Offset:offset];
            record.unit = concentrationUnit;
            int typeAndLocation = [data getIntValueWith:FORMAT_UINT8 Offset:offset + 2];
            record.type = (typeAndLocation & 0xF0) >> 4; // TODO this way or around?
            record.sampleLocation = (typeAndLocation & 0x0F);
            offset += 3;
        }
        
        if (sensorStatusAnnunciationPresent) {
            record.status = [data getIntValueWith:FORMAT_UINT16 Offset:offset];
        }
        // This allows you to check other values that are not provided by the Nordic Semiconductor's Glucose Service in SDK 4.4.2.
//        record.status = 0x1A;
//        record.context.carbohydrateId = 1;
//        record.context.carbohydrateUnits = 0.23f;
//        record.context.meal = 2;
//        record.context.tester = 2;
//        record.context.health = 4;
        // the following values are not implemented yet (see ExpandableRecordAdapter#getChildrenCount() and #getChild(...)
//        record.context.exerciseDuration = 3600;
//        record.context.exerciseIntensity = 45;
//        record.context.medicationId = 3;
//        record.context.medicationQuantity = 0.03f;
//        record.context.medicationUnit =UNIT_kg;
//        record.context.HbA1c = 213.3f;
        
        // data set modifications must be done in UI thread
//        mHandler.post(new Runnable() {
//            @Override
//            public void run() {
//                // insert the new record to storage
//                mRecords.put(record.sequenceNumber, record);
//                
//                // if there is no context information following the measurement data, notify callback about the new record
//                if (!contextInfoFollows)
//                    mCallbacks.onDatasetChanged();
//            }
//        });
        if (!contextInfoFollows) {
            if ([self.delegate respondsToSelector:@selector(onDatasetChanged:)]) {
                [self.delegate onDatasetChanged:self];
            }
        }
        
    } else if ([GM_CONTEXT_CHARACTERISTIC isEqualToString:characteristicUUID]) {
        int offset = 0;
        int flags = [data getIntValueWith:FORMAT_UINT8 Offset:offset];
        offset += 1;
        
        BOOL carbohydratePresent = (flags & 0x01) > 0;
        BOOL mealPresent = (flags & 0x02) > 0;
        BOOL testerHealthPresent = (flags & 0x04) > 0;
        BOOL exercisePresent = (flags & 0x08) > 0;
        BOOL medicationPresent = (flags & 0x10) > 0;
        int medicationUnit = (flags & 0x20) > 0 ? UNIT_l : UNIT_kg;
        BOOL hbA1cPresent = (flags & 0x40) > 0;
        BOOL moreFlagsPresent = (flags & 0x80) > 0;
        
        int sequenceNumber = [data getIntValueWith:FORMAT_UINT16 Offset:offset];
        offset += 2;
        
        GlucoseRecord *record = nil;
        
        for (NSInteger i =0; i<self.mRecords.count; i++) {
            GlucoseRecord *tempRecord = [self.mRecords objectAtIndex:i];
            if (tempRecord.sequenceNumber == sequenceNumber) {
                record = tempRecord;
                break;
            }
        }
        
        if (record == nil) {
            return;
        }
        
        
        MeasurementContext *context = record.context;
        
        if (moreFlagsPresent)
            offset += 1;
        
        if (carbohydratePresent) {
            context.carbohydrateId = [data getIntValueWith:FORMAT_UINT8 Offset:offset];
            context.carbohydrateUnits = [data getFloatValueWithFormatType:FORMAT_SFLOAT Offset:offset + 1];
            offset += 3;
        }
        
        if (mealPresent) {
            context.meal = [data getIntValueWith:FORMAT_UINT8 Offset:offset];
            offset += 1;
        }
        
        if (testerHealthPresent) {
            int testerHealth = [data getIntValueWith:FORMAT_UINT8 Offset:offset];
            context.tester = (testerHealth & 0xF0) >> 4;
            context.health = (testerHealth & 0x0F);
            offset += 1;
        }
        
        if (exercisePresent) {
            context.exerciseDuration = [data getIntValueWith:FORMAT_UINT16 Offset:offset];
            context.exerciseIntensity = [data getIntValueWith:FORMAT_UINT8 Offset:offset+2];
            offset += 3;
        }
        
        if (medicationPresent) {
            context.medicationId = [data getIntValueWith:FORMAT_UINT8 Offset:offset];
            context.medicationQuantity = [data getFloatValueWithFormatType:FORMAT_SFLOAT Offset:offset + 1];
            context.medicationUnit = medicationUnit;
            offset += 3;
        }
        
        if (hbA1cPresent) {
            context.HbA1c = [data getFloatValueWithFormatType:FORMAT_SFLOAT Offset:offset];
        }
        
        // notify callback about the new record
        
        if ([self.delegate respondsToSelector:@selector(onDatasetChanged:)]) {
            [self.delegate onDatasetChanged:self];
        }
    }
}

-(void)parseGLSOpValue:(NSData*)data withCharacteristic:(NSString *)characteristicUUID{
    
    // Record Access Control Point characteristic
    int offset = 0;
    int opCode = [data getIntValueWith:FORMAT_UINT8 Offset:offset];
    offset += 2; // skip the operator
    
    if (opCode == OP_CODE_NUMBER_OF_STORED_RECORDS_RESPONSE) {
        // We've obtained the number of all records
        int number = [data getIntValueWith:FORMAT_UINT16 Offset:offset];
        
        if ([self.delegate respondsToSelector:@selector(onNumberOfRecordsRequested:)]) {
            [self.delegate onNumberOfRecordsRequested:number];
        }
        
        // Request the records
        if (number > 0) {
            
            self.opData = [NSMutableData data];
            [self setOpCode:nil OpCode:OP_CODE_REPORT_STORED_RECORDS Operator:OPERATOR_ALL_RECORDS];
            [[HMBluetooth sharedInstance]writeCharacteristicWithServiceUUID:GLS_SERVICE_UUID CharacteristicUUID:RACP_CHARACTERISTIC data:self.opData CompleteBlock:^(CBPeripheral *peripheral, CBCharacteristic *characteristic, NSError *error) {
                
            }];
            
        } else {
            if ([self.delegate respondsToSelector:@selector(onOperationCompleted)]) {
                [self.delegate onOperationCompleted];
            }
        }
    } else if (opCode == OP_CODE_RESPONSE_CODE) {
//        int requestedOpCode = [data getIntValueWith:FORMAT_UINT8 Offset:offset];
        int responseCode = [data getIntValueWith:FORMAT_UINT8 Offset:offset + 1];
        
        switch (responseCode) {
            case RESPONSE_SUCCESS:
                if (!mAbort){
                    if ([self.delegate respondsToSelector:@selector(onOperationCompleted)]) {
                        [self.delegate onOperationCompleted];
                    }
                }
                else{
                    if ([self.delegate respondsToSelector:@selector(onOperationAborted)]) {
                        [self.delegate onOperationAborted];
                    }
                }
                break;
            case RESPONSE_NO_RECORDS_FOUND:
                if ([self.delegate respondsToSelector:@selector(onOperationCompleted)]) {
                    [self.delegate onOperationCompleted];
                }
                break;
            case RESPONSE_OP_CODE_NOT_SUPPORTED:
                if ([self.delegate respondsToSelector:@selector(onOperationNotSupported)]) {
                    [self.delegate onOperationNotSupported];
                }
                break;
            case RESPONSE_PROCEDURE_NOT_COMPLETED:
            case RESPONSE_ABORT_UNSUCCESSFUL:
            default:
                if ([self.delegate respondsToSelector:@selector(onOperationFailed)]) {
                    [self.delegate onOperationFailed];
                }
                 break;
               
        }
        mAbort = false;
    }
}

/**
 * Writes given operation parameters to the characteristic
 *
 * @param characteristic
 *            the characteristic to write. This must be the Record Access Control Point characteristic
 * @param opCode
 *            the operation code
 * @param operator
 *            the operator (see {@link #OPERATOR_NULL} and others
 * @param params
 *            optional parameters (one for >=, <=, two for the range, none for other operators)
 */
-(void)setOpCode:(CBCharacteristic *)characteristic OpCode:(int) opCode Operator:(int)operator,... {
    
    va_list args;
    NSMutableArray *otherParams = [NSMutableArray new];

    va_start(args, operator);
    if (operator) {
        NSObject *other;
        while ((other = va_arg(args, NSObject *))) {
            NSLog(@"Do something with other: %@", other);
            [otherParams addObject:other];
        }
        
         va_end(args);
    }
    
    //int size = 2 + ((otherParams.count > 0) ? 1 : 0) + otherParams.count * 2; // 1 byte for opCode, 1 for operator, 1 for filter type (if parameters exists) and 2 for each parameter
   
//    characteristic.setValue(new byte[size]);
//    self.opData setValue:<#(nullable id)#> forKey:<#(nonnull NSString *)#>
    
    // write the operation  code
    int offset = 0;
    [self.opData setValue:opCode FormatType:FORMAT_UINT8 Offset:offset];
    offset += 1;
    
    // write the operator. This is always present but may be equal to OPERATOR_NULL
    [self.opData setValue:operator FormatType:FORMAT_UINT8 Offset:offset];
    
    offset += 1;
    
    // if parameters exists, append them. Parameters should be sorted from minimum to maximum. Currently only one or two params are allowed
    if (otherParams.count > 0) {
        // our implementation use only sequence number as a filer type
        [self.opData setValue:FILTER_TYPE_SEQUENCE_NUMBER FormatType:FORMAT_UINT8 Offset:offset];
        offset += 1;
        
        for (NSNumber * value in otherParams) {
            [self.opData setValue:[value intValue] FormatType:FORMAT_UINT16 Offset:offset];

            offset += 2;
        }
    }
}
#pragma mark - Records
-(void)refreshRecords{
    if (self.mRecords.count == 0) {
        [self getAllRecords];
    } else {
        if ([self.delegate respondsToSelector:@selector(onOperationStarted)]) {
            [self.delegate onOperationStarted];
        }
        
        // obtain the last sequence number
        GlucoseRecord *record=[self.mRecords lastObject];
        int sequenceNumber = record.sequenceNumber + 1;
        
        self.opData = [NSMutableData data];
        [self setOpCode:nil OpCode:OP_CODE_REPORT_STORED_RECORDS Operator:OPERATOR_GREATER_THEN_OR_EQUAL,sequenceNumber];
        [[HMBluetooth sharedInstance]writeCharacteristicWithServiceUUID:GLS_SERVICE_UUID CharacteristicUUID:RACP_CHARACTERISTIC data:self.opData CompleteBlock:^(CBPeripheral *peripheral, CBCharacteristic *characteristic, NSError *error) {
            
        }];
        // Info:
        // Operators OPERATOR_LESS_THEN_OR_EQUAL and OPERATOR_RANGE are not supported by Nordic Semiconductor Glucose Service in SDK 4.4.2.
    }
}


/**
 * Sends the request to obtain the last (most recent) record from glucose device. The data will be returned to Glucose Measurement characteristic as a notification followed by Record Access
 * Control Point indication with status code ({@link #RESPONSE_SUCCESS} or other in case of error.
 */
-(void)getLastRecord{
    [self clear];
    
    if ([self.delegate respondsToSelector:@selector(onOperationStarted)]) {
        [self.delegate onOperationStarted];
    }
    
    self.opData = [NSMutableData data];
    [self setOpCode:nil OpCode:OP_CODE_REPORT_STORED_RECORDS Operator:OPERATOR_LAST_RECORD];
    [[HMBluetooth sharedInstance]writeCharacteristicWithServiceUUID:GLS_SERVICE_UUID CharacteristicUUID:RACP_CHARACTERISTIC data:self.opData CompleteBlock:^(CBPeripheral *peripheral, CBCharacteristic *characteristic, NSError *error) {
        
    }];

}

/**
 * Sends the request to obtain the first (oldest) record from glucose device. The data will be returned to Glucose Measurement characteristic as a notification followed by Record Access Control
 * Point indication with status code ({@link #RESPONSE_SUCCESS} or other in case of error.
 */
-(void)getFirstRecord{
    [self clear];
    
    if ([self.delegate respondsToSelector:@selector(onOperationStarted)]) {
        [self.delegate onOperationStarted];
    }
    
    self.opData = [NSMutableData data];
    [self setOpCode:nil OpCode:OP_CODE_REPORT_STORED_RECORDS Operator:OPERATOR_FIRST_RECORD];
    [[HMBluetooth sharedInstance]writeCharacteristicWithServiceUUID:GLS_SERVICE_UUID CharacteristicUUID:RACP_CHARACTERISTIC data:self.opData CompleteBlock:^(CBPeripheral *peripheral, CBCharacteristic *characteristic, NSError *error) {
        
    }];
}

/**
 * Sends the request to obtain all records from glucose device. Initially we want to notify him/her about the number of the records so the {@link #OP_CODE_REPORT_NUMBER_OF_RECORDS} is send. The
 * data will be returned to Glucose Measurement characteristic as a notification followed by Record Access Control Point indication with status code ({@link #RESPONSE_SUCCESS} or other in case of
 * error.
 */
-(void)getAllRecords {
    [self clear];
    
    if ([self.delegate respondsToSelector:@selector(onOperationStarted)]) {
        [self.delegate onOperationStarted];
    }
    
    self.opData = [NSMutableData data];
    [self setOpCode:nil OpCode:OP_CODE_REPORT_NUMBER_OF_RECORDS Operator:OPERATOR_ALL_RECORDS];
    
    [[HMBluetooth sharedInstance]writeCharacteristicWithServiceUUID:GLS_SERVICE_UUID CharacteristicUUID:RACP_CHARACTERISTIC data:self.opData CompleteBlock:^(CBPeripheral *peripheral, CBCharacteristic *characteristic, NSError *error) {
        
    }];
}

/**
 * Returns all records as a sparse array where sequence number is the key.
 *
 * @return the records list
 */
-(NSArray<GlucoseRecord *>*) getRecords{
    return self.mRecords;
}

/**
 * Clears the records list locally
 */
-(void)clear{
    [self.mRecords removeAllObjects];
    
    if ([self.delegate respondsToSelector:@selector(onDatasetChanged:)]) {
        [self.delegate onDatasetChanged:self];
    }
    
}
/**
 * Sends the request to delete all data from the device. A Record Access Control Point indication with status code ({@link #RESPONSE_SUCCESS} (or other in case of error) will be send.
 *
 * FIXME This method is not supported by Nordic Semiconductor Glucose Service in SDK 4.4.2.
 */
-(void)deleteAllRecords {
    [self clear];
    if ([self.delegate respondsToSelector:@selector(onOperationStarted)]) {
        [self.delegate onOperationStarted];
    }
    
    self.opData = [NSMutableData data];
    [self setOpCode:nil OpCode:OP_CODE_DELETE_STORED_RECORDS Operator:OPERATOR_ALL_RECORDS];
    [[HMBluetooth sharedInstance]writeCharacteristicWithServiceUUID:GLS_SERVICE_UUID CharacteristicUUID:RACP_CHARACTERISTIC data:self.opData CompleteBlock:^(CBPeripheral *peripheral, CBCharacteristic *characteristic, NSError *error) {
        
    }];

}

/**
 * Sends abort operation signal to the device
 */
-(void)abort{
    mAbort = true;
    self.opData = [NSMutableData data];
    [self setOpCode:nil OpCode:OP_CODE_ABORT_OPERATION Operator:OPERATOR_NULL];
    [[HMBluetooth sharedInstance]writeCharacteristicWithServiceUUID:GLS_SERVICE_UUID CharacteristicUUID:RACP_CHARACTERISTIC data:self.opData CompleteBlock:^(CBPeripheral *peripheral, CBCharacteristic *characteristic, NSError *error) {
        
    }];
}

#pragma mark -Getter and Setter
-(NSMutableArray<GlucoseRecord *>*)mRecords{
    if (!_mRecords) {
        _mRecords = [NSMutableArray new];
    }
    return _mRecords;
}
-(NSMutableData *)opData{
    if (!_opData) {
        _opData = [NSMutableData new];
    }
    return _opData;
}
@end
