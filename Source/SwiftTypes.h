/*
    SwiftTypes.h
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

#import <Foundation/Foundation.h>


typedef struct _SwiftPoint {
    NSInteger x;
    NSInteger y;
} SwiftPoint;

typedef struct _SwiftColorTransform {
    CGFloat redMultiply;
    CGFloat greenMultiply;
    CGFloat blueMultiply;
    CGFloat alphaMultiply;
    CGFloat redAdd;
    CGFloat greenAdd;
    CGFloat blueAdd;
    CGFloat alphaAdd;
} SwiftColorTransform;

extern const SwiftColorTransform SwiftColorTransformIdentity;

typedef struct _SwiftColor {
    CGFloat red;
    CGFloat green;
    CGFloat blue;
    CGFloat alpha;
} SwiftColor;


typedef struct _SwiftHeader {
    UInt8   version;
    BOOL    isCompressed;
    UInt16  frameCount;
    UInt32  fileLength;
    CGRect  stageRect;
    CGFloat frameRate;
} SwiftHeader;


enum _SwiftSoundFormat {
//                                                     Description                      Minimum .swf version
    SwiftSoundFormatUncompressedNativeEndian = 0,   // Uncompressed, native-endian      1
    SwiftSoundFormatADPCM                    = 1,   // ADPCM                            1
    SwiftSoundFormatMP3                      = 2,   // MP3                              4
    SwiftSoundFormatUncompressedLittleEndian = 3,   // Uncompressed, little-endian      4
    SwiftSoundFormatNellymoser16kHz          = 4,   // Nellymoser, 16kHz                10
    SwiftSoundFormatNellymoser8kHZ           = 5,   // Nellymoser, 8kHz                 10
    SwiftSoundFormatNellymoser               = 6,   // Nellymoser                       6
    SwiftSoundFormatSpeex                    = 11   // Speex                            10
};
typedef NSInteger SwiftSoundFormat;


enum _SwiftTag {
    SwiftTagEnd                          = 0,
    SwiftTagShowFrame                    = 1,
    SwiftTagDefineShape                  = 2,
    SwiftTagPlaceObject                  = 4,
    SwiftTagRemoveObject                 = 5,
    SwiftTagDefineBits                   = 6,
    SwiftTagDefineButton                 = 7,
    SwiftTagJPEGTables                   = 8,
    SwiftTagSetBackgroundColor           = 9,
    SwiftTagDefineFont                   = 10,
    SwiftTagDefineText                   = 11,
    SwiftTagDoAction                     = 12,
    SwiftTagDefineFontInfo               = 13,
    SwiftTagDefineSound                  = 14,
    SwiftTagStartSound                   = 15,
    SwiftTagDefineButtonSound            = 17,
    SwiftTagSoundStreamHead              = 18,
    SwiftTagSoundStreamBlock             = 19,
    SwiftTagDefineBitsLossless           = 20,
    SwiftTagDefineBitsJPEG2              = 21, // Mapped to SwiftTagDefineBits, version=2
    SwiftTagDefineShape2                 = 22, // Mapped to SwiftTagDefineShape, version=2
    SwiftTagDefineButtonCxform           = 23,
    SwiftTagProtect                      = 24,
    SwiftTagPlaceObject2                 = 26, // Mapped to SwiftTagPlaceObject, version=2
    SwiftTagRemoveObject2                = 28, // Mapped to SwiftTagRemoveObject, version=2
    SwiftTagDefineShape3                 = 32, // Mapped to SwiftTagDefineShape, version=3
    SwiftTagDefineText2                  = 33, // Mapped to SwiftTagDefineText, version=2
    SwiftTagDefineButton2                = 34, // Mapped to SwiftTagDefineButton, version=1
    SwiftTagDefineBitsJPEG3              = 35, // Mapped to SwiftTagDefineBits, version=3
    SwiftTagDefineBitsLossless2          = 36, // Mapped to SwiftTagDefineBitsLossless, version=2
    SwiftTagDefineEditText               = 37,
    SwiftTagDefineSprite                 = 39,
    SwiftTagFrameLabel                   = 43,
    SwiftTagSoundStreamHead2             = 45, // Mapped to SwiftTagSoundStreamHead, version=2
    SwiftTagDefineMorphShape             = 46,
    SwiftTagDefineFont2                  = 48,
    SwiftTagExportAssets                 = 56,
    SwiftTagImportAssets                 = 57,
    SwiftTagEnableDebugger               = 58,
    SwiftTagDoInitAction                 = 59,
    SwiftTagDefineVideoStream            = 60,
    SwiftTagVideoFrame                   = 61,
    SwiftTagDefineFontInfo2              = 62, // Mapped to SwiftTagDefineFontInfo, version=2
    SwiftTagEnableDebugger2              = 64, // Mapped to SwiftTagEnableDebugger, version=2
    SwiftTagScriptLimits                 = 65,
    SwiftTagSetTabIndex                  = 66,
    SwiftTagFileAttributes               = 69,
    SwiftTagPlaceObject3                 = 70, // Mapped to SwiftTagPlaceObject, version=3
    SwiftTagImportAssets2                = 71, // Mapped to SwiftTagImportAssets, version=2
    SwiftTagDefineFontAlignZones         = 73,
    SwiftTagCSMTextSettings              = 74,
    SwiftTagDefineFont3                  = 75, // Mapped to SwiftTagDefineFont, version=3
    SwiftTagSymbolClass                  = 76,
    SwiftTagMetadata                     = 77,
    SwiftTagDefineScalingGrid            = 78,
    SwiftTagDoABC                        = 82,
    SwiftTagDefineShape4                 = 83, // Mapped to SwiftTagDefineShape, version=4
    SwiftTagDefineMorphShape2            = 84, // Mapped to SwiftTagDefineMorphShape, version=2
    SwiftTagDefineSceneAndFrameLabelData = 86,
    SwiftTagDefineBinaryData             = 87,
    SwiftTagDefineFontName               = 88,
    SwiftTagStartSound2                  = 89, // Mapped to SwiftTagStartSound, version=2
    SwiftTagDefineBitsJPEG4              = 90, // Mapped to SwiftTagDefineBits, version=4
    SwiftTagDefineFont4                  = 91, // Mapped to SwiftTagDefineFont, version=4

    SwiftTagCount
};
typedef NSInteger SwiftTag;

typedef NSInteger SwiftVersion;

typedef struct _SwiftParser SwiftParser;
typedef struct _SwiftWriter SwiftWriter;

