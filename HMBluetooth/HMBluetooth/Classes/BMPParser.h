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
const static NSString *BP_SERVICE_UUID = @"00001810-0000-1000-8000-00805f9b34fb";
/** Blood Pressure Measurement characteristic UUID */
const static NSString * BPM_CHARACTERISTIC_UUID = @"00002A35-0000-1000-8000-00805f9b34fb";
/** Intermediate Cuff Pressure characteristic UUID */
const static NSString * ICP_CHARACTERISTIC_UUID =@"00002A36-0000-1000-8000-00805f9b34fb";

@class CBCharacteristic;

@interface BMPParser : NSObject
@property (nonatomic,weak)id <BMPParserPrt> delegate;

-(void)parseBPMValueWithCharacteristic:(CBCharacteristic *)characteristic;

@end
