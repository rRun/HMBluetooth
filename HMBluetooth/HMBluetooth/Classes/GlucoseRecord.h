//
//  GlucoseRecord.h
//  Pods
//
//  Created by 何霞雨 on 16/8/18.
//
//

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSInteger,GLS_UNIT) {
    UNIT_kgpl=0,//单位为kgpl
    UNIT_molpl=1,//单位为molpl
};

typedef NS_ENUM(NSInteger,UNITs) {
    UNIT_kg=0,//单位为kg
    UNIT_l=1,//单位为l
};

typedef NS_ENUM(NSInteger,CARBOHYDRATE) {
    Not_present_Carbohydrate=0,//未设置
    Breakfast=1,//早餐
    Lunch=2,//午餐
    Dinner=3,//晚餐
    Snack=4,//点心
    Drink=5,//喝水
    Supper=6,//晚餐
    Brunch=7,//早午餐
};

typedef NS_ENUM(NSInteger,MEAL) {
    Not_present_Meal=0,//未设置
    Preprandial_Before_Meal=1,
    Preprandial_After_Meal=2,
    Fasting=3,
    Casual=4,
    Bedtime=5,
};

typedef NS_ENUM(NSInteger,TESTER) {
    Not_present_Tester=0,//未设置
    Self=1,
    Health_Care_Professional=2,
    Lab_test=3,
    Tester_value_not_available=15,
};

typedef NS_ENUM(NSInteger,HEALTH) {
    Not_present_Health=0,//未设置
    Minor_health_issues=1,
    Major_health_issues=2,
    During_menses=3,
    Under_stress=4,
    No_health_issues=5,
    Health_value_not_available=15,
};

typedef NS_ENUM(NSInteger,MEDICATION) {
    Not_present_Medication=0,//未设置
    Rapid_acting_insulin=1,//快效胰岛素
    Short_acting_insulin=2,//短效胰岛素
    Intermediate_acting_insulin=3,//中效胰岛素
    Long_acting_insulin=4,//长效胰岛素
    Pre_mixed_insulin=5,//预混胰岛素
};

#pragma mark - MeasurementContext

@interface MeasurementContext : NSObject
/**
 * One of the following:<br/>
 * 0 Not present<br/>
 * 1 Breakfast<br/>
 * 2 Lunch<br/>
 * 3 Dinner<br/>
 * 4 Snack<br/>
 * 5 Drink<br/>
 * 6 Supper<br/>
 * 7 Brunch
 */
@property (nonatomic,assign) CARBOHYDRATE carbohydrateId;
/** Number of kilograms of carbohydrate */
@property (nonatomic,assign) float carbohydrateUnits;
/**
 * One of the following:<br/>
 * 0 Not present<br/>
 * 1 Preprandial (before meal)<br/>
 * 2 Postprandial (after meal)<br/>
 * 3 Fasting<br/>
 * 4 Casual (snacks, drinks, etc.)<br/>
 * 5 Bedtime
 */
@property (nonatomic,assign) MEAL meal;
/**
 * One of the following:<br/>
 * 0 Not present<br/>
 * 1 Self<br/>
 * 2 Health Care Professional<br/>
 * 3 Lab test<br/>
 * 15 Tester value not available
 */
@property (nonatomic,assign) TESTER tester;
/**
 * One of the following:<br/>
 * 0 Not present<br/>
 * 1 Minor health issues<br/>
 * 2 Major health issues<br/>
 * 3 During menses<br/>
 * 4 Under stress<br/>
 * 5 No health issues<br/>
 * 15 Tester value not available
 */
@property (nonatomic,assign) HEALTH health;
/** Exercise duration in seconds. 0 if not present */
@property (nonatomic,assign) int exerciseDuration;
/** Exercise intensity in percent. 0 if not present */
@property (nonatomic,assign) int exerciseIntensity;
/**
 * One of the following:<br/>
 * 0 Not present<br/>
 * 1 Rapid acting insulin<br/>
 * 2 Short acting insulin<br/>
 * 3 Intermediate acting insulin<br/>
 * 4 Long acting insulin<br/>
 * 5 Pre-mixed insulin
 */
@property (nonatomic,assign) MEDICATION medicationId;
/** Quantity of medication. See {@link #medicationUnit} for the unit. */
@property (nonatomic,assign) float medicationQuantity;
/** One of the following: {@link GlucoseRecord.MeasurementContext#UNIT_kg}, {@link GlucoseRecord.MeasurementContext#UNIT_l}. */
@property (nonatomic,assign) UNITs medicationUnit;
/** HbA1c value. 0 if not present */
@property (nonatomic,assign) float HbA1c;

@end

#pragma mark - GlucoseRecord
@interface GlucoseRecord : NSObject

/** Record sequence number */
@property (nonatomic,assign) int sequenceNumber;
/** The base time of the measurement */
@property (nonatomic,strong) NSCalendar *time;
/** Time offset of the record */
@property (nonatomic,assign) int timeOffset;
/** The glucose concentration. 0 if not present */
@property (nonatomic,assign) float glucoseConcentration;
/** Concentration unit. One of the following: {@link GlucoseRecord#UNIT_kgpl}, {@link GlucoseRecord#UNIT_molpl} */
@property (nonatomic,assign) GLS_UNIT unit;
/** The type of the record. 0 if not present */
@property (nonatomic,assign) int type;
/** The sample location. 0 if unknown */
@property (nonatomic,assign) int sampleLocation;
/** Sensor status annunciation flags. 0 if not present */
@property (nonatomic,assign) int status;

@property (nonatomic,strong) MeasurementContext *context;
@end


