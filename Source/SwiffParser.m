/*
    SwiffParser.m
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

#import "SwiffParser.h"

#import "SwiffUtils.h"

#include <stdlib.h>
#include <stdio.h>
#include <zlib.h>
#include <string.h>


struct SwiffParser {
    const UInt8  *buffer;
    const UInt8  *end;
    const UInt8  *b;
    const UInt8  *nextTagB;
    
    CFMutableDictionaryRef values;
    NSStringEncoding encoding;

    UInt32        length;

    UInt8         bitPosition;
    UInt8         bitByte;
    UInt8         isValid;
    Boolean       bufferNeedsFree;

    UInt16        currentTag;
    UInt8         currentTagVersion;
};

void SwiffParserEnsureBufferError(SwiffParser *parser);


SwiffParser *SwiffParserCreate(const UInt8 *buffer, UInt32 length)
{
    SwiffParser *parser = calloc(1, sizeof(SwiffParser));

    parser->buffer      = buffer;
    parser->length      = length;
    parser->b           = parser->buffer;
    parser->bitPosition = 0;
    parser->bitByte     = 0;
    parser->isValid     = YES;
    parser->encoding    = NSUTF8StringEncoding;

    return parser;
}


extern void SwiffParserFree(SwiffParser *parser)
{
    if (parser->bufferNeedsFree) {
        free((void *)parser->buffer);
    }
    
    if (parser->values) {
        CFRelease(parser->values);
    }

    free(parser);
}


static BOOL sInflate(const UInt8 *inBuffer, UInt32 inLength, UInt8 *outBuffer, UInt32 outLength)
{
    z_stream stream;
    bzero(&stream, sizeof(z_stream));

    int err;

    stream.next_in   = (Bytef *)inBuffer;
    stream.avail_in  = inLength;
    stream.next_out  = (Bytef *)outBuffer;
    stream.avail_out = outLength;

    err = inflateInit(&stream);
    if (err != Z_OK) {
        return NO;
    }

    err = inflate(&stream, Z_NO_FLUSH);
    if (err != Z_STREAM_END) {
        inflateEnd(&stream);
        return NO;
    }

    inflateEnd(&stream);

    return YES;
}


void SwiffParserEnsureBufferError(SwiffParser *parser)
{
    SwiffWarn(@"Parser", @"SwiffParser %p is no longer valid.  Break on SwiffParserEnsureBufferError to debug.", parser);
}


static BOOL sEnsureBuffer(SwiffParser *parser, int length)
{
    BOOL yn = ((parser->b + length) <= (parser->buffer + parser->length));

    if (!yn) {
        SwiffParserEnsureBufferError(parser);
        parser->isValid = NO;
    }

    return yn;
}


BOOL SwiffParserReadHeader(SwiffParser *parser, SwiffHeader *outHeader)
{
    UInt8  sig1 = 0, sig2 = 0, sig3 = 0, version = 0;
    BOOL   isCompressed   = NO;
    BOOL   didInflateFail = NO;
    UInt32 fileLength     = 0;

    SwiffParserReadUInt8(parser, &sig1);
    SwiffParserReadUInt8(parser, &sig2);
    SwiffParserReadUInt8(parser, &sig3);
    SwiffParserReadUInt8(parser, &version);

    SwiffParserReadUInt32(parser, &fileLength);

    if (sig1 == 'C' && sig2 == 'W' && sig3 == 'S') {
        isCompressed = YES;

        UInt8 *newBuffer = (UInt8 *)malloc(fileLength);

        if (sInflate(parser->b, parser->length - 8, newBuffer, fileLength)) {
            parser->buffer = newBuffer;
            parser->b      = parser->buffer;
            parser->length = fileLength;
            parser->bufferNeedsFree = YES;
        
        } else {
            free(newBuffer);
            didInflateFail = YES;
        }
    }
    
    CGRect stageRect;
    SwiffParserReadRect(parser, &stageRect);
    
    CGFloat frameRate;
    SwiffParserReadFixed8(parser, &frameRate);

    UInt16 frameCount;
    SwiffParserReadUInt16(parser, &frameCount);
    
    if (outHeader) {
        outHeader->version      = version;
        outHeader->isCompressed = isCompressed;
        outHeader->fileLength   = fileLength;
        outHeader->stageRect    = stageRect;
        outHeader->frameRate    = frameRate;
        outHeader->frameCount   = frameCount;
    }
    
    return (sig1 == 'F' || sig1 == 'C') &&
            sig2 == 'W' &&
            sig3 == 'S' &&
           !didInflateFail &&
            SwiffParserIsValid(parser);
}


BOOL SwiffParserIsValid(SwiffParser *parser)
{
    return parser->isValid;
}


void SwiffParserAdvance(SwiffParser *parser, UInt32 length)
{
    if (!sEnsureBuffer(parser, length)) {
        return;
    }

    parser->b += length;
}


const UInt8 *SwiffParserGetCurrentBytePointer(SwiffParser *parser)
{
    return parser->b;
}


void SwiffParserSetStringEncoding(SwiffParser *parser, NSStringEncoding encoding)
{
    parser->encoding = encoding;
}


NSStringEncoding SwiffParserGetStringEncoding(SwiffParser *parser)
{
    return parser->encoding;
}


extern void SwiffParserSetAssociatedValue(SwiffParser *parser, NSString *key, id value)
{
    if (value) {
        if (!parser->values) {
            parser->values = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        }

        CFDictionarySetValue(parser->values, key, value);

    } else {
        if (parser->values) {
            CFDictionaryRemoveValue(parser->values, key);
        }
    }
}


id SwiffParserGetAssociatedValue(SwiffParser *parser, NSString *key)
{
    return parser->values ? CFDictionaryGetValue(parser->values, key) : nil;
}


#pragma mark -
#pragma mark Tags

void SwiffParserAdvanceToNextTag(SwiffParser *parser)
{
    UInt16 tagCodeAndLength;

    if (parser->nextTagB) {
        parser->b = parser->nextTagB;
    }
    
    SwiffParserByteAlign(parser);

    SwiffParserReadUInt16(parser, &tagCodeAndLength);

    SwiffTag  tag     = (tagCodeAndLength >> 6);
    UInt32    length  = (tagCodeAndLength & 0x3F);

    // Long RECORDHEADER
    if (length == 0x3F) {
        SwiffParserReadUInt32(parser, &length);
    }

    SwiffTag  currentTag;
    NSInteger currentTagVersion;
    SwiffTagSplit(tag, &currentTag, &currentTagVersion);

    parser->currentTag = currentTag;
    parser->currentTagVersion = currentTagVersion;

    parser->nextTagB = parser->b + length;
}


UInt32 SwiffParserGetBytesRemainingInCurrentTag(SwiffParser *parser)
{
    return (parser->nextTagB - parser->b);
}


SwiffTag SwiffParserGetCurrentTag(SwiffParser *parser)
{
    return parser->currentTag;
}


NSInteger SwiffParserGetCurrentTagVersion(SwiffParser *parser)
{
    return parser->currentTagVersion;
}


#pragma mark -
#pragma mark Bitfields

void SwiffParserByteAlign(SwiffParser *parser)
{
    parser->bitPosition = 0;
    parser->bitByte     = 0;
}


void SwiffParserReadFBits(SwiffParser *parser, UInt8 numberOfBits, CGFloat *outValue)
{
    SInt32 s = 0;
    SwiffParserReadSBits(parser, numberOfBits, &s);

    if (outValue) {
        *outValue = (s / 65536.0);
    }
}


void SwiffParserReadSBits(SwiffParser *parser, UInt8 numberOfBits, SInt32 *outValue)
{
    UInt32 u = 0;
    SwiffParserReadUBits(parser, numberOfBits, &u);

    if (outValue) {
        // Sign extend using bit-width of length
        UInt32 mask = 1U << (numberOfBits - 1);
        u = u & ((1U << numberOfBits) - 1);
        *outValue = (u ^ mask) - mask;
    }
}


void SwiffParserReadUBits(SwiffParser *parser, UInt8 numberOfBits, UInt32 *outValue)
{
    int i;
    UInt32 value = 0;
    UInt8 bp = parser->bitPosition;

    for (i = 0; i < numberOfBits; i++) {
        if (bp == 0) {
            if (!sEnsureBuffer(parser, 1)) break;
            parser->bitByte = *((UInt8 *)parser->b);
            parser->b++;
        }

        UInt8 bit = ((parser->bitByte >> (7 - bp)) & 0x1);
        value = (value << 1) + bit;

        bp = (bp + 1) % 8;
    }

    parser->bitPosition = bp;

    if (outValue) {
        *outValue = value;
    }
}


#pragma mark -
#pragma mark Primitives

void SwiffParserReadSInt8(SwiffParser *parser, SInt8 *i)
{
    if (!sEnsureBuffer(parser, sizeof(SInt8))) {
        return;
    }

    if (i) *i = *((SInt8 *)parser->b);
    parser->b += sizeof(SInt8);
    SwiffParserByteAlign(parser);
}


void SwiffParserReadSInt16(SwiffParser *parser, SInt16 *i)
{
    if (!sEnsureBuffer(parser, sizeof(SInt16))) {
        return;
    }

    if (i) *i = *((SInt16 *)parser->b);
    parser->b += sizeof(SInt16);
    SwiffParserByteAlign(parser);
}


void SwiffParserReadSInt32(SwiffParser *parser, SInt32 *i)
{
    if (!sEnsureBuffer(parser, sizeof(SInt32))) {
        return;
    }

    if (i) *i = *((SInt32 *)parser->b);
    parser->b += sizeof(SInt32);
    SwiffParserByteAlign(parser);
}


void SwiffParserReadUInt8(SwiffParser *parser, UInt8 *i)
{
    if (!sEnsureBuffer(parser, sizeof(UInt8))) {
        return;
    }

    if (i) *i = *((UInt8 *)parser->b);
    parser->b += sizeof(UInt8);
    SwiffParserByteAlign(parser);
}


void SwiffParserReadUInt16(SwiffParser *parser, UInt16 *i)
{
    if (!sEnsureBuffer(parser, sizeof(UInt16))) {
        return;
    }

    if (i) *i = *((UInt16 *)parser->b);
    parser->b += sizeof(UInt16);
    SwiffParserByteAlign(parser);
}


void SwiffParserReadUInt32(SwiffParser *parser, UInt32 *i)
{
    if (!sEnsureBuffer(parser, sizeof(UInt32))) {
        return;
    }

    if (i) *i = *((UInt32 *)parser->b);
    parser->b += sizeof(UInt32);
    SwiffParserByteAlign(parser);
}


void SwiffParserReadFloat(SwiffParser *parser, float *outValue)
{
    UInt32 i = 0;
    SwiffParserReadUInt32(parser, &i);
    
    if (outValue) {
        *outValue = *((float *)&i);
    }
}


void SwiffParserReadFixed(SwiffParser *parser, CGFloat *outValue)
{
    UInt32 i = 0;
    SwiffParserReadUInt32(parser, &i);
    
    if (outValue) {
        *outValue = (i >> 16) + ((i & 0xffff) / 65535.0);
    }
}


void SwiffParserReadFixed8(SwiffParser *parser, CGFloat *outValue)
{
    UInt16 i = 0;
    SwiffParserReadUInt16(parser, &i);
    
    if (outValue) {
        *outValue = (i >> 8) + ((i & 0xff) / 255.0);
    }
}


void SwiffParserReadEncodedU32(SwiffParser *parser, UInt32 *outValue)
{
    UInt32 result = 0;
    UInt8  byte;

    {
        SwiffParserReadUInt8(parser, &byte);
        result += byte;
    }

    if (result & 0x00000080) {
        SwiffParserReadUInt8(parser, &byte);
        result = (result & 0x0000007f) | (byte << 7);
    }
        
    if (result & 0x00004000) {
        SwiffParserReadUInt8(parser, &byte);
        result = (result & 0x00003fff) | (byte << 14);
    }

    if (result & 0x00200000) {
        SwiffParserReadUInt8(parser, &byte);
        result = (result & 0x001fffff) | (byte << 21);
    }

    if (result & 0x10000000) {
        SwiffParserReadUInt8(parser, &byte);
        result = (result & 0x0fffffff) | (byte << 28);
    }

    if (outValue) {
        *outValue = result;
    }

    SwiffParserByteAlign(parser);
}


#pragma mark -
#pragma mark Structs

void SwiffParserReadRect(SwiffParser *parser, CGRect *outValue)
{
    UInt32 nBits;
    SInt32 minX, maxX, minY, maxY;

    SwiffParserByteAlign(parser);
    
    SwiffParserReadUBits(parser, 5,     &nBits );
    SwiffParserReadSBits(parser, nBits, &(minX));
    SwiffParserReadSBits(parser, nBits, &(maxX));
    SwiffParserReadSBits(parser, nBits, &(minY));
    SwiffParserReadSBits(parser, nBits, &(maxY));
    
    if (outValue) {
        outValue->origin.x    = SwiffGetCGFloatFromTwips(minX);
        outValue->origin.y    = SwiffGetCGFloatFromTwips(minY);
        outValue->size.width  = SwiffGetCGFloatFromTwips(maxX - minX);
        outValue->size.height = SwiffGetCGFloatFromTwips(maxY - minY);
    }

    SwiffParserByteAlign(parser);
}


void SwiffParserReadMatrix(SwiffParser *parser, CGAffineTransform *outMatrix)
{
    UInt32 hasFeature, numberOfBits;

    CGFloat scaleX      = 1.0;
    CGFloat scaleY      = 1.0;
    CGFloat rotateSkew0 = 0.0;
    CGFloat rotateSkew1 = 0.0;
    SInt32  translateX  = 0;
    SInt32  translateY  = 0;

    SwiffParserByteAlign(parser);

    SwiffParserReadUBits(parser, 1, &hasFeature);
    if (hasFeature) {
        SwiffParserReadUBits(parser, 5, &numberOfBits);
        SwiffParserReadFBits(parser, numberOfBits, &scaleX);
        SwiffParserReadFBits(parser, numberOfBits, &scaleY);
    }

    SwiffParserReadUBits(parser, 1, &hasFeature);
    if (hasFeature) {
        SwiffParserReadUBits(parser, 5, &numberOfBits);
        SwiffParserReadFBits(parser, numberOfBits, &rotateSkew0);
        SwiffParserReadFBits(parser, numberOfBits, &rotateSkew1);
    }
    
    SwiffParserReadUBits(parser, 5, &numberOfBits);
    SwiffParserReadSBits(parser, numberOfBits, &translateX);
    SwiffParserReadSBits(parser, numberOfBits, &translateY);

    SwiffParserByteAlign(parser);

    if (outMatrix) {
        outMatrix->a  = scaleX;
        outMatrix->b  = rotateSkew0;
        outMatrix->c  = rotateSkew1;
        outMatrix->d  = scaleY;
        outMatrix->tx = SwiffGetCGFloatFromTwips(translateX);
        outMatrix->ty = SwiffGetCGFloatFromTwips(translateY);
    }
}


void SwiffParserReadColorRGB(SwiffParser *parser, SwiffColor *outValue)
{
    UInt8 r, g, b;

    SwiffParserReadUInt8(parser, &r);
    SwiffParserReadUInt8(parser, &g);
    SwiffParserReadUInt8(parser, &b);

    if (outValue) {
        outValue->red   = r / 255.0;
        outValue->green = g / 255.0;
        outValue->blue  = b / 255.0;
        outValue->alpha = 1.0;
    }
}


void SwiffParserReadColorRGBA(SwiffParser *parser, SwiffColor *outValue)
{
    UInt8 r, g, b, a;

    SwiffParserReadUInt8(parser, &r);
    SwiffParserReadUInt8(parser, &g);
    SwiffParserReadUInt8(parser, &b);
    SwiffParserReadUInt8(parser, &a);

    if (outValue) {
        outValue->red   = r / 255.0;
        outValue->green = g / 255.0;
        outValue->blue  = b / 255.0;
        outValue->alpha = a / 255.0;
    }
}


void SwiffParserReadColorARGB(SwiffParser *parser, SwiffColor *outValue)
{
    UInt8 r, g, b, a;

    SwiffParserReadUInt8(parser, &a);
    SwiffParserReadUInt8(parser, &r);
    SwiffParserReadUInt8(parser, &g);
    SwiffParserReadUInt8(parser, &b);

    if (outValue) {
        outValue->red   = r / 255.0;
        outValue->green = g / 255.0;
        outValue->blue  = b / 255.0;
        outValue->alpha = a / 255.0;
    }
}


static void sSWFParserReadColorTransform(SwiffParser *parser, SwiffColorTransform *transform, BOOL hasAlpha)
{
    UInt32 hasAddTerms, hasMultTerms, nBits;

    transform->redMultiply   = 1.0;
    transform->greenMultiply = 1.0;
    transform->blueMultiply  = 1.0;
    transform->alphaMultiply = 1.0;

    transform->redAdd   = 0;
    transform->greenAdd = 0;
    transform->blueAdd  = 0;
    transform->alphaAdd = 0;

    SwiffParserByteAlign(parser);

    SwiffParserReadUBits(parser, 1, &hasAddTerms);
    SwiffParserReadUBits(parser, 1, &hasMultTerms);
    SwiffParserReadUBits(parser, 4, &nBits);

    if (hasMultTerms) {
        SInt32 r, g, b, a;

        SwiffParserReadSBits(parser, nBits, &r);
        SwiffParserReadSBits(parser, nBits, &g);
        SwiffParserReadSBits(parser, nBits, &b);
        if (hasAlpha) SwiffParserReadSBits(parser, nBits, &a);
        
        static const CGFloat sMultiplyDivisor = 256;
        transform->redMultiply   = (r / sMultiplyDivisor);
        transform->greenMultiply = (g / sMultiplyDivisor);
        transform->blueMultiply  = (b / sMultiplyDivisor);
        if (hasAlpha) transform->alphaMultiply = (a / sMultiplyDivisor);
    }

    if (hasAddTerms) {
        SInt32 r, g, b, a;

        SwiffParserReadSBits(parser, nBits, &r);
        SwiffParserReadSBits(parser, nBits, &g);
        SwiffParserReadSBits(parser, nBits, &b);
        if (hasAlpha) SwiffParserReadSBits(parser, nBits, &a);

        static const CGFloat sAddDivisor = 255;
        transform->redAdd   = (r / sAddDivisor);
        transform->greenAdd = (g / sAddDivisor);
        transform->blueAdd  = (b / sAddDivisor);
        if (hasAlpha) transform->alphaAdd = (a / sAddDivisor);
    }

    SwiffParserByteAlign(parser);

}


void SwiffParserReadColorTransform(SwiffParser *parser, SwiffColorTransform *transform)
{
    return sSWFParserReadColorTransform(parser, transform, NO);
}


void SwiffParserReadColorTransformWithAlpha(SwiffParser *parser, SwiffColorTransform *transform)
{
    return sSWFParserReadColorTransform(parser, transform, YES);
}


#pragma mark -
#pragma mark Objects

void SwiffParserReadData(SwiffParser *parser, UInt32 length, NSData **outValue)
{
    if (!sEnsureBuffer(parser, length)) {
        return;
    }

    if (outValue) {
        *outValue = [[[NSData alloc] initWithBytes:parser->b length:length] autorelease];
    }

    SwiffParserAdvance(parser, length);
}


void SwiffParserReadString(SwiffParser *parser, NSString **outValue)
{
    UInt8 i;
    const UInt8 *start = parser->b;
    
    do {
        SwiffParserReadUInt8(parser, &i);
    } while (i != 0);
    
    UInt32 length = (parser->b - start);
    if (outValue) {
        if (length) {
            length--;
            *outValue = [[[NSString alloc] initWithBytes:start length:length encoding:parser->encoding] autorelease];
        } else {
            *outValue = nil;
        }
    }
}


void SwiffParserReadLengthPrefixedString(SwiffParser *parser, NSString **outValue)
{
    UInt8 length;
    SwiffParserReadUInt8(parser, &length);

    if (!sEnsureBuffer(parser, length)) {
        return;
    }

    if (outValue) {
        //!spec: "Note that font name strings in the DefineFontInfo tag are not null-terminated;
        //        instead their length is specified by the FontNameLen field." (page 179)
        //
        // In practice, they are both length-prefixed and null terminated.
        //
        UInt8 lengthToUse = length;
        if (length > 0 && (parser->b[length - 1] == 0)) {
            lengthToUse--;
        }

        *outValue = [[[NSString alloc] initWithBytes:parser->b length:lengthToUse encoding:parser->encoding] autorelease];
    }

    SwiffParserAdvance(parser, length);
}

