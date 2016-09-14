//
//  NSMutableData+HMParser.m
//  Pods
//
//  Created by 何霞雨 on 16/8/19.
//
//

#import "NSMutableData+HMParser.h"
#import "NSData+HMParser.h"

@implementation NSMutableData (HMParser)
/**
 * Set the locally stored value of this characteristic.
 * <p>See {@link #setValue(byte[])} for details.
 *
 * @param value New value for this characteristic
 * @param formatType Integer format type used to transform the value parameter
 * @param offset Offset at which the value should be placed
 * @return true if the locally stored value has been set
 */
-(BOOL)setValue:(int) value FormatType:(int) formatType Offset:(int)offset {
    
    int len = offset + [self getTypeLen:formatType];
    NSMutableData *mValue = [[NSMutableData alloc]initWithLength:len];
    
    if (len > self.length) return false;
    self.bytes;
    switch (formatType) {
        case FORMAT_SINT8:
            value = [self intToSignedBits:value size:8];
            // Fall-through intended
        case FORMAT_UINT8:
            [self replaceBytesInRange:NSMakeRange(offset, 1) withBytes:(Byte*)(value & 0xFF)];
//            mValue[offset] = (Byte*)(value & 0xFF);
            break;
            
        case FORMAT_SINT16:
            value = [self intToSignedBits:value size:16];
            // Fall-through intended
        case FORMAT_UINT16:
            [mValue replaceBytesInRange:NSMakeRange(offset++, 1) withBytes:(Byte*)(value & 0xFF)];
            [mValue replaceBytesInRange:NSMakeRange(offset, 1) withBytes:(Byte*)((value >> 8) & 0xFF)];
            break;
            
        case FORMAT_SINT32:
            value = [self intToSignedBits:value size:32];
            // Fall-through intended
        case FORMAT_UINT32:
            [mValue replaceBytesInRange:NSMakeRange(offset++, 1) withBytes:(Byte*)(value & 0xFF)];
            [mValue replaceBytesInRange:NSMakeRange(offset++, 1) withBytes:(Byte*)((value >> 8) & 0xFF)];
            [mValue replaceBytesInRange:NSMakeRange(offset++, 1) withBytes:(Byte*)((value >> 16) & 0xFF)];
            [mValue replaceBytesInRange:NSMakeRange(offset, 1) withBytes:(Byte*)((value >> 24) & 0xFF)];
            break;
            
        default:
            return false;
    }
    return true;
}

#pragma mark  - Private
/**
 * Convert an integer into the signed bits of a given length.
 */
-(int)intToSignedBits:(int) i size:(int) size {
    if (i < 0) {
        i = (1 << (size-1)) + (i & ((1 << (size-1)) - 1));
    }
    return i;
}
@end
