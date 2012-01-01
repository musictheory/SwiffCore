/*
    SwiffBitmapDefinition.h
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

#import "SwiffBitmapDefinition.h"

#include <zlib.h>

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif


static NSInteger sFindJPEGStart(const UInt8 *b, NSUInteger length)
{
    NSInteger i = 0;

    // "Before version 8 of the SWF file format, SWF files could contain an erroneous header
    //  of 0xFF, 0xD9, 0xFF, 0xD8 before the JPEG SOI marker" (Page 147)
    //
    if (length >= 6) {
        if (b[i] == 0xFF && b[i+1] == 0xD9 && b[i+2] == 0xFF && b[i+3] == 0xD8) {
            if (b[i+4] == 0xFF && b[i+5] == 0xD8) {
                i += 4;
            } else {
                i += 2;
            }
        }
    }

    if ((length >= 2) && (b[i] == 0xFF) && (b[i+1] == 0xD8)) {
        return i;
    } else {
        return NSNotFound;
    }
}


static BOOL sIsJPEG(const UInt8 *bytes, NSUInteger length)
{
    NSInteger offset = sFindJPEGStart(bytes, length);
    return offset != NSNotFound;
}


// Based on flash.util.SwfImageUtils.JPEGIterator of the Adobe Flex SDK
//
static void sEnumerateJPEG(NSData *data, void (^callback)(UInt8, const UInt8 *, NSUInteger))
{
    const UInt8 *bytes = [data bytes];
    NSUInteger totalLength = [data length];

    NSInteger start = sFindJPEGStart(bytes, totalLength);

    __block BOOL      valid      = (start != NSNotFound);
    __block NSInteger offset     = start;
    __block NSInteger length     = 0;
    __block NSInteger nextOffset = 0;
    __block UInt8     code       = bytes[start + 1];

    NSInteger (^getNextOffset)() = ^{
        NSInteger i = offset + 2 + length;

        while (i < totalLength) {
            if ((code == 0xDA) && (bytes[i] != 0xFF)) {
                ++i;
            } else if ((i + 1) >= totalLength) {
                i = -1;
                break;
            } else if (bytes[i + 1] == 0xFF) {
                ++i;
            } else if ((code == 0xDA) && (bytes[i + 1] == 0x00)) {
                i += 2;
            } else {
                break;
            }
        }

        return i;
    };
    
    void (^next)() = ^{
        offset = nextOffset;
        if ((offset >= totalLength) || (offset == -1)) {
            valid  = NO;
            offset = totalLength;
            return;
        }

        code = bytes[offset + 1];

        if ((code == 0x00) || (code == 0x01) || ((code >= 0xD0) && (code <= 0xd9))) {
            length = 0;
        } else if ((offset + 3) >= totalLength) {
            valid = NO;
        } else {
            length = (bytes[offset + 2] << 8) + bytes[offset + 3];
        }

        nextOffset = getNextOffset();
    };

    while (valid) {
        NSInteger size = ((nextOffset >= 0) ? nextOffset : totalLength) - offset;
        callback(code, bytes + offset, size);
        next();
    }
}


static NSData *sCreateValidJPEG(NSData *inData, NSData *inTableData) CF_RETURNS_RETAINED;

static NSData *sCreateValidJPEG(NSData *inData, NSData *inTableData)
{
    NSMutableData *tableData   = [[NSMutableData alloc] initWithCapacity:[inData length]];
    NSMutableData *preScanData = [[NSMutableData alloc] initWithCapacity:[inData length]];
    NSMutableData *scanData    = [[NSMutableData alloc] initWithCapacity:[inData length]];

    __block BOOL foundScan = NO;

    // Split inData into tables, pre-Start-of-Scan, and Start-of-scan
    {
        sEnumerateJPEG(inData, ^(UInt8 code, const UInt8 *bytes, NSUInteger length) {
            if (code == 0xDA) {
                foundScan = YES;
            }

            if ((code == 0xDB) || (code == 0xC4)) {
                [tableData appendBytes:bytes length:length];

            } else if ((code != 0xD8) && (code != 0xD9)) {
                [(foundScan ? scanData : preScanData) appendBytes:bytes length:length];
            }
        });
    }

    // If we didn't have tableData, extract the tables from inTableData
    if (![tableData length]) {
        sEnumerateJPEG(inTableData, ^(UInt8 code, const UInt8 *bytes, NSUInteger length) {
            if ((code == 0xDB) || (code == 0xC4)) {
                [tableData appendBytes:bytes length:length];
            }
        });
    }

    // We now have all of the table segments in tableData, and all other segments in image
    NSMutableData *resultData = [[NSMutableData alloc] initWithCapacity:4 + [preScanData length] + [tableData length] + [scanData length]]; 
        
    [resultData appendBytes:"\xFF\xD8" length:2];
    [resultData appendData:preScanData];
    [resultData appendData:tableData];
    [resultData appendData:scanData];
    [resultData appendBytes:"\xFF\xD9" length:2];

    [tableData   release];
    [preScanData release];
    [scanData    release];

    return resultData;
}


static NSData *sCreateUncompressedData(const UInt8 *bytes, NSUInteger length)
{
    z_stream stream;
    bzero(&stream, sizeof(z_stream));

    NSMutableData *outData = [[NSMutableData alloc] initWithLength:(8 * 1024)];

    stream.next_in  = (Bytef *)bytes;
    stream.avail_in = length;

    if (inflateInit(&stream) == Z_OK) {
        do {
            if (stream.total_out >= [outData length]) {
                [outData increaseLengthBy: (8 * 1024)];
            }

            stream.next_out  = [outData mutableBytes] + stream.total_out;
            stream.avail_out = (unsigned int)([outData length] - stream.total_out);

            inflate(&stream, Z_FINISH);  
        } while (stream.avail_out == 0);

        inflateEnd(&stream);

        [outData setLength:stream.total_out];

    }

    return outData;
}


static CGImageRef sCreateImage(size_t width, size_t height, size_t bitsPerComponent, size_t bitsPerPixel, CGBitmapInfo bitmapInfo, NSData *data)
{
    CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)data);
    
    size_t bytesPerRow = (width * bitsPerPixel + 7) / 8;

    CGImageRef result = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow, rgb, bitmapInfo, provider, NULL, NO, kCGRenderingIntentDefault);
    
    CGColorSpaceRelease(rgb);
    CGDataProviderRelease(provider);

    return result;
}


static CGImageRef sCreateImage_RGB_555(size_t width, size_t height, NSData *data)
{
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Big | kCGImageAlphaNone;
    return sCreateImage(width, height, 5, 16, bitmapInfo, data);
}


static CGImageRef sCreateImage_XRGB_8888(size_t width, size_t height, NSData *data)
{
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Big | kCGImageAlphaNoneSkipFirst;
    return sCreateImage(width, height, 8, 32, bitmapInfo, data);
}


static CGImageRef sCreateImage_ARGB_8888(size_t width, size_t height, NSData *data)
{
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Big | kCGImageAlphaFirst;
    return sCreateImage(width, height, 8, 32, bitmapInfo, data);
}


static CGImageRef sCreateImage_Bytes(const UInt8 *bytes, NSUInteger length, NSData *jpegTables)
{
    NSData *data = nil;
    if (sIsJPEG(bytes, length)) {
        NSData *tmp = [[NSData alloc] initWithBytesNoCopy:(void *)bytes length:length freeWhenDone:NO];
        data = sCreateValidJPEG(tmp, jpegTables);
        [tmp release];

    } else {
        data = [[NSData alloc] initWithBytes:bytes length:length];
    }

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
    UIImage *image = [[UIImage alloc] initWithData:data];
#else
    NSBitmapImageRep *image = [[NSBitmapImageRep alloc] initWithData:data];
#endif

    CGImageRef result = [image CGImage];
    CGImageRetain(result);
    
    [image release];
    [data release];

    return result;
}


static CGImageRef sCreateImage_Indexed(size_t width, size_t height, NSInteger indexCount, BOOL alpha, NSData *data)
{
    const UInt8 *bytes = [data bytes];
    NSUInteger length = [data length];

    UInt32 *table = calloc(sizeof(UInt32), 256);
    indexCount *= (alpha ? 4 : 3);

    NSInteger i = 0, o = 0;
    while (i < indexCount) {
        UInt8 r = bytes[i++];
        UInt8 g = bytes[i++];
        UInt8 b = bytes[i++];
        UInt8 a = 0;
        
        if (alpha) {
            a = bytes[i++];
        }
       
        // Store as ARGB in table.
#if TARGET_RT_BIG_ENDIAN
        table[o++] = (a << 24) | (r << 16) | (g << 8)  |  b;
#else
        table[o++] = (b << 24) | (g << 16) | (r << 8)  |  a;
#endif
    }

    bytes  += i;
    length -= i;

    UInt32  outLength = sizeof(UInt32) * length;
    UInt32 *outBytes  = malloc(outLength);

    // "Row widths in the pixel data fields of these structures must be rounded up to the next 32-bit word boundary."
    UInt8 bytesPerRow = ((width + 3) / 4) * 4;
    
    o = 0;
    for (NSInteger y = 0; y < height; y++) {
        i = (y * bytesPerRow);

        for (NSInteger x = 0; x < width; x++) {
            outBytes[o++] = table[bytes[i]];
            i++;
        }
    }
    
    NSData *outData = [[NSData alloc] initWithBytesNoCopy:outBytes length:outLength freeWhenDone:YES];
    CGImageRef result = (alpha ? sCreateImage_ARGB_8888 : sCreateImage_XRGB_8888)(width, height, outData);
    [outData release];
    
    free(table);

    return result;
}


@implementation SwiffBitmapDefinition

- (id) initWithParser:(SwiffParser *)parser movie:(SwiffMovie *)movie
{
    if ((self = [super init])) {
        UInt16 libraryID;
        SwiffParserReadUInt16(parser, &libraryID);
        m_movie     = movie;
        m_libraryID = libraryID;

        SwiffTagJoin(SwiffParserGetCurrentTag(parser), SwiffParserGetCurrentTagVersion(parser), &m_tag);

        NSData *tagData = nil;
        UInt32 remainingBytes = SwiffParserGetBytesRemainingInCurrentTag(parser);
        SwiffParserReadData(parser, remainingBytes, &tagData);
        
        m_tagData = [tagData retain];
        
        if (!SwiffParserIsValid(parser)) {
            [self release];
            return nil;
        }
    }
    
    return self;
}


- (void) dealloc
{
    [m_tagData        release];  m_tagData        = nil;
    [m_jpegTablesData release];  m_jpegTablesData = nil;
    CGImageRelease(m_CGImage);   m_CGImage        = NULL;

    [super dealloc];
}


- (void) clearWeakReferences
{
    m_movie = nil;
}


- (void) _generateImage
{
    if (!m_tagData) return;

    const UInt8 *bytes  = [m_tagData bytes];
    NSUInteger   length = [m_tagData length];

    if ((m_tag == SwiffTagDefineBits) || (m_tag == SwiffTagDefineBitsJPEG2)) {
        m_CGImage = sCreateImage_Bytes(bytes, length, m_jpegTablesData);

    } else if ((m_tag == SwiffTagDefineBitsJPEG3) || (m_tag == SwiffTagDefineBitsJPEG4)) {
        UInt32 dataSize    = (bytes[3] << 24) | (bytes[2] << 16) | (bytes[1] << 8) | bytes[0];
        UInt16 imageOffset = 4;
        UInt16 alphaOffset = 4 + dataSize;
        
        if (m_tag == SwiffTagDefineBitsJPEG4) {
            dataSize    -= 2;
            imageOffset += 2;
            alphaOffset += 2;
        }

        CGImageRef image = sCreateImage_Bytes(bytes + imageOffset, dataSize, m_jpegTablesData);
        
        if (image) {
            NSData *alphaData = sCreateUncompressedData(bytes + alphaOffset, length - alphaOffset);

            if ([alphaData length]) {
                size_t width = CGImageGetWidth(image);
                size_t height = CGImageGetHeight(image);

                CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)alphaData);

                CGColorSpaceRef space = CGColorSpaceCreateDeviceGray();
                CGImageRef alphaImage = CGImageCreate(width, height, 8, 8, width, space, kCGImageAlphaNone, provider, NULL, NO, kCGRenderingIntentDefault);
                CGColorSpaceRelease(space);

                if (alphaImage) {
                    m_CGImage = CGImageCreateWithMask(image, alphaImage);
                }

                CGDataProviderRelease(provider);
                CGImageRelease(alphaImage);
            }

            [alphaData release];
        }

        if (m_CGImage) {
            CGImageRelease(image);
        } else {
            m_CGImage = image;
        }
       
    } else if ((m_tag == SwiffTagDefineBitsLossless) || (m_tag == SwiffTagDefineBitsLossless2)) {
        BOOL   alpha  = (m_tag == SwiffTagDefineBitsLossless2);
        UInt8  format =  bytes[0];
        size_t width  = (bytes[2] << 8) | bytes[1];
        size_t height = (bytes[4] << 8) | bytes[3];

        UInt8  offsetForImage = (format == 3) ? 6 : 5;
        NSData *imageData = sCreateUncompressedData(bytes + offsetForImage, length - offsetForImage);
 
        if (format == 3) {
            m_CGImage = sCreateImage_Indexed(width, height, bytes[5] + 1, alpha, imageData);

        } else if (format == 4) {
            //!issue: Untested code path, see issue #12
            m_CGImage = sCreateImage_RGB_555(width, height, imageData);

        } else if (format == 5) {
            m_CGImage = (alpha ? sCreateImage_ARGB_8888 : sCreateImage_XRGB_8888)(width, height, imageData);
        }

        [imageData release];
    }

    [m_tagData release];
    m_tagData = nil;
    
    [m_jpegTablesData release];
    m_jpegTablesData = nil;
}


#pragma mark -
#pragma mark Accessors

- (void) _setJPEGTablesData:(NSData *)data
{
    if (m_jpegTablesData != data) {
        [m_jpegTablesData release];
        m_jpegTablesData = [data retain];
    }
}


- (CGImageRef) CGImage
{
    if (!m_CGImage) {
        [self _generateImage];
    }
    
    return m_CGImage;
}


- (CGRect) bounds
{
    return CGRectZero;
}


- (CGRect) renderBounds
{
    return CGRectZero;
}


@synthesize movie     = m_movie,
            libraryID = m_libraryID;

@end
