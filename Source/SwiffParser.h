/*
    SwiffParser.h
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

#import <SwiffImport.h>
#import <SwiffBase.h>


typedef struct SwiffParser SwiffParser;

extern SwiffParser *SwiffParserCreate(const UInt8 *buffer, UInt32 length);
extern void SwiffParserFree(SwiffParser *reader);

extern BOOL SwiffParserReadHeader(SwiffParser *parser, SwiffHeader *outHeader);

extern void SwiffParserAdvance(SwiffParser *parser, UInt32 length);
extern BOOL SwiffParserIsValid(SwiffParser *parser);

// Allow the parser to store key-value pairs at parse time
extern void SwiffParserSetAssociatedValue(SwiffParser *parser, NSString *key, id value);
extern id   SwiffParserGetAssociatedValue(SwiffParser *parser, NSString *key);

extern const UInt8 *SwiffParserGetCurrentBytePointer(SwiffParser *parser);

// The encoding to use for STRINGs, defaults to NSUTF8StringEncoding
extern void SwiffParserSetStringEncoding(SwiffParser *parser, NSStringEncoding encoding);
extern NSStringEncoding SwiffParserGetStringEncoding(SwiffParser *parser);


// Tags
//
extern void SwiffParserAdvanceToNextTag(SwiffParser *parser);
extern UInt32 SwiffParserGetBytesRemainingInCurrentTag(SwiffParser *parser);

extern SwiffTag  SwiffParserGetCurrentTag(SwiffParser *parser);
extern NSInteger SwiffParserGetCurrentTagVersion(SwiffParser *parser);


// Bitfields
//
extern void SwiffParserByteAlign(SwiffParser *parser);

extern void SwiffParserReadFBits(SwiffParser *parser, UInt8 numberOfBits, CGFloat *outValue);
extern void SwiffParserReadSBits(SwiffParser *parser, UInt8 numberOfBits, SInt32 *outValue);
extern void SwiffParserReadUBits(SwiffParser *parser, UInt8 numberOfBits, UInt32 *outValue);


// Primitives
//
extern void SwiffParserReadUInt8(SwiffParser *parser, UInt8 *outValue);
extern void SwiffParserReadUInt16(SwiffParser *parser, UInt16 *outValue);
extern void SwiffParserReadUInt32(SwiffParser *parser, UInt32 *outValue);

extern void SwiffParserReadSInt8(SwiffParser *parser, SInt8 *outValue);
extern void SwiffParserReadSInt16(SwiffParser *parser, SInt16 *outValue);
extern void SwiffParserReadSInt32(SwiffParser *parser, SInt32 *outValue);

extern void SwiffParserReadFloat(SwiffParser *parser, float *outValue);
extern void SwiffParserReadFixed(SwiffParser *parser, CGFloat *outValue);
extern void SwiffParserReadFixed8(SwiffParser *parser, CGFloat *outValue);

extern void SwiffParserReadEncodedU32(SwiffParser *parser, UInt32 *outValue);


// Structs
//
extern void SwiffParserReadRect(SwiffParser *parser, CGRect *outValue);
extern void SwiffParserReadMatrix(SwiffParser *parser, CGAffineTransform *outMatrix);

extern void SwiffParserReadColorRGB(SwiffParser *parser, SwiffColor *outValue);
extern void SwiffParserReadColorRGBA(SwiffParser *parser, SwiffColor *outValue);
extern void SwiffParserReadColorARGB(SwiffParser *parser, SwiffColor *outValue);

extern void SwiffParserReadColorTransform(SwiffParser *parser, SwiffColorTransform *colorTransform);
extern void SwiffParserReadColorTransformWithAlpha(SwiffParser *parser, SwiffColorTransform *colorTransform);


// Objects
//
extern void SwiffParserReadData(SwiffParser *parser, UInt32 length, NSData **outValue);

extern void SwiffParserReadString(SwiffParser *parser, NSString **outValue);
extern void SwiffParserReadLengthPrefixedString(SwiffParser *parser, NSString **outValue);
