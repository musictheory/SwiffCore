/*
    SwiftWriter.h
    Copyright (c) 2011, musictheory.net, LLC.  All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
        * Redistributions of source code must retain the above copyright
          notice, this list of conditions and the following disclaimer.
        * Redistributions in binary form must reproduce the above copyright
          notice, this list of conditions and the following disclaimer in the
          documentation and/or other materials provided with the distribution.
        * Neither the name of musictheory.net, LLC nor the names of its contributors
          may be used to endorse or promote products derived from this software
          without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
    ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
    WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
    DISCLAIMED. IN NO EVENT SHALL MUSICTHEORY.NET, LLC BE LIABLE FOR ANY
    DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
    (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
    ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
    (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
    SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import <SwiftImport.h>
#import <SwiftBase.h>


typedef struct _SwiftWriter SwiftWriter;

extern SwiftWriter *SwiftWriterCreate(void);
extern void SwiftWriterFree(SwiftWriter *writer);

extern NSData *SwiftWriterGetData(SwiftWriter *writer);

extern NSData *SwiftWriterGetDataWithHeader(SwiftWriter *writer, SwiftHeader header);


// Tags
//
extern void SwiftWriterStartTag(SwiftWriter *writer, SwiftTag tag, NSInteger version);
extern void SwiftWriterEndTag(SwiftWriter *writer);


// Bitfields
//
extern void SwiftWriterByteAlign(SwiftWriter *writer);

extern void SwiftWriterAppendUBits(SwiftWriter *writer, UInt8 numberOfBits, UInt32 value);
extern void SwiftWriterAppendSBits(SwiftWriter *writer, UInt8 numberOfBits, SInt32 value);


// Primitives
//
extern void SwiftWriterAppendBytes(SwiftWriter *writer, const UInt8 *bytes, UInt32 length);

extern void SwiftWriterAppendSInt8(SwiftWriter *writer, SInt8 value);
extern void SwiftWriterAppendSInt16(SwiftWriter *writer, SInt16 value);
extern void SwiftWriterAppendSInt32(SwiftWriter *writer, SInt32 value);

extern void SwiftWriterAppendUInt8(SwiftWriter *writer, UInt8 value);
extern void SwiftWriterAppendUInt16(SwiftWriter *writer, UInt16 value);
extern void SwiftWriterAppendUInt32(SwiftWriter *writer, UInt32 value);

extern void SwiftWriterAppendFixed8(SwiftWriter *writer, CGFloat value);


// Structs
//
extern void SwiftWriterAppendRect(SwiftWriter *writer, CGRect value);


// Objects
extern void SwiftWriterAppendData(SwiftWriter *writer, NSData *data);
