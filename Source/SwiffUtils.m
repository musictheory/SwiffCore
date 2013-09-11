/*
    SwiffUtils.m
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

#import "SwiffUtils.h"
#import <asl.h>


#pragma mark -
#pragma mark Global Configuration

static NSStringEncoding sANSIStringEncoding   = NSWindowsCP1252StringEncoding;
static NSStringEncoding sLegacyStringEncoding = NSWindowsCP1252StringEncoding;


NSStringEncoding SwiffGetANSIStringEncoding(void)
{
    return sANSIStringEncoding;
}


void SwiffSetANSIStringEncoding(NSStringEncoding encoding)
{
    sANSIStringEncoding = encoding;
}


extern NSStringEncoding SwiffGetLegacyStringEncoding(void)
{
    return sLegacyStringEncoding;
}


void SwiffSetLegacyStringEncoding(NSStringEncoding encoding)
{
    sLegacyStringEncoding = encoding;
}


#pragma mark -
#pragma mark Logging

NSInteger _SwiffLogEnabledCategoryCount = 0;
static NSMutableArray  *sSwiffLogEnabledCategories = nil;
void (*_SwiffLogFunction)(NSString *format, ...) = NSLog;


void _SwiffLog(NSString *category, NSInteger level, NSString *format, ...)
{
    if (!format) return;

    va_list  v;
    va_start(v, format);

    CFMutableStringRef message = CFStringCreateMutable(NULL, 0);
    
    if (message) {
        CFStringAppendFormat(message, NULL, CFSTR("[%@]: "), category);
        CFStringAppendFormatAndArguments(message, NULL, (__bridge CFStringRef)format, v);

        _SwiffLogFunction(@"%@", message);

        CFRelease(message);
    }

    va_end(v);
}


void SwiffLogSetCategoryEnabled(NSString *category, BOOL newEnabled)
{
    BOOL isEnabled = SwiffLogIsCategoryEnabled(category);
    
    if (isEnabled != newEnabled) {
        if (newEnabled) {
            if (!sSwiffLogEnabledCategories) sSwiffLogEnabledCategories = [[NSMutableArray alloc] init];
            [sSwiffLogEnabledCategories addObject:category];
        } else {
            [sSwiffLogEnabledCategories removeObject:category];
        }
    }

    _SwiffLogEnabledCategoryCount = [sSwiffLogEnabledCategories count];
}


BOOL SwiffLogIsCategoryEnabled(NSString *category)
{
    return [sSwiffLogEnabledCategories containsObject:category];
}


#pragma mark -
#pragma mark Colors

static void sSwiffColorApplyColorTransformPointer(SwiffColor *color, const SwiffColorTransform *transform)
{
    if (!transform) return;

    color->red = (color->red * transform->redMultiply) + transform->redAdd;
    if      (color->red < 0.0) color->red = 0.0;
    else if (color->red > 1.0) color->red = 1.0;
    
    color->green = (color->green * transform->greenMultiply) + transform->greenAdd;
    if      (color->green < 0.0) color->green = 0.0;
    else if (color->green > 1.0) color->green = 1.0;

    color->blue  = (color->blue * transform->blueMultiply)  + transform->blueAdd;
    if      (color->blue < 0.0) color->blue = 0.0;
    else if (color->blue > 1.0) color->blue = 1.0;
    
    color->alpha = (color->alpha * transform->alphaMultiply) + transform->alphaAdd;
    if      (color->alpha < 0.0) color->alpha = 0.0;
    else if (color->alpha > 1.0) color->alpha = 1.0;
}


SwiffColor SwiffColorFromCGColor(CGColorRef cgColor)
{
    SwiffColor result = { 0, 0, 0, 0 };

    CGColorSpaceRef   space       = cgColor ? CGColorGetColorSpace(cgColor) : NULL;
    const CGFloat    *components  = cgColor ? CGColorGetComponents(cgColor) : NULL;
    size_t            n           = cgColor ? CGColorGetNumberOfComponents(cgColor) : 0;
    CGColorSpaceModel model       = space   ? CGColorSpaceGetModel(space)   : kCGColorSpaceModelUnknown;

    if (model == kCGColorSpaceModelMonochrome) {
        result.red   = 
        result.green = 
        result.blue  = (n > 0) ? components[0] : 0.0;
        result.alpha = (n > 1) ? components[1] : 1.0;

    } else if (model == kCGColorSpaceModelRGB) {
        result.red   = (n > 0) ? components[0] : 0.0;
        result.green = (n > 1) ? components[1] : 0.0;
        result.blue  = (n > 2) ? components[2] : 0.0;
        result.alpha = (n > 3) ? components[3] : 1.0;
    }
    
    return result;
}


CGColorRef SwiffColorCopyCGColor(SwiffColor color)
{
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    CGColorRef result = CGColorCreate(space, (CGFloat *)&color);
    CGColorSpaceRelease(space);

    return result;
}


NSString *SwiffStringFromColor(SwiffColor color)
{
    NSString *alphaString = @"";
    
    if (color.alpha != 1.0) {
        alphaString = [NSString stringWithFormat:@", alpha=%.02lf", color.alpha];
    }
    
    return [NSString stringWithFormat:@"#%02lX%02lX%02lX%@",
        (long)(color.red   * 255),
        (long)(color.green * 255),
        (long)(color.blue  * 255),
        alphaString];
}


SwiffColor SwiffColorApplyColorTransform(SwiffColor color, const SwiffColorTransform *transform)
{
    sSwiffColorApplyColorTransformPointer(&color, transform);
    return color;
}


SwiffColor SwiffColorApplyColorTransformStack(SwiffColor color, CFArrayRef stack)
{
    if (!stack) return color;
    for (CFIndex i = 0, count = CFArrayGetCount(stack); i < count; i++) {
        SwiffColorTransform *transformPtr = (SwiffColorTransform *)CFArrayGetValueAtIndex(stack, i);
        sSwiffColorApplyColorTransformPointer(&color, transformPtr);
    }
    
    return color;
}


BOOL SwiffColorTransformEqualToTransform(const SwiffColorTransform *a, const SwiffColorTransform *b)
{
    if (a && b) {
        return (0 == memcmp(a, b, sizeof(SwiffColorTransform)));
    } else if (!a && !b) {
        return YES;
    } else {
        return NO;
    }
}


BOOL SwiffColorTransformIsIdentity(const SwiffColorTransform *transform)
{
    if (!transform) return YES;
    return (0 == memcmp(transform, &SwiffColorTransformIdentity, sizeof(SwiffColorTransform)));
}


NSString *SwiffStringFromColorTransform(const SwiffColorTransform *transform)
{
    return [NSString stringWithFormat:@"(r * %.02f) + %.02f, (g * %.02f) + %.02f, (b * %.02f) + %.02f, (a * %.02f) + %.02f",
        (float)transform->redMultiply,   (float)transform->redAdd,
        (float)transform->greenMultiply, (float)transform->greenAdd,
        (float)transform->blueMultiply,  (float)transform->blueAdd,
        (float)transform->alphaMultiply, (float)transform->alphaAdd];
}


NSString *SwiffStringFromColorTransformStack(CFArrayRef stack)
{
    if (!stack) return @"[ ]";

    NSMutableString *result = [NSMutableString string];

    [result appendString:@"[\n"];

    CFIndex count = CFArrayGetCount(stack);
    CFIndex lastI = (count - 1);
    for (CFIndex i = 0; i < count; i++) {
        SwiffColorTransform *transformPtr = (SwiffColorTransform *)CFArrayGetValueAtIndex(stack, i);
        NSString *string = SwiffStringFromColorTransform(transformPtr);
        [result appendFormat:@"    %@%@\n", string, (i == lastI) ? @"" : @","];
    }

    [result appendString:@"]"];
    
    return result;
}


#pragma mark -
#pragma mark Tags

static NSInteger const sTagMap[] = {
    SwiffTagDefineBitsJPEG2,       SwiffTagDefineBits,           2,
    SwiffTagDefineShape2,          SwiffTagDefineShape,          2,
    SwiffTagPlaceObject2,          SwiffTagPlaceObject,          2,
    SwiffTagRemoveObject2,         SwiffTagRemoveObject,         2,
    SwiffTagDefineText2,           SwiffTagDefineText,           2,
    SwiffTagDefineButton2,         SwiffTagDefineButton,         2,
    SwiffTagDefineBitsLossless2,   SwiffTagDefineBitsLossless,   2,
    SwiffTagSoundStreamHead2,      SwiffTagSoundStreamHead,      2,
    SwiffTagDefineFont2,           SwiffTagDefineFont,           2,
    SwiffTagDefineFontInfo2,       SwiffTagDefineFontInfo,       2,
    SwiffTagEnableDebugger2,       SwiffTagEnableDebugger,       2,
    SwiffTagImportAssets2,         SwiffTagImportAssets,         2,
    SwiffTagDefineMorphShape2,     SwiffTagDefineMorphShape,     2,
    SwiffTagStartSound2,           SwiffTagStartSound,           2,
    SwiffTagDefineShape3,          SwiffTagDefineShape,          3,
    SwiffTagDefineBitsJPEG3,       SwiffTagDefineBits,           3,
    SwiffTagPlaceObject3,          SwiffTagPlaceObject,          3,
    SwiffTagDefineFont3,           SwiffTagDefineFont,           3,
    SwiffTagDefineShape4,          SwiffTagDefineShape,          4,
    SwiffTagDefineBitsJPEG4,       SwiffTagDefineBits,           4,
    SwiffTagDefineFont4,           SwiffTagDefineFont,           4,
    0, 0, 0
};


BOOL SwiffTagSplit(SwiffTag inTag, SwiffTag *outTag, NSInteger *outVersion)
{
    NSInteger i         = 0;
    SwiffTag  mappedTag = inTag;
    NSInteger version   = 1;
    BOOL      yn        = NO;

    SwiffTag currentTag;
    while ((currentTag = sTagMap[i])) {
        if (inTag == currentTag) {
            mappedTag = sTagMap[i + 1];
            version   = sTagMap[i + 2];
            yn        = YES;
            break;
        }

        i += 3;
    }

    if (outTag)     *outTag     = mappedTag;
    if (outVersion) *outVersion = version;

    return yn;
}


BOOL SwiffTagJoin(SwiffTag inTag, NSInteger inVersion, SwiffTag *outTag)
{
    NSInteger i         = 0;
    SwiffTag  mappedTag = inTag;
    BOOL      yn        = NO;

    SwiffTag  currentTag;
    NSInteger currentVersion;
    while ((currentTag = sTagMap[i + 1]) && (currentVersion = sTagMap[i + 2])) {
        if ((inTag == currentTag) && (inVersion == currentVersion)) {
            mappedTag = sTagMap[i];
            yn        = YES;
            break;
        }

        i += 3;
    }

    if (outTag) *outTag = mappedTag;

    return yn;
}


#pragma mark -
#pragma mark MPEG

SwiffMPEGError SwiffMPEGReadHeader(const UInt8 *buffer, SwiffMPEGHeader *header)
{
    UInt16 frameSync    = 0;
    UInt8  bitrateIndex = 0;
    UInt8  rateIndex    = 0;

    UInt32 i = ntohl(*((UInt32 *)buffer));
 
    frameSync             = ((i >> 21) & 0x7FF);
    header->version       = ((i >> 19) & 0x3);
    header->layer         = ((i >> 17) & 0x3);
    header->hasCRC        = ((i >> 16) & 0x1) ? NO : YES;
    bitrateIndex          = ((i >> 12) & 0xf);
    rateIndex             = ((i >> 10) & 0x3);
    header->hasPadding    = ((i >>  9) & 0x1);
/*  UInt8 reserved        = ((i >>  8) & 0x1); */
    header->channelMode   = ((i >>  6) & 0x3);
    header->modeExtension = ((i >>  4) & 0x3);
    header->hasCopyright  = ((i >>  3) & 0x1);
    header->isOriginal    = ((i >>  2) & 0x1);
    header->emphasis      = ((i      ) & 0x3);

    header->samplingRate  = SwiffMPEGGetSamplingRate(header->version, rateIndex);
    header->bitrate       = SwiffMPEGGetBitrate(header->version, header->layer, bitrateIndex);
    header->frameSize     = SwiffMPEGGetFrameSize(header->version, header->layer, header->bitrate, header->samplingRate, header->hasPadding);

    SwiffMPEGError error = SwiffMPEGErrorNone;

    // Check for errors
    if (frameSync != 0x7FF) {
        error = SwiffMPEGErrorInvalidFrameSync;
    } else if (bitrateIndex == 15) {
        error = SwiffMPEGErrorBadBitrate;
    }
    
    // Check for reserved values
    if (error == SwiffMPEGErrorNone) {
        if      (header->version  == 1) { error = SwiffMPEGErrorReservedVersion;      }
        else if (header->layer    == 0) { error = SwiffMPEGErrorReservedLayer;        }
        else if (rateIndex        == 3) { error = SwiffMPEGErrorReservedSamplingRate; }
        else if (header->emphasis == 2) { error = SwiffMPEGErrorReservedEmphasis;     }
    }   

    return error;
}


UInt32 SwiffMPEGGetBitrate(SwiffMPEGVersion version, SwiffMPEGLayer layer, UInt8 bitrateIndex)
{
    BOOL isVersion2x = (version == SwiffMPEGVersion2) || (version == SwiffMPEGVersion25);

    const UInt32 map[2][4][16] = {
        {
            {   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0 },  // Layer bit reserved
            {   0,  32,  40,  48,  56,  64,  80,  96, 112, 128, 160, 192, 224, 256, 320,   0 },  // MPEG1, Layer 3
            {   0,  32,  48,  56,  64,  80,  96, 112, 128, 160, 192, 224, 256, 320, 384,   0 },  // MPEG1, Layer 2
            {   0,  32,  64,  96, 128, 160, 192, 224, 256, 288, 320, 352, 384, 416, 448,   0 }   // MPEG1, Layer 1
        },{ 
            {   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0 },  // Layer bit reserved
            {   0,   8,  16,  24,  32,  40,  48,  56,  64,  80,  96, 112, 128, 144, 160,   0 },  // MPEG2x, Layer 3
            {   0,   8,  16,  24,  32,  40,  48,  56,  64,  80,  96, 112, 128, 144, 160,   0 },  // MPEG2x, Layer 2
            {   0,  32,  48,  56,  64,  80,  96, 112, 128, 144, 160, 176, 192, 224, 256,   0 }   // MPEG2x, Layer 1
        }
    };

    return map[isVersion2x ? 1 : 0][layer % 4][bitrateIndex % 16] * 1000;
}


UInt32 SwiffMPEGGetSamplesPerFrame(SwiffMPEGVersion version, SwiffMPEGLayer layer)
{
    static const UInt32 map[2][4] = {
        {   0, 1152, 1152, 384 },  // MPEG 1
        {   0,  576, 1152, 384 }   // MPEG 2, MPEG 2.5
    };

    BOOL isVersion2x = (version == SwiffMPEGVersion2) || (version == SwiffMPEGVersion25);
    return map[isVersion2x ? 1 : 0][layer % 4];
}


UInt16 SwiffMPEGGetSamplingRate(SwiffMPEGVersion version, UInt8 rateIndex)
{
    static const UInt16 map[4][3] = {
        { 11025, 12000,  8000 },  // MPEG 2.5
        {     0,     0,     0 },  // reserved
        { 22050, 24000, 16000 },  // MPEG 2
        { 44100, 48000, 32000 }   // MPEG 1
    };

    return map[version % 4][rateIndex % 3];
}


extern UInt32 SwiffMPEGGetCoefficients(SwiffMPEGVersion version, SwiffMPEGLayer layer)
{
    static const UInt32 map[2][4] = {
        {   0, 144, 144,  12 },  // MPEG 1
        {   0,  72, 144,  12 }   // MPEG 2, MPEG 2.5
    };

    BOOL isVersion2x = (version == SwiffMPEGVersion2) || (version == SwiffMPEGVersion25);
    return map[isVersion2x ? 1 : 0][layer % 4];
}


extern UInt32 SwiffMPEGGetSlotSize(SwiffMPEGLayer layer)
{
    static const UInt32 map[4] = { 0, 1, 1, 4 };
    return map[layer % 4];
}


extern UInt32 SwiffMPEGGetFrameSize(SwiffMPEGVersion version, SwiffMPEGLayer layer, NSInteger bitrate, NSInteger samplingRate, BOOL hasPadding)
{
    UInt32 coefficients = SwiffMPEGGetCoefficients(version, layer);
    UInt32 slotSize     = SwiffMPEGGetSlotSize(layer);

    if (samplingRate) {
        return (UInt32)(((coefficients * bitrate / samplingRate) + (hasPadding ? 1 : 0))) * slotSize;
    } else {
        return 0;
    }
}
