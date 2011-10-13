//
//  SWFTypes.h
//  TheoryLessons
//
//  Created by Ricci Adams on 2011-10-05.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

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

