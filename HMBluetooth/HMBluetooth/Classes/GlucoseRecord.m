//
//  GlucoseRecord.m
//  Pods
//
//  Created by 何霞雨 on 16/8/18.
//
//

#import "GlucoseRecord.h"

#pragma mark - GlucoseRecord
@interface GlucoseRecord()

@end

@implementation GlucoseRecord
-(MeasurementContext *)context{
    if (!_context) {
        _context = [MeasurementContext new];
    }
    
    return _context;
}
@end

#pragma mark - MeasurementContext

@interface MeasurementContext()

@end

@implementation MeasurementContext

@end