//
//  BMPManager.m
//  Pods
//
//  Created by 何霞雨 on 16/8/11.
//
//

#import "BMPParser.h"

#import <CoreBluetooth/CoreBluetooth.h>

#import "NSData+HMParser.h"

@implementation BMPParser


-(void)parseBPMValueWithCharacteristic:(CBCharacteristic *)characteristic{
    // Both BPM and ICP have the same structure.
    NSData *data = characteristic.value;
    // first byte - flags
    int offset = 0;
    int flags = [data getIntValueWith:FORMAT_UINT8 Offset:offset++];
    // See BPMManagerCallbacks.UNIT_* for unit options
    int unit = flags & 0x01;
    BOOL timestampPresent = (flags & 0x02) > 0;
    BOOL pulseRatePresent = (flags & 0x04) > 0;
    
    if ([BPM_CHARACTERISTIC_UUID isEqualToString:characteristic.UUID.UUIDString]) {
        // following bytes - systolic, diastolic and mean arterial pressure
        float systolic = [data getFloatValueWithFormatType:FORMAT_SFLOAT Offset:offset];
        float diastolic = [data getFloatValueWithFormatType:FORMAT_SFLOAT Offset:offset + 2];
        float meanArterialPressure = [data getFloatValueWithFormatType:FORMAT_SFLOAT Offset:offset + 4];
        offset += 6;
        
        if ([self.delegate respondsToSelector:@selector(onBloodPressureMeasurementReadWithSystolic:Diastolic:MeanArterialPressure:Unit:)]) {
            [self.delegate onBloodPressureMeasurementReadWithSystolic:systolic Diastolic:diastolic MeanArterialPressure:meanArterialPressure Unit:unit];
        }
        
    } else if ([ICP_CHARACTERISTIC_UUID isEqualToString:characteristic.UUID.UUIDString]) {
        // following bytes - cuff pressure. Diastolic and MAP are unused
        float cuffPressure = [data getFloatValueWithFormatType:FORMAT_SFLOAT Offset:offset];
        offset += 6;
        
        if ([self.delegate respondsToSelector:@selector(onIntermediateCuffPressureReadWithCuffPressure:Unit:)]) {
            [self.delegate onIntermediateCuffPressureReadWithCuffPressure:cuffPressure Unit:unit];
        }
        
    }
    
    // parse timestamp if present
    if (timestampPresent) {
        //    先定义一个遵循某个历法的日历对象
        NSCalendar *greCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        
        //    定义一个NSDateComponents对象，设置一个时间点
        NSDateComponents *dateComponentsForDate = [[NSDateComponents alloc] init];
        [dateComponentsForDate setYear:[data getIntValueWith:FORMAT_UINT16 Offset:offset]];
        [dateComponentsForDate setMonth:[data getIntValueWith:FORMAT_UINT8 Offset:offset+2]];
        [dateComponentsForDate setDay:[data getIntValueWith:FORMAT_UINT8 Offset:offset+3]];
        [dateComponentsForDate setHour:[data getIntValueWith:FORMAT_UINT8 Offset:offset+4]];
        [dateComponentsForDate setMinute:[data getIntValueWith:FORMAT_UINT8 Offset:offset+5]];
        [dateComponentsForDate setSecond:[data getIntValueWith:FORMAT_UINT8 Offset:offset+6]];
        
        greCalendar = [dateComponentsForDate calendar];
        
        offset += 7;
        
        if ([self.delegate respondsToSelector:@selector(onTimestampReadWithCalendar:)]) {
            [self.delegate onTimestampReadWithCalendar:greCalendar];
        }
        
    } else
        if ([self.delegate respondsToSelector:@selector(onTimestampReadWithCalendar:)]) {
            [self.delegate onTimestampReadWithCalendar:nil];
        }
    
    // parse pulse rate if present
    if (pulseRatePresent) {
        float pulseRate = [data getFloatValueWithFormatType:FORMAT_SFLOAT Offset:offset];
        offset += 2;
        
        if ([self.delegate respondsToSelector:@selector(onPulseRateReadWithPulseRate:)]) {
            [self.delegate onPulseRateReadWithPulseRate:pulseRate];
        }

    } else
        if ([self.delegate respondsToSelector:@selector(onPulseRateReadWithPulseRate:)]) {
            [self.delegate onPulseRateReadWithPulseRate:-1];
        }

}
@end
