/*
    SwiftParser.m
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

#import "SwiftParser.h"

#include <stdlib.h>
#include <stdio.h>
#include <zlib.h>
#include <string.h>


struct _SwiftParser {
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

void _SwiftParserEnsureBufferError(SwiftParser *parser);


SwiftParser *SwiftParserCreate(const UInt8 *buffer, UInt32 length)
{
    SwiftParser *parser = calloc(1, sizeof(SwiftParser));

    parser->buffer      = buffer;
    parser->length      = length;
    parser->b           = parser->buffer;
    parser->bitPosition = 0;
    parser->bitByte     = 0;
    parser->isValid     = YES;
    parser->encoding    = NSUTF8StringEncoding;

    return parser;
}


extern void SwiftParserFree(SwiftParser *parser)
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


void _SwiftParserEnsureBufferError(SwiftParser *parser)
{
    SwiftWarn(@"SwiftParser %p is no longer valid.  Break on _SwiftParserEnsureBufferError to debug.", parser);
}


static BOOL sEnsureBuffer(SwiftParser *parser, int length)
{
    BOOL yn = ((parser->b + length) <= (parser->buffer + parser->length));

    if (!yn) {
        _SwiftParserEnsureBufferError(parser);
        parser->isValid = NO;
    }

    return yn;
}


BOOL SwiftParserReadHeader(SwiftParser *parser, SwiftHeader *outHeader)
{
    UInt8  sig1 = 0, sig2 = 0, sig3 = 0, version = 0;
    BOOL   isCompressed   = NO;
    BOOL   didInflateFail = NO;
    UInt32 fileLength     = 0;

    SwiftParserReadUInt8(parser, &sig1);
    SwiftParserReadUInt8(parser, &sig2);
    SwiftParserReadUInt8(parser, &sig3);
    SwiftParserReadUInt8(parser, &version);

    SwiftParserReadUInt32(parser, &fileLength);

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
    SwiftParserReadRect(parser, &stageRect);
    
    CGFloat frameRate;
    SwiftParserReadFixed8(parser, &frameRate);

    UInt16 frameCount;
    SwiftParserReadUInt16(parser, &frameCount);
    
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
            SwiftParserIsValid(parser);
}


BOOL SwiftParserIsValid(SwiftParser *parser)
{
    return parser->isValid;
}


void SwiftParserAdvance(SwiftParser *parser, UInt32 length)
{
    if (!sEnsureBuffer(parser, length)) {
        return;
    }

    parser->b += length;
}


const UInt8 *SwiftParserGetCurrentBytePointer(SwiftParser *parser)
{
    return parser->b;
}


void SwiftParserSetStringEncoding(SwiftParser *parser, NSStringEncoding encoding)
{
    parser->encoding = encoding;
}


NSStringEncoding SwiftParserGetStringEncoding(SwiftParser *parser)
{
    return parser->encoding;
}


extern void SwiftParserSetAssociatedValue(SwiftParser *parser, NSString *key, id value)
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


id SwiftParserGetAssociatedValue(SwiftParser *parser, NSString *key)
{
    return parser->values ? CFDictionaryGetValue(parser->values, key) : nil;
}


#pragma mark -
#pragma mark Tags

void SwiftParserAdvanceToNextTag(SwiftParser *parser)
{
    UInt16 tagCodeAndLength;

    if (parser->nextTagB) {
        parser->b = parser->nextTagB;
    }
    
    SwiftParserByteAlign(parser);

    SwiftParserReadUInt16(parser, &tagCodeAndLength);

    SwiftTag  tag     = (tagCodeAndLength >> 6);
    UInt32    length  = (tagCodeAndLength & 0x3F);

    // Long RECORDHEADER
    if (length == 0x3F) {
        SwiftParserReadUInt32(parser, &length);
    }

    SwiftTag  currentTag;
    NSInteger currentTagVersion;
    SwiftTagSplit(tag, &currentTag, &currentTagVersion);

    parser->currentTag = currentTag;
    parser->currentTagVersion = currentTagVersion;

    parser->nextTagB = parser->b + length;
}


UInt32 SwiftParserGetBytesRemainingInCurrentTag(SwiftParser *parser)
{
    return (parser->nextTagB - parser->b);
}


SwiftTag SwiftParserGetCurrentTag(SwiftParser *parser)
{
    return parser->currentTag;
}


NSInteger SwiftParserGetCurrentTagVersion(SwiftParser *parser)
{
    return parser->currentTagVersion;
}


#pragma mark -
#pragma mark Bitfields

void SwiftParserByteAlign(SwiftParser *parser)
{
    parser->bitPosition = 0;
    parser->bitByte     = 0;
}


void SwiftParserReadFBits(SwiftParser *parser, UInt8 numberOfBits, CGFloat *outValue)
{
    SInt32 s = 0;
    SwiftParserReadSBits(parser, numberOfBits, &s);

    if (outValue) {
        *outValue = (s / 65536.0);
    }
}


void SwiftParserReadSBits(SwiftParser *parser, UInt8 numberOfBits, SInt32 *outValue)
{
    UInt32 u = 0;
    SwiftParserReadUBits(parser, numberOfBits, &u);

    if (outValue) {
        // Sign extend using bit-width of length
        UInt32 mask = 1U << (numberOfBits - 1);
        u = u & ((1U << numberOfBits) - 1);
        *outValue = (u ^ mask) - mask;
    }
}


void SwiftParserReadUBits(SwiftParser *parser, UInt8 numberOfBits, UInt32 *outValue)
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

void SwiftParserReadSInt8(SwiftParser *parser, SInt8 *i)
{
    if (!sEnsureBuffer(parser, sizeof(SInt8))) {
        return;
    }

    if (i) *i = *((SInt8 *)parser->b);
    parser->b += sizeof(SInt8);
    SwiftParserByteAlign(parser);
}


void SwiftParserReadSInt16(SwiftParser *parser, SInt16 *i)
{
    if (!sEnsureBuffer(parser, sizeof(SInt16))) {
        return;
    }

    if (i) *i = *((SInt16 *)parser->b);
    parser->b += sizeof(SInt16);
    SwiftParserByteAlign(parser);
}


void SwiftParserReadSInt32(SwiftParser *parser, SInt32 *i)
{
    if (!sEnsureBuffer(parser, sizeof(SInt32))) {
        return;
    }

    if (i) *i = *((SInt32 *)parser->b);
    parser->b += sizeof(SInt32);
    SwiftParserByteAlign(parser);
}


void SwiftParserReadUInt8(SwiftParser *parser, UInt8 *i)
{
    if (!sEnsureBuffer(parser, sizeof(UInt8))) {
        return;
    }

    if (i) *i = *((UInt8 *)parser->b);
    parser->b += sizeof(UInt8);
    SwiftParserByteAlign(parser);
}


void SwiftParserReadUInt16(SwiftParser *parser, UInt16 *i)
{
    if (!sEnsureBuffer(parser, sizeof(UInt16))) {
        return;
    }

    if (i) *i = *((UInt16 *)parser->b);
    parser->b += sizeof(UInt16);
    SwiftParserByteAlign(parser);
}


void SwiftParserReadUInt32(SwiftParser *parser, UInt32 *i)
{
    if (!sEnsureBuffer(parser, sizeof(UInt32))) {
        return;
    }

    if (i) *i = *((UInt32 *)parser->b);
    parser->b += sizeof(UInt32);
    SwiftParserByteAlign(parser);
}


void SwiftParserReadFixed8(SwiftParser *parser, CGFloat *outValue)
{
    UInt16 i = 0;
    SwiftParserReadUInt16(parser, &i);
    
    if (outValue) {
        *outValue = (i >> 8) + ((i & 0xff) / 255.0);
    }
}


void SwiftParserReadEncodedU32(SwiftParser *parser, UInt32 *outValue)
{
    UInt32 result = 0;
    UInt8  byte;

    {
        SwiftParserReadUInt8(parser, &byte);
        result += byte;
    }

    if (result & 0x00000080) {
        SwiftParserReadUInt8(parser, &byte);
        result = (result & 0x0000007f) | (byte << 7);
    }
        
    if (result & 0x00004000) {
        SwiftParserReadUInt8(parser, &byte);
        result = (result & 0x00003fff) | (byte << 14);
    }

    if (result & 0x00200000) {
        SwiftParserReadUInt8(parser, &byte);
        result = (result & 0x001fffff) | (byte << 21);
    }

    if (result & 0x10000000) {
        SwiftParserReadUInt8(parser, &byte);
        result = (result & 0x0fffffff) | (byte << 28);
    }

    if (outValue) {
        *outValue = result;
    }

    SwiftParserByteAlign(parser);
}


#pragma mark -
#pragma mark Structs

void SwiftParserReadRect(SwiftParser *parser, CGRect *outValue)
{
    UInt32 nBits;
    SInt32 minX, maxX, minY, maxY;

    SwiftParserByteAlign(parser);
    
    SwiftParserReadUBits(parser, 5,     &nBits );
    SwiftParserReadSBits(parser, nBits, &(minX));
    SwiftParserReadSBits(parser, nBits, &(maxX));
    SwiftParserReadSBits(parser, nBits, &(minY));
    SwiftParserReadSBits(parser, nBits, &(maxY));
    
    if (outValue) {
        outValue->origin.x    = SwiftFloatFromTwips(minX);
        outValue->origin.y    = SwiftFloatFromTwips(minY);
        outValue->size.width  = SwiftFloatFromTwips(maxX - minX);
        outValue->size.height = SwiftFloatFromTwips(maxY - minY);
    }

    SwiftParserByteAlign(parser);
}


void SwiftParserReadMatrix(SwiftParser *parser, CGAffineTransform *outMatrix)
{
    UInt32 hasFeature, numberOfBits;

    CGFloat scaleX      = 1.0;
    CGFloat scaleY      = 1.0;
    CGFloat rotateSkew0 = 0.0;
    CGFloat rotateSkew1 = 0.0;
    SInt32  translateX  = 0;
    SInt32  translateY  = 0;

    SwiftParserByteAlign(parser);

    SwiftParserReadUBits(parser, 1, &hasFeature);
    if (hasFeature) {
        SwiftParserReadUBits(parser, 5, &numberOfBits);
        SwiftParserReadFBits(parser, numberOfBits, &scaleX);
        SwiftParserReadFBits(parser, numberOfBits, &scaleY);
    }

    SwiftParserReadUBits(parser, 1, &hasFeature);
    if (hasFeature) {
        SwiftParserReadUBits(parser, 5, &numberOfBits);
        SwiftParserReadFBits(parser, numberOfBits, &rotateSkew0);
        SwiftParserReadFBits(parser, numberOfBits, &rotateSkew1);
    }
    
    SwiftParserReadUBits(parser, 5, &numberOfBits);
    SwiftParserReadSBits(parser, numberOfBits, &translateX);
    SwiftParserReadSBits(parser, numberOfBits, &translateY);

    SwiftParserByteAlign(parser);

    if (outMatrix) {
        outMatrix->a  = scaleX;
        outMatrix->b  = rotateSkew0;
        outMatrix->c  = rotateSkew1;
        outMatrix->d  = scaleY;
        outMatrix->tx = SwiftFloatFromTwips(translateX);
        outMatrix->ty = SwiftFloatFromTwips(translateY);
    }
}


void SwiftParserReadColorRGB(SwiftParser *parser, SwiftColor *outValue)
{
    UInt8 r, g, b;

    SwiftParserReadUInt8(parser, &r);
    SwiftParserReadUInt8(parser, &g);
    SwiftParserReadUInt8(parser, &b);

    if (outValue) {
        outValue->red   = r / 255.0;
        outValue->green = g / 255.0;
        outValue->blue  = b / 255.0;
        outValue->alpha = 1.0;
    }
}


void SwiftParserReadColorRGBA(SwiftParser *parser, SwiftColor *outValue)
{
    UInt8 r, g, b, a;

    SwiftParserReadUInt8(parser, &r);
    SwiftParserReadUInt8(parser, &g);
    SwiftParserReadUInt8(parser, &b);
    SwiftParserReadUInt8(parser, &a);

    if (outValue) {
        outValue->red   = r / 255.0;
        outValue->green = g / 255.0;
        outValue->blue  = b / 255.0;
        outValue->alpha = a / 255.0;
    }
}


void SwiftParserReadColorARGB(SwiftParser *parser, SwiftColor *outValue)
{
    UInt8 r, g, b, a;

    SwiftParserReadUInt8(parser, &a);
    SwiftParserReadUInt8(parser, &r);
    SwiftParserReadUInt8(parser, &g);
    SwiftParserReadUInt8(parser, &b);

    if (outValue) {
        outValue->red   = r / 255.0;
        outValue->green = g / 255.0;
        outValue->blue  = b / 255.0;
        outValue->alpha = a / 255.0;
    }
}


static void sSWFParserReadColorTransform(SwiftParser *parser, SwiftColorTransform *transform, BOOL hasAlpha)
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

    SwiftParserByteAlign(parser);

    SwiftParserReadUBits(parser, 1, &hasAddTerms);
    SwiftParserReadUBits(parser, 1, &hasMultTerms);
    SwiftParserReadUBits(parser, 4, &nBits);

    if (hasMultTerms) {
        SInt32 r, g, b, a;

        SwiftParserReadSBits(parser, nBits, &r);
        SwiftParserReadSBits(parser, nBits, &g);
        SwiftParserReadSBits(parser, nBits, &b);
        if (hasAlpha) SwiftParserReadSBits(parser, nBits, &a);
        
        transform->redMultiply   = (r / 255.0);
        transform->greenMultiply = (g / 255.0);
        transform->blueMultiply  = (b / 255.0);
        if (hasAlpha) transform->alphaMultiply = (a / 255.0);
    }

    if (hasAddTerms) {
        SInt32 r, g, b, a;

        SwiftParserReadSBits(parser, nBits, &r);
        SwiftParserReadSBits(parser, nBits, &g);
        SwiftParserReadSBits(parser, nBits, &b);
        if (hasAlpha) SwiftParserReadSBits(parser, nBits, &a);

        transform->redAdd   = (r / 255.0);
        transform->greenAdd = (g / 255.0);
        transform->blueAdd  = (b / 255.0);
        if (hasAlpha) transform->alphaAdd = (a / 255.0);
    }

    SwiftParserByteAlign(parser);

}


void SwiftParserReadColorTransform(SwiftParser *parser, SwiftColorTransform *transform)
{
    return sSWFParserReadColorTransform(parser, transform, NO);
}


void SwiftParserReadColorTransformWithAlpha(SwiftParser *parser, SwiftColorTransform *transform)
{
    return sSWFParserReadColorTransform(parser, transform, YES);
}


#pragma mark -
#pragma mark Objects

void SwiftParserReadData(SwiftParser *parser, UInt32 length, NSData **outValue)
{
    if (!sEnsureBuffer(parser, length)) {
        return;
    }

    if (outValue) {
        *outValue = [[[NSData alloc] initWithBytes:parser->b length:length] autorelease];
    }

    SwiftParserAdvance(parser, length);
}


void SwiftParserReadString(SwiftParser *parser, NSString **outValue)
{
    UInt8 i;
    const UInt8 *start = parser->b;
    
    do {
        SwiftParserReadUInt8(parser, &i);
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


void SwiftParserReadLengthPrefixedString(SwiftParser *parser, NSString **outValue)
{
    UInt8 length;
    SwiftParserReadUInt8(parser, &length);

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

    SwiftParserAdvance(parser, length);
}

