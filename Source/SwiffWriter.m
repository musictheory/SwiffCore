/*
    SwiffWriter.m
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

#import "SwiffWriter.h"

#include <stdlib.h>
#include <stdio.h>
#include <zlib.h>
#include <string.h>


struct SwiffWriter {
    CFMutableDataRef data;
    UInt8 bitPosition;
    UInt8 bitByte;

    NSInteger frameCount;
    SwiffTag  currentTag;
    CFMutableDataRef baseData;
};


#pragma mark -
#pragma mark Lifecycle

SwiffWriter *SwiffWriterCreate()
{
    SwiffWriter *writer = calloc(1, sizeof(SwiffWriter));
    writer->data = CFDataCreateMutable(NULL, 0);
    
    return writer;
}


void SwiffWriterFree(SwiffWriter *writer)
{
    if (writer->data)     CFRelease(writer->data);
    if (writer->baseData) CFRelease(writer->baseData);

    free(writer);
}


NSData *SwiffWriterGetData(SwiffWriter *writer)
{
    return [[(__bridge NSData *)writer->data retain] autorelease];
}


NSData *SwiffWriterGetDataWithHeader(SwiffWriter *writer, SwiffHeader header)
{
    SwiffWriterByteAlign(writer);

    SwiffWriter *subwriter = SwiffWriterCreate();

    SwiffWriterAppendRect(subwriter,   header.stageRect);
    SwiffWriterAppendFixed8(subwriter, header.frameRate);
    SwiffWriterAppendUInt16(subwriter, writer->frameCount);
    SwiffWriterAppendData(subwriter, (__bridge NSData *)writer->data);

    UInt32 fileSize = CFDataGetLength(subwriter->data) + 8;

    UInt8 signature[4];
    signature[0] = (header.isCompressed ? 'C' : 'F');
    signature[1] = 'W';
    signature[2] = 'S';
    signature[3] = header.version;

    NSMutableData *result = [NSMutableData dataWithCapacity:(CFDataGetLength(writer->data) + 32)];
    [result appendBytes:&signature length:4];
    [result appendBytes:&fileSize  length:4];

    if (header.isCompressed) {
        z_stream stream;
        bzero(&stream, sizeof(z_stream));

        NSMutableData *compressedData = [[NSMutableData alloc] initWithLength:(32 * 1024)];

        stream.next_in  = (Bytef *)CFDataGetBytePtr(subwriter->data);
        stream.avail_in = CFDataGetLength(subwriter->data);

        if (deflateInit(&stream, Z_BEST_COMPRESSION) == Z_OK) {
            do {
                if (stream.total_out >= [compressedData length]) {
                    [compressedData increaseLengthBy: (32 * 1024)];
                }

                stream.next_out  = [compressedData mutableBytes] + stream.total_out;
                stream.avail_out = (unsigned int)([compressedData length] - stream.total_out);

                deflate(&stream, Z_FINISH);  
            } while (stream.avail_out == 0);

            deflateEnd(&stream);
            
            [result appendBytes:[compressedData mutableBytes] length:stream.total_out];
            
        // Fallback to uncompressed
        } else {
            SwiffWarn(@"Writer", @"SwiffWriterGetDataWithHeader(): falling back to uncompressed");

            [result replaceBytesInRange:NSMakeRange(0, 1) withBytes:"F"];
            [result appendData:(__bridge NSData *)subwriter->data];
        }

        [compressedData release];

    } else {
        [result appendData:(__bridge NSData *)subwriter->data];
    }

    SwiffWriterFree(subwriter);
    
    return result;
}


#pragma mark -
#pragma mark Tags

void SwiffWriterStartTag(SwiffWriter *writer, SwiffTag tag, NSInteger version)
{
    if (writer->baseData == NULL) {
        SwiffTag currentTag;
        SwiffTagJoin(tag, version, &currentTag);
        
        writer->baseData = writer->data;
        writer->data = CFDataCreateMutable(NULL, 0);
        writer->currentTag = currentTag;
        
        if (tag == SwiffTagShowFrame) {
            writer->frameCount++;
        }

    } else {
        SwiffWarn(@"Writer", @"SwiffWriterStartTag() called without ending previous tag with SwiffWriterEnd()");
    }
}


void SwiffWriterEndTag(SwiffWriter *writer)
{
    if (writer->baseData) {
        SwiffTag  tag     = writer->currentTag;
        CFDataRef tagData = writer->data;

        writer->data = writer->baseData;
        writer->baseData = NULL;
        writer->currentTag = 0;
    
        CFIndex length    = CFDataGetLength(tagData);
        BOOL    needsLong = length >= 63;

        SwiffWriterAppendUInt16(writer, (tag << 6) | (needsLong ? 0x3F : length));

        if (needsLong) {
            SwiffWriterAppendSInt32(writer, length);
        }

        SwiffWriterAppendData(writer, (__bridge NSData *)tagData);
        CFRelease(tagData);

    } else {
        SwiffWarn(@"Writer", @"SwiffWriterEnd() called without previous SwiffWriterStartTag()");
    }
}


#pragma mark
#pragma mark Bitfields

static void sCalculateBitsForUInt32(UInt32 u, UInt32 *inOutBits)
{
    // From http://graphics.stanford.edu/~seander/bithacks.html
    register UInt32 result;
    register UInt32 shift;

    result = (u > 0xFFFF) << 4; u >>= result;
    shift  = (u > 0xFF  ) << 3; u >>= shift;  result |= shift;
    shift  = (u > 0xF   ) << 2; u >>= shift;  result |= shift;
    shift  = (u > 0x3   ) << 1; u >>= shift;  result |= shift;
                                              result |= (u >> 1);

    result++;

    if (result > *inOutBits) {
        *inOutBits = result;
    }
}


static void sCalculateBitsForSInt32(SInt32 s, UInt32 *inOutBits)
{
    UInt32 u = (s >= 0) ? s : ~s;
    sCalculateBitsForUInt32(u << 1, inOutBits);
}


void SwiffWriterByteAlign(SwiffWriter *writer)
{
    if (writer->bitPosition != 0) {
        CFDataAppendBytes(writer->data, &writer->bitByte, 1);
        writer->bitByte = 0;
        writer->bitPosition = 0;
    }
}


void SwiffWriterAppendUBits(SwiffWriter *writer, UInt8 numberOfBits, UInt32 value)
{
    for (NSInteger i = (numberOfBits - 1); i >= 0; i--) {
        UInt8 bitToWrite = ((value & (1 << i)) >> i);
        writer->bitByte = (writer->bitByte << 1) | bitToWrite;
        writer->bitPosition++;

        if (writer->bitPosition == 8) {
            SwiffWriterByteAlign(writer);
        }
    }
}


void SwiffWriterAppendSBits(SwiffWriter *writer, UInt8 numberOfBits, SInt32 value)
{
    SwiffWriterAppendUBits(writer, numberOfBits, *((UInt32 *)&value));
}


#pragma mark -
#pragma mark Primitives

extern void SwiffWriterAppendBytes(SwiffWriter *writer, const UInt8 *bytes, UInt32 length)
{
    SwiffWriterByteAlign(writer);
    CFDataAppendBytes(writer->data, bytes, length);
}


void SwiffWriterAppendSInt8(SwiffWriter *writer, SInt8 value)
{
    SwiffWriterByteAlign(writer);
    CFDataAppendBytes(writer->data, (UInt8 *) &value, 1);
}


void SwiffWriterAppendSInt16(SwiffWriter *writer, SInt16 value)
{
    SwiffWriterByteAlign(writer);
    CFDataAppendBytes(writer->data, (UInt8 *) &value, 2);
}


void SwiffWriterAppendSInt32(SwiffWriter *writer, SInt32 value)
{
    SwiffWriterByteAlign(writer);
    CFDataAppendBytes(writer->data, (UInt8 *) &value, 4);
}


extern void SwiffWriterAppendUInt8(SwiffWriter *writer, UInt8 value)
{
    SwiffWriterByteAlign(writer);
    CFDataAppendBytes(writer->data, &value, 1);
}


extern void SwiffWriterAppendUInt16(SwiffWriter *writer, UInt16 value)
{
    SwiffWriterByteAlign(writer);
    CFDataAppendBytes(writer->data, (UInt8 *) &value, 2);
}


void SwiffWriterAppendUInt32(SwiffWriter *writer, UInt32 value)
{
    SwiffWriterByteAlign(writer);
    CFDataAppendBytes(writer->data, (UInt8 *) &value, 4);
}


void SwiffWriterAppendFixed8(SwiffWriter *writer, CGFloat value)
{
    SwiffWriterByteAlign(writer);
    SwiffWriterAppendSInt16(writer, (SInt16)(value * 256));
}


#pragma mark -
#pragma mark Structs

void SwiffWriterAppendRect(SwiffWriter *writer, CGRect rect)
{
    SInt32 xMin = lround(CGRectGetMinX(rect) * 20);
    SInt32 xMax = lround(CGRectGetMaxX(rect) * 20);
    SInt32 yMin = lround(CGRectGetMinY(rect) * 20);
    SInt32 yMax = lround(CGRectGetMaxY(rect) * 20);

    UInt32 nBits = 0;
    sCalculateBitsForSInt32(xMin, &nBits);
    sCalculateBitsForSInt32(xMax, &nBits);
    sCalculateBitsForSInt32(yMin, &nBits);
    sCalculateBitsForSInt32(yMax, &nBits);

    SwiffWriterAppendUBits(writer, 5, nBits);
    SwiffWriterAppendSBits(writer, nBits, xMin);
    SwiffWriterAppendSBits(writer, nBits, xMax);
    SwiffWriterAppendSBits(writer, nBits, yMin);
    SwiffWriterAppendSBits(writer, nBits, yMax);
}


#pragma mark -
#pragma mark Objects

void SwiffWriterAppendData(SwiffWriter *writer, NSData *data)
{
    CFDataRef cfData = (__bridge CFDataRef)data;

    SwiffWriterByteAlign(writer);
    CFDataAppendBytes(writer->data, CFDataGetBytePtr(cfData), CFDataGetLength(cfData));
}

