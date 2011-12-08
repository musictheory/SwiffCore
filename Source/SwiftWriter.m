/*
    SwiftWriter.m
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

#import "SwiftWriter.h"

#include <stdlib.h>
#include <stdio.h>
#include <zlib.h>
#include <string.h>


struct _SwiftWriter {
    CFMutableDataRef data;
    UInt8 bitPosition;
    UInt8 bitByte;

    NSInteger frameCount;
    SwiftTag  currentTag;
    CFMutableDataRef baseData;
};


#pragma mark -
#pragma mark Lifecycle

SwiftWriter *SwiftWriterCreate()
{
    SwiftWriter *writer = calloc(1, sizeof(SwiftWriter));
    writer->data = CFDataCreateMutable(NULL, 0);
    
    return writer;
}


void SwiftWriterFree(SwiftWriter *writer)
{
    if (writer->data)     CFRelease(writer->data);
    if (writer->baseData) CFRelease(writer->baseData);

    free(writer);
}


NSData *SwiftWriterGetData(SwiftWriter *writer)
{
    return [[(__bridge NSData *)writer->data retain] autorelease];
}


NSData *SwiftWriterGetDataWithHeader(SwiftWriter *writer, SwiftHeader header)
{
    SwiftWriterByteAlign(writer);

    SwiftWriter *subwriter = SwiftWriterCreate();

    SwiftWriterAppendRect(subwriter,   header.stageRect);
    SwiftWriterAppendFixed8(subwriter, header.frameRate);
    SwiftWriterAppendUInt16(subwriter, writer->frameCount);
    SwiftWriterAppendData(subwriter, (__bridge NSData *)writer->data);

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
            SwiftWarn(@"SwiftWriterGetDataWithHeader(): falling back to uncompressed");

            [result replaceBytesInRange:NSMakeRange(0, 1) withBytes:"F"];
            [result appendData:(__bridge NSData *)subwriter->data];
        }

        [compressedData release];

    } else {
        [result appendData:(__bridge NSData *)subwriter->data];
    }

    SwiftWriterFree(subwriter);
    
    return result;
}


#pragma mark -
#pragma mark Tags

void SwiftWriterStartTag(SwiftWriter *writer, SwiftTag tag, NSInteger version)
{
    if (writer->baseData == NULL) {
        BOOL shouldWarn = NO;
        
        if (version == 2) {
            switch (tag) {
            case SwiftTagDefineBits:         tag = SwiftTagDefineBitsJPEG2;         break;
            case SwiftTagDefineShape:        tag = SwiftTagDefineShape2;            break;
            case SwiftTagPlaceObject:        tag = SwiftTagPlaceObject2;            break;
            case SwiftTagRemoveObject:       tag = SwiftTagRemoveObject2;           break;
            case SwiftTagDefineText:         tag = SwiftTagDefineText2;             break;
            case SwiftTagDefineButton:       tag = SwiftTagDefineButton2;           break;
            case SwiftTagDefineBitsLossless: tag = SwiftTagDefineBitsLossless2;     break;
            case SwiftTagSoundStreamHead:    tag = SwiftTagSoundStreamHead2;        break;
            case SwiftTagDefineFont:         tag = SwiftTagDefineFont2;             break;
            case SwiftTagDefineFontInfo:     tag = SwiftTagDefineFontInfo2;         break;
            case SwiftTagEnableDebugger:     tag = SwiftTagEnableDebugger2;         break;
            case SwiftTagImportAssets:       tag = SwiftTagImportAssets2;           break;
            case SwiftTagDefineMorphShape:   tag = SwiftTagDefineMorphShape2;       break;
            case SwiftTagStartSound:         tag = SwiftTagStartSound2;             break;                                                                   
            default:                         shouldWarn = YES;                      break;
            }
        
        } else if (version == 3) {
            switch (tag) {
            case SwiftTagDefineShape:        tag = SwiftTagDefineShape3;            break;
            case SwiftTagDefineBits:         tag = SwiftTagDefineBitsJPEG3;         break;
            case SwiftTagPlaceObject:        tag = SwiftTagPlaceObject3;            break;
            case SwiftTagDefineFont:         tag = SwiftTagDefineFont3;             break;                                                                   
            default:                         shouldWarn = YES;                      break;
            }

        } else if (version == 4) {
            switch (tag) {
            case SwiftTagDefineShape:        tag = SwiftTagDefineShape4;            break;
            case SwiftTagDefineBits:         tag = SwiftTagDefineBitsJPEG4;         break;
            case SwiftTagDefineFont:         tag = SwiftTagDefineFont4;             break;
            default:                         shouldWarn = YES;                      break;
            }

        } else if (version != 1) {
            version = 1;
            shouldWarn = YES;
        }

        if (shouldWarn == YES) {
            SwiftWarn(@"Unknown version %d for tag %d, defaulting to version 1", version, tag)
        }

        writer->baseData = writer->data;
        writer->data = CFDataCreateMutable(NULL, 0);
        writer->currentTag = tag;
        
        if (tag == SwiftTagShowFrame) {
            writer->frameCount++;
        }

    } else {
        SwiftWarn(@"SwiftWriterStartTag() called without ending previous tag with SwiftWriterEnd()");
    }
}


void SwiftWriterEndTag(SwiftWriter *writer)
{
    if (writer->baseData) {
        SwiftTag  tag     = writer->currentTag;
        CFDataRef tagData = writer->data;

        writer->data = writer->baseData;
        writer->baseData = NULL;
        writer->currentTag = 0;
    
        CFIndex length    = CFDataGetLength(tagData);
        BOOL    needsLong = length >= 63;

        SwiftWriterAppendUInt16(writer, (tag << 6) | (needsLong ? 0x3F : length));

        if (needsLong) {
            SwiftWriterAppendSInt32(writer, length);
        }

        SwiftWriterAppendData(writer, (__bridge NSData *)tagData);
        CFRelease(tagData);

    } else {
        SwiftWarn(@"SwiftWriterEnd() called without previous SwiftWriterStartTag()");
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


void SwiftWriterByteAlign(SwiftWriter *writer)
{
    if (writer->bitPosition != 0) {
        CFDataAppendBytes(writer->data, &writer->bitByte, 1);
        writer->bitByte = 0;
        writer->bitPosition = 0;
    }
}


void SwiftWriterAppendUBits(SwiftWriter *writer, UInt8 numberOfBits, UInt32 value)
{
    for (NSInteger i = (numberOfBits - 1); i >= 0; i--) {
        UInt8 bitToWrite = ((value & (1 << i)) >> i);
        writer->bitByte = (writer->bitByte << 1) | bitToWrite;
        writer->bitPosition++;

        if (writer->bitPosition == 8) {
            SwiftWriterByteAlign(writer);
        }
    }
}


void SwiftWriterAppendSBits(SwiftWriter *writer, UInt8 numberOfBits, SInt32 value)
{
    SwiftWriterAppendUBits(writer, numberOfBits, *((UInt32 *)&value));
}


#pragma mark -
#pragma mark Primitives

extern void SwiftWriterAppendBytes(SwiftWriter *writer, const UInt8 *bytes, UInt32 length)
{
    SwiftWriterByteAlign(writer);
    CFDataAppendBytes(writer->data, bytes, length);
}


void SwiftWriterAppendSInt8(SwiftWriter *writer, SInt8 value)
{
    SwiftWriterByteAlign(writer);
    CFDataAppendBytes(writer->data, (UInt8 *) &value, 1);
}


void SwiftWriterAppendSInt16(SwiftWriter *writer, SInt16 value)
{
    SwiftWriterByteAlign(writer);
    CFDataAppendBytes(writer->data, (UInt8 *) &value, 2);
}


void SwiftWriterAppendSInt32(SwiftWriter *writer, SInt32 value)
{
    SwiftWriterByteAlign(writer);
    CFDataAppendBytes(writer->data, (UInt8 *) &value, 4);
}


extern void SwiftWriterAppendUInt8(SwiftWriter *writer, UInt8 value)
{
    SwiftWriterByteAlign(writer);
    CFDataAppendBytes(writer->data, &value, 1);
}


extern void SwiftWriterAppendUInt16(SwiftWriter *writer, UInt16 value)
{
    SwiftWriterByteAlign(writer);
    CFDataAppendBytes(writer->data, (UInt8 *) &value, 2);
}


void SwiftWriterAppendUInt32(SwiftWriter *writer, UInt32 value)
{
    SwiftWriterByteAlign(writer);
    CFDataAppendBytes(writer->data, (UInt8 *) &value, 4);
}


void SwiftWriterAppendFixed8(SwiftWriter *writer, CGFloat value)
{
    SwiftWriterByteAlign(writer);
    SwiftWriterAppendSInt16(writer, (SInt16)(value * 256));
}


#pragma mark -
#pragma mark Structs

void SwiftWriterAppendRect(SwiftWriter *writer, CGRect rect)
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

    SwiftWriterAppendUBits(writer, 5, nBits);
    SwiftWriterAppendSBits(writer, nBits, xMin);
    SwiftWriterAppendSBits(writer, nBits, xMax);
    SwiftWriterAppendSBits(writer, nBits, yMin);
    SwiftWriterAppendSBits(writer, nBits, yMax);
}


#pragma mark -
#pragma mark Objects

void SwiftWriterAppendData(SwiftWriter *writer, NSData *data)
{
    CFDataRef cfData = (__bridge CFDataRef)data;

    SwiftWriterByteAlign(writer);
    CFDataAppendBytes(writer->data, CFDataGetBytePtr(cfData), CFDataGetLength(cfData));
}

