//
//  SwiftUtil.m
//  SwiftKick
//
//  Created by Ricci Adams on 2011-10-09.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SwiftUtil.h"
#import <asl.h>


BOOL _SwiftShouldLog = NO;

void SwiftEnableLogging()
{
    _SwiftShouldLog = YES;
}


void _SwiftLog(NSInteger level, NSString *format, ...)
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


extern SwiftColor SwiftColorApplyColorTransform(SwiftColor color, SwiftColorTransform transform)
{
    color.red = (color.red * transform.redMultiply) + transform.redAdd;
    if      (color.red < 0.0) color.red = 0.0;
    else if (color.red > 1.0) color.red = 1.0;
    
    color.green = (color.green * transform.greenMultiply) + transform.greenAdd;
    if      (color.green < 0.0) color.green = 0.0;
    else if (color.green > 1.0) color.green = 1.0;

    color.blue  = (color.blue * transform.blueMultiply)  + transform.blueAdd;
    if      (color.blue < 0.0) color.blue = 0.0;
    else if (color.blue > 1.0) color.blue = 1.0;
    
    color.alpha = (color.alpha * transform.alphaMultiply) + transform.alphaAdd;
    if      (color.alpha < 0.0) color.alpha = 0.0;
    else if (color.alpha > 1.0) color.alpha = 1.0;

    return color;
}
