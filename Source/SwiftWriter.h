//
//  SwiftWriter.h
//  SwiftCore
//
//  Created by Ricci Adams on 2011-10-29.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


extern SwiftWriter *SwiftWriterCreate(void);
extern void SwiftWriterFree(SwiftWriter *writer);

extern NSData *SwiftWriterGetData(SwiftWriter *writer);

extern NSData *SwiftWriterGetDataWithHeader(SwiftWriter *writer, SwiftHeader header);


// Tags
//
extern void SwiftWriterStartTag(SwiftWriter *writer, SwiftTag tag, SwiftVersion version);
extern void SwiftWriterEndTag(SwiftWriter *writer);


// Bitfields
//
extern void SwiftWriterByteAlign(SwiftWriter *writer);

extern void SwiftWriterAppendUBits(SwiftWriter *writer, UInt8 numberOfBits, UInt32 value);
extern void SwiftWriterAppendSBits(SwiftWriter *writer, UInt8 numberOfBits, SInt32 value);


// Primitives
//
extern void SwiftWriterAppendUInt8(SwiftWriter *writer, UInt8 value);
extern void SwiftWriterAppendUInt16(SwiftWriter *writer, UInt16 value);
extern void SwiftWriterAppendUInt32(SwiftWriter *writer, UInt32 value);

extern void SwiftWriterAppendSInt8(SwiftWriter *writer, SInt8 value);
extern void SwiftWriterAppendSInt16(SwiftWriter *writer, SInt16 value);
extern void SwiftWriterAppendSInt32(SwiftWriter *writer, SInt32 value);

extern void SwiftWriterAppendFixed8(SwiftWriter *writer, CGFloat value);


// Structs
//
extern void SwiftWriterAppendRect(SwiftWriter *writer, CGRect value);


// Objects
extern void SwiftWriterAppendData(SwiftWriter *writer, NSData *data);

