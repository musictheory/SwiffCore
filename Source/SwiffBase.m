/*
    SwiffBase.m
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

#import "SwiffBase.h"
#import <asl.h>

static NSStringEncoding sANSIStringEncoding   = NSWindowsCP1252StringEncoding;
static NSStringEncoding sLegacyStringEncoding = NSWindowsCP1252StringEncoding;


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


const SwiffColorTransform SwiffColorTransformIdentity = {
    1.0, 1.0, 1.0, 1.0,
    0.0, 0.0, 0.0, 0.0
};


BOOL _SwiffShouldLog = NO;

void SwiffEnableLogging()
{
    _SwiffShouldLog = YES;
}


void _SwiffLog(NSInteger level, NSString *format, ...)
{
    if (!format) return;

    va_list  v;
    va_start(v, format);

#if TARGET_IPHONE_SIMULATOR
    NSLogv(format, v);
#else
    CFStringRef message = CFStringCreateWithFormatAndArguments(NULL, NULL, (CFStringRef)format, v);
    
    if (message) {
        UniChar *characters = (UniChar *)CFStringGetCharactersPtr((CFStringRef)message);
        CFIndex  length     = CFStringGetLength(message);
        BOOL     needsFree  = NO;

        if (!characters) {
            characters = malloc(sizeof(UniChar) * length);
            
            if (characters) {
                CFStringGetCharacters(message, CFRangeMake(0, length), characters);
                needsFree = YES;
            }
        }

        // Always log to ASL

        asl_log(NULL, NULL, level, "%ls\n", (wchar_t *)characters);

        if (needsFree) {
            free(characters);
        }

        CFRelease(message);
    }
#endif

    va_end(v);
}


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


