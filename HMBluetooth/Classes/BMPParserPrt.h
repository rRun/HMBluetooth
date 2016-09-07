//
//  BMPManagerPrt.h
//  Pods
//
//  Created by 何霞雨 on 16/8/11.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger,BMP_UNIT) {//血压单位
    UNIT_mmHG=0,//单位为mmhg
    UNIT_kPa=1,//单位为kPa
};

@protocol BMPParserPrt <NSObject>

/**
 * Called when new BPM value has been obtained from the sensor
 *
 * @param systolic
 * @param diastolic
 * @param meanArterialPressure
 * @param unit
 *            one of the following {@link #UNIT_kPa} or {@link #UNIT_mmHG}
 */
-(void)onBloodPressureMeasurementReadWithSystolic:(float)systolic Diastolic:(float)diastolic MeanArterialPressure:(float)meanArterialPressure Unit:(BMP_UNIT)unit;

/**
 * Called when new ICP value has been obtained from the device
 *
 * @param cuffPressure
 * @param unit
 *            one of the following {@link #UNIT_kPa} or {@link #UNIT_mmHG}
 */
-(void)onIntermediateCuffPressureReadWithCuffPressure:(float)cuffPressure Unit:(BMP_UNIT)unit;

/**
 * Called when new pulse rate value has been obtained from the device. If there was no pulse rate in the packet the parameter will be equal -1.0f
 *
 * @param pulseRate
 *            pulse rate or -1.0f
 */
-(void)onPulseRateReadWithPulseRate:(float)pulseRate;

/**
 * Called when the timestamp value has been read from the device. If there was no timestamp information the parameter will be <code>null</code>
 *
 * @param calendar
 *            the timestamp or <code>null</code>
 */
-(void)onTimestampReadWithCalendar:(NSCalendar *)calendar;

@end
