//
//  SwiftReader.h
//  TheoryLessons
//
//  Created by Ricci Adams on 2011-10-05.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <CoreFoundation/CoreFoundation.h>
#import <CoreGraphics/CoreGraphics.h>

extern SwiftParser *SwiftParserCreate(const UInt8 *buffer, UInt32 length);
extern void SwiftParserFree(SwiftParser *reader);

extern BOOL SwiftParserIsValid(SwiftParser *parser);

extern BOOL SwiftParserAdvanceToNextTag(SwiftParser *parser);
extern BOOL SwiftParserAdvanceToNextTagInSprite(SwiftParser *parser);

extern SwiftTag  SwiftParserGetCurrentTag(SwiftParser *parser);
extern NSInteger SwiftParserGetCurrentTagVersion(SwiftParser *parser);
extern NSInteger SwiftParserGetMovieVersion(SwiftParser *parser);

extern void SwiftParserByteAlign(SwiftParser *parser);
extern void SwiftParserAdvance(SwiftParser *parser, UInt32 length);

extern UInt32 SwiftParserGetBytesRemainingInCurrentTag(SwiftParser *parser);

extern void SwiftParserReadUBits(SwiftParser *parser, UInt8 numberOfBits, UInt32 *outValue);
extern void SwiftParserReadSBits(SwiftParser *parser, UInt8 numberOfBits, SInt32 *outValue);
extern void SwiftParserReadFBits(SwiftParser *parser, UInt8 numberOfBits, CGFloat *outValue);

extern void SwiftParserReadFixed8(SwiftParser *parser, CGFloat *outValue);

extern void SwiftParserReadUInt8(SwiftParser *parser, UInt8 *outValue);
extern void SwiftParserReadUInt16(SwiftParser *parser, UInt16 *outValue);
extern void SwiftParserReadUInt32(SwiftParser *parser, UInt32 *outValue);

extern void SwiftParserReadSInt8(SwiftParser *parser, SInt8 *outValue);
extern void SwiftParserReadSInt16(SwiftParser *parser, SInt16 *outValue);
extern void SwiftParserReadSInt32(SwiftParser *parser, SInt32 *outValue);

extern void SwiftParserReadEncodedU32(SwiftParser *parser, UInt32 *outValue);

extern void SwiftParserReadMatrix(SwiftParser *parser, CGAffineTransform *outMatrix);
extern void SwiftParserReadRect(SwiftParser *parser, CGRect *outValue);

extern void SwiftParserReadColorRGB(SwiftParser *parser, SwiftColor *outValue);
extern void SwiftParserReadColorRGBA(SwiftParser *parser, SwiftColor *outValue);
extern void SwiftParserReadColorARGB(SwiftParser *parser, SwiftColor *outValue);

extern void SwiftParserReadColorTransform(SwiftParser *parser, SwiftColorTransform *colorTransform);
extern void SwiftParserReadColorTransformWithAlpha(SwiftParser *parser, SwiftColorTransform *colorTransform);

extern void SwiftParserReadString(SwiftParser *parser, NSString **outValue);
extern void SwiftParserReadPascalString(SwiftParser *parser, NSString **outValue);

extern void SwiftParserReadStringWithEncoding(SwiftParser *parser, NSStringEncoding encoding, NSString **outValue);
extern void SwiftParserReadPascalStringWithEncoding(SwiftParser *parser, NSStringEncoding encoding, NSString **outValue);
