/*
    SwiffUtils.h
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
#import <SwiffTypes.h>


#pragma mark -
#pragma mark Global Configuration

// The encoding to use when the specification calls for "ANSI" encoding
// Defaults to NSWindowsCP1252StringEncoding
extern void SwiffSetANSIStringEncoding(NSStringEncoding encoding);
extern NSStringEncoding SwiffGetANSIStringEncoding(void);

// The encoding to used for STRINGs in old (< v5) .swf files
// Defaults to NSWindowsCP1252StringEncoding
extern void SwiffSetLegacyStringEncoding(NSStringEncoding encoding);
extern NSStringEncoding SwiffGetLegacyStringEncoding(void);


#pragma mark -
#pragma mark Platform Helpers

#ifndef UIKIT_EXTERN
#ifndef NSStringFromCGPoint
#define NSStringFromCGPoint(X) NSStringFromPoint(NSPointFromCGPoint(X))
#define NSStringFromCGSize(X)  NSStringFromSize(NSSizeFromCGSize(X))
#define NSStringFromCGRect(X)  NSStringFromRect(NSRectFromCGRect(X))
#endif
#endif


#pragma mark -
#pragma mark Geometry Helpers

#if CGFLOAT_IS_DOUBLE
    #define SwiffTwipsPerPixel 20.0
    static inline CGFLOAT_TYPE SwiffRound(CGFLOAT_TYPE x) { return round(x);  }
    static inline CGFLOAT_TYPE SwiffFloor(CGFLOAT_TYPE x) { return floor(x);  }
    static inline CGFLOAT_TYPE SwiffCeil( CGFLOAT_TYPE x) { return ceil(x);   }

    static inline CGFLOAT_TYPE SwiffGetDistance(CGPoint p1, CGPoint p2) {
        return (CGFloat)sqrt(pow(p2.x - p1.x, 2.0) + pow(p2.y - p1.y, 2.0));
    }

#else
    #define SwiffTwipsPerPixel 20.0f
    static inline CGFLOAT_TYPE SwiffRound(CGFLOAT_TYPE x) { return roundf(x); }
    static inline CGFLOAT_TYPE SwiffFloor(CGFLOAT_TYPE x) { return floorf(x); }
    static inline CGFLOAT_TYPE SwiffCeil( CGFLOAT_TYPE x) { return ceilf(x);  }

    static inline CGFLOAT_TYPE SwiffGetDistance(CGPoint p1, CGPoint p2) {
        return (CGFloat)sqrtf(powf(p2.x - p1.x, 2.0) + powf(p2.y - p1.y, 2.0));
    }
#endif

#define SwiffGetTwipsFromCGFloat(FLOAT) (NSInteger)lroundf((FLOAT) * SwiffTwipsPerPixel)
#define SwiffGetCGFloatFromTwips(TWIPS) ((TWIPS) / SwiffTwipsPerPixel)

static inline CGFLOAT_TYPE SwiffScaleRound(CGFLOAT_TYPE x, CGFLOAT_TYPE scaleFactor) { return SwiffRound(x * scaleFactor) / scaleFactor; }
static inline CGFLOAT_TYPE SwiffScaleFloor(CGFLOAT_TYPE x, CGFLOAT_TYPE scaleFactor) { return SwiffFloor(x * scaleFactor) / scaleFactor; }
static inline CGFLOAT_TYPE SwiffScaleCeil( CGFLOAT_TYPE x, CGFLOAT_TYPE scaleFactor) { return SwiffCeil( x * scaleFactor) / scaleFactor; }


#pragma mark -
#pragma mark Logging

extern NSInteger _SwiffLogEnabledCategoryCount;
extern void (*_SwiffLogFunction)(NSString *format, ...);
extern void _SwiffLog(NSString *category, NSInteger level, NSString *format, ...) NS_FORMAT_FUNCTION(3,4);

extern void SwiffLogSetCategoryEnabled(NSString *category, BOOL enabled);
extern BOOL SwiffLogIsCategoryEnabled(NSString *category);

#define SwiffShouldLog(category) ((_SwiffLogEnabledCategoryCount > 0) && SwiffLogIsCategoryEnabled(category))
#define SwiffLog(category, ...)  { if (SwiffShouldLog(category)) _SwiffLog(category, 6, __VA_ARGS__); }
#define SwiffWarn(category, ...) { _SwiffLog(category, 4, __VA_ARGS__); }


#pragma mark -
#pragma mark Colors

extern SwiffColor SwiffColorFromCGColor(CGColorRef cgColor);
extern CGColorRef SwiffColorCopyCGColor(SwiffColor color) CF_RETURNS_RETAINED;

extern NSString *SwiffStringFromColor(SwiffColor color);

extern SwiffColor SwiffColorApplyColorTransform(SwiffColor color, const SwiffColorTransform *transform);

extern BOOL SwiffColorTransformIsIdentity(const SwiffColorTransform *transform);
extern BOOL SwiffColorTransformEqualToTransform(const SwiffColorTransform *a, const SwiffColorTransform *b);

// CFArrayRef values must be valid (SwiffColorTransform *).  If stack is NULL, color is returned
extern SwiffColor SwiffColorApplyColorTransformStack(SwiffColor color, CFArrayRef stack);

extern NSString *SwiffStringFromColorTransform(const SwiffColorTransform *transform);
extern NSString *SwiffStringFromColorTransformStack(CFArrayRef stack);


#pragma mark -
#pragma mark Tags

extern BOOL SwiffTagSplit(SwiffTag inTag, SwiffTag *outTag, NSInteger *outVersion);
extern BOOL SwiffTagJoin(SwiffTag inTag, NSInteger inVersion, SwiffTag *outTag);


#pragma mark -
#pragma mark Sparse Array

extern void  SwiffSparseArrayFree(SwiffSparseArray *array);
extern void  SwiffSparseArrayEnumerateValues(SwiffSparseArray *array, void (^)(void *value));
extern void  SwiffSparseArraySetConsumedObjectAtIndex(SwiffSparseArray *array, UInt16 index, id object CF_CONSUMED);
extern void  SwiffSparseArraySetValueAtIndex(SwiffSparseArray *array, UInt16 index, void *object);
extern void *SwiffSparseArrayGetValueAtIndex(SwiffSparseArray *array, UInt16 index);


#pragma mark -
#pragma mark MPEG

SwiffMPEGError SwiffMPEGReadHeader(const UInt8 *inBuffer, SwiffMPEGHeader *outHeader);

extern UInt32 SwiffMPEGGetBitrate(SwiffMPEGVersion version, SwiffMPEGLayer layer, UInt8 bitrateIndex);
extern UInt32 SwiffMPEGGetSamplesPerFrame(SwiffMPEGVersion version, SwiffMPEGLayer layer);
extern UInt16 SwiffMPEGGetSamplingRate(SwiffMPEGVersion version, UInt8 rateIndex);

extern NSInteger SwiffMPEGGetCoefficients(SwiffMPEGVersion version, SwiffMPEGLayer layer);
extern NSInteger SwiffMPEGGetSlotSize(SwiffMPEGLayer layer);

extern UInt32 SwiffMPEGGetFrameSize(SwiffMPEGVersion version, SwiffMPEGLayer layer, NSInteger bitrate, NSInteger samplingRate, BOOL hasPadding);

