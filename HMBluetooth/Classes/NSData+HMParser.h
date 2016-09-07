//
//  NSData+HMParser.h
//  Pods
//
//  Created by 何霞雨 on 16/8/18.
//
//

#import <Foundation/Foundation.h>

/**
 * Characteristic value format type uint8
 */
const static int FORMAT_UINT8 = 0x11;

/**
 * Characteristic value format type uint16
 */
const static int FORMAT_UINT16 = 0x12;

/**
 * Characteristic value format type uint32
 */
const static int FORMAT_UINT32 = 0x14;

/**
 * Characteristic value format type sint8
 */
const static int FORMAT_SINT8 = 0x21;

/**
 * Characteristic value format type sint16
 */
const static int FORMAT_SINT16 = 0x22;

/**
 * Characteristic value format type sint32
 */
const static int FORMAT_SINT32 = 0x24;

/**
 * Characteristic value format type sfloat (16-bit float)
 */
const static int FORMAT_SFLOAT = 0x32;

/**
 * Characteristic value format type float (32-bit float)
 */
const static int FORMAT_FLOAT = 0x34;


@interface NSData (HMParser)

-(int)getIntValueWith:(int)formatType Offset:(int)offset;

-(float)getFloatValueWithFormatType:(int)formatType Offset:(int)offset;

//private
-(int)getTypeLen:(int)formatType;
@end
