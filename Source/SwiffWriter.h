/*
    SwiffWriter.h
    Copyright (c) 2011-2012, musictheory.net, LLC.  All rights reserved.

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

#import <SwiffImport.h>
#import <SwiffTypes.h>


typedef struct SwiffWriter SwiffWriter;

extern SwiffWriter *SwiffWriterCreate(void);
extern void SwiffWriterFree(SwiffWriter *writer);

extern NSData *SwiffWriterGetData(SwiffWriter *writer);

extern NSData *SwiffWriterGetDataWithHeader(SwiffWriter *writer, SwiffHeader header);


// Tags
//
extern void SwiffWriterStartTag(SwiffWriter *writer, SwiffTag tag, NSInteger version);
extern void SwiffWriterEndTag(SwiffWriter *writer);


// Bitfields
//
extern void SwiffWriterByteAlign(SwiffWriter *writer);

extern void SwiffWriterAppendUBits(SwiffWriter *writer, UInt8 numberOfBits, UInt32 value);
extern void SwiffWriterAppendSBits(SwiffWriter *writer, UInt8 numberOfBits, SInt32 value);


// Primitives
//
extern void SwiffWriterAppendBytes(SwiffWriter *writer, const UInt8 *bytes, UInt32 length);

extern void SwiffWriterAppendSInt8(SwiffWriter *writer, SInt8 value);
extern void SwiffWriterAppendSInt16(SwiffWriter *writer, SInt16 value);
extern void SwiffWriterAppendSInt32(SwiffWriter *writer, SInt32 value);

extern void SwiffWriterAppendUInt8(SwiffWriter *writer, UInt8 value);
extern void SwiffWriterAppendUInt16(SwiffWriter *writer, UInt16 value);
extern void SwiffWriterAppendUInt32(SwiffWriter *writer, UInt32 value);

extern void SwiffWriterAppendFixed8(SwiffWriter *writer, CGFloat value);


// Structs
//
extern void SwiffWriterAppendRect(SwiffWriter *writer, CGRect value);


// Objects
extern void SwiffWriterAppendData(SwiffWriter *writer, NSData *data);
