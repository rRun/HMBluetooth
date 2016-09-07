//
//  NSData+HMParser.m
//  Pods
//
//  Created by 何霞雨 on 16/8/18.
//
//

#import "NSData+HMParser.h"

@implementation NSData (HMParser)

-(int)getIntValueWith:(int)formatType Offset:(int)offset{
    
    Byte *mValue = (Byte *)[self bytes];
    if ((offset + [self getTypeLen:formatType]) > self.length) return 0;
    switch (formatType) {
        case FORMAT_UINT8:
            return [self unsignedByteToInt:mValue[offset]];
            
        case FORMAT_UINT16:
            return [self unsignedByteToIntB0:mValue[offset] B1:mValue[offset+1]];
            
        case FORMAT_UINT32:
            return [self unsignedByteToIntB0:mValue[offset] B1:mValue[offset+1] B2:mValue[offset+2] B3:mValue[offset+3]];
        case FORMAT_SINT8:
            return [self unsignedToSigned:[self unsignedByteToInt:mValue[offset]] Size:8];
            
        case FORMAT_SINT16:
            return [self unsignedToSigned:[self unsignedByteToIntB0:mValue[offset] B1:mValue[offset+1]] Size:16];
            
        case FORMAT_SINT32:
            return [self unsignedToSigned:[self unsignedByteToIntB0:mValue[offset] B1:mValue[offset+1] B2:mValue[offset+2] B3:mValue[offset+3]] Size:32];
    }
    
    return 0;
    
}


/**
 * Return the stored value of this characteristic.
 * <p>See {@link #getValue} for details.
 *
 * @param formatType The format type used to interpret the characteristic
 *                   value.
 * @param offset Offset at which the float value can be found.
 * @return Cached value of the characteristic at a given offset or null
 *         if the requested offset exceeds the value size.
 */
-(float)getFloatValueWithFormatType:(int)formatType Offset:(int)offset{
    
    Byte *mValue = (Byte *)[self bytes];
    if ((offset + [self getTypeLen:formatType]) > self.length) return 0;
    
    switch (formatType) {
        case FORMAT_SFLOAT:
            return [self bytesToFloatB0:mValue[offset] B1: mValue[offset+1]];
            
        case FORMAT_FLOAT:
            return [self bytesToFloatB0:mValue[offset] B1:mValue[offset+1] B2:mValue[offset+2] B3:mValue[offset+3]];
    }
    
    return 0;
    
}
#pragma mark - Int
/**
 * Returns the size of a give value type.
 */
-(int)getTypeLen:(int)formatType{
    return formatType & 0xF;
}

/**
 * Convert a signed byte to an unsigned int.
 */
-(int)unsignedByteToInt:(Byte)b{
    return b & 0xFF;
}

/**
 * Convert signed bytes to a 16-bit unsigned int.
 */
-(int)unsignedByteToIntB0:(Byte)b0 B1:(Byte)b1{
    return [self unsignedByteToInt:b0] + ([self unsignedByteToInt:b1] << 8);
}

/**
 * Convert signed bytes to a 32-bit unsigned int.
 */
-(int)unsignedByteToIntB0:(Byte)b0 B1:(Byte)b1 B2:(Byte)b2 B3:(Byte)b3{
    return [self unsignedByteToInt:b0] + ([self unsignedByteToInt:b1] << 8) + ([self unsignedByteToInt:b2] << 16) + ([self unsignedByteToInt:b3] << 24);
}


/**
 * Convert an unsigned integer value to a two's-complement encoded
 * signed value.
 */
-(int)unsignedToSigned:(int) unsignedInt Size:(int)size{
    if ((unsignedInt & (1 << (size-1))) != 0) {
        unsignedInt = -1 * ((1 << (size-1)) - (unsignedInt & ((1 << (size-1))-1)));
    }
    return unsignedInt;
}

#pragma mark - Float


/**
 * Convert signed bytes to a 16-bit short float value.
 */
-(float)bytesToFloatB0:(Byte )b0 B1:(Byte )b1{
    int mantissa =[self unsignedToSigned:([self unsignedByteToInt:b0]
                                          + (([self unsignedByteToInt:b1] & 0x0F) << 8)) Size:12];
    int exponent = [self unsignedToSigned:([self unsignedByteToInt:b1] >> 4) Size:4];
    return (float)(mantissa * powf(10, exponent));
}

/**
 * Convert signed bytes to a 32-bit short float value.
 */
-(float)bytesToFloatB0:(Byte )b0 B1:(Byte )b1 B2:(Byte )b2 B3:(Byte )b3{
    int mantissa = [self unsignedToSigned:([self unsignedByteToInt:b0]
                                           + ([self unsignedByteToInt:b1] << 8)
                                           + ([self unsignedByteToInt:b2] << 16)) Size:24];
    return (float)(mantissa * powf(10, b3));

}
@end
