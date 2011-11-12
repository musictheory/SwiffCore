/*
    SwiftPNGExporter.m
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

#import "SwiftPNGExporter.h"

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif

#import "SwiftMovie.h"
#import "SwiftRenderer.h"



@implementation SwiftPNGExporter

+ (id) sharedInstance
{
    static SwiftPNGExporter *sSharedInstance = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sSharedInstance = [[SwiftPNGExporter alloc] init]; 
    });
    
    return sSharedInstance;
}


- (BOOL) exportFrame:(SwiftFrame *)frame ofMovie:(SwiftMovie *)movie toFile:(NSString *)path
{
    NSURL *fileURL = [NSURL fileURLWithPath:path];

    if (fileURL) {
        return [self exportFrame:frame ofMovie:movie toURL:fileURL];
    }
    
    return NO;
}


- (BOOL) exportFrame:(SwiftFrame *)frame ofMovie:(SwiftMovie *)movie toURL:(NSURL *)fileURL
{
    CGSize     stageSize = [movie stageRect].size;
    size_t     width     = stageSize.width;
    size_t     height    = stageSize.height;
    CGImageRef image     = NULL;
    BOOL       success   = NO;

    if (width && height) {
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef    context    = CGBitmapContextCreate(NULL, width, height, 8, width * 4, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);

        [[SwiftRenderer sharedInstance] renderFrame:frame movie:movie context:context];

        image = CGBitmapContextCreateImage(context);

        CGContextRelease(context);
        CGColorSpaceRelease(colorSpace);
    }

    NSData *data = nil;

    if (image) {
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
        UIImage *uiImage = [[UIImage alloc] initWithCGImage:image scale:1 orientation:UIImageOrientationUp];
        data = UIImagePNGRepresentation(uiImage);
        [uiImage release];
#else
        NSBitmapImageRep *nsImageRep = [[NSBitmapImageRep alloc] initWithCGImage:image];
        data = [nsImageRep representationUsingType:NSPNGFileType properties:nil];
        [nsImageRep release];
#endif

        CGImageRelease(image);
    }
    
    if (data) {
        NSError *error = nil;
        success = [data writeToURL:fileURL options:NSDataWritingAtomic error:&error];
    }

    return success;
}


@end
