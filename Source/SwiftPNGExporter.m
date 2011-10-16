//
//  SwiftPNGExporter.m
//  SwiftCore
//
//  Created by Ricci Adams on 2011-10-13.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SwiftPNGExporter.h"
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
    CGSize     stageSize = [movie stageSize];
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
