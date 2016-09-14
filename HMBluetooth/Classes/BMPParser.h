//
//  BMPManager.h
//  Pods
//
//  Created by 何霞雨 on 16/8/11.
//
//

#import <Foundation/Foundation.h>
#import "BMPParserPrt.h"

/** Blood Pressure service UUID */
static NSString *BP_SERVICE_UUID = @"1810";
/** Blood Pressure Measurement characteristic UUID */
static NSString * BPM_CHARACTERISTIC_UUID = @"2A35";
/** Intermediate Cuff Pressure characteristic UUID */
static NSString * ICP_CHARACTERISTIC_UUID =@"2A36";

@class CBCharacteristic;

@interface BMPParser : NSObject
@property (nonatomic,weak)id <BMPParserPrt> delegate;

-(void)parseBPMValueWithCharacteristic:(CBCharacteristic *)characteristic;

@end
