//
//  NSMutableData+HMParser.h
//  Pods
//
//  Created by 何霞雨 on 16/8/19.
//
//

#import <Foundation/Foundation.h>

@interface NSMutableData (HMParser)
-(BOOL)setValue:(int) value FormatType:(int) formatType Offset:(int)offset;
@end
