//
//  SwiffTypes.h
//  SwiffCore
//
//  Created by Ricci Adams on 2012-01-06.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <SwiffImport.h>

typedef NSInteger SwiffTwips;


typedef struct SwiffPoint {
    SwiffTwips x;
    SwiffTwips y;
} SwiffPoint;


typedef struct SwiffColorTransform {
    CGFloat redMultiply;
    CGFloat greenMultiply;
    CGFloat blueMultiply;
    CGFloat alphaMultiply;
    CGFloat redAdd;
    CGFloat greenAdd;
    CGFloat blueAdd;
    CGFloat alphaAdd;
} SwiffColorTransform;

extern const SwiffColorTransform SwiffColorTransformIdentity;


typedef struct SwiffColor {
    CGFloat red;
    CGFloat green;
    CGFloat blue;
    CGFloat alpha;
} SwiffColor;


typedef struct SwiffHeader {
    UInt8   version;
    BOOL    isCompressed;
    UInt16  frameCount;
    UInt32  fileLength;
    CGRect  stageRect;
    CGFloat frameRate;
} SwiffHeader;


typedef struct SwiffSparseArray {
    id      **values;
} SwiffSparseArray;


enum {
//                                                     Description                      Minimum .swf version
    SwiffSoundFormatUncompressedNativeEndian = 0,   // Uncompressed, native-endian      1
    SwiffSoundFormatADPCM                    = 1,   // ADPCM                            1
    SwiffSoundFormatMP3                      = 2,   // MP3                              4
    SwiffSoundFormatUncompressedLittleEndian = 3,   // Uncompressed, little-endian      4
    SwiffSoundFormatNellymoser16kHz          = 4,   // Nellymoser, 16kHz                10
    SwiffSoundFormatNellymoser8kHZ           = 5,   // Nellymoser, 8kHz                 10
    SwiffSoundFormatNellymoser               = 6,   // Nellymoser                       6
    SwiffSoundFormatSpeex                    = 11   // Speex                            10
};
typedef NSInteger SwiffSoundFormat;


enum {
    SwiffFontLanguageCodeNone               = 0,
    SwiffFontLanguageCodeLatin              = 1,
    SwiffFontLanguageCodeJapanese           = 2,
    SwiffFontLanguageCodeKorean             = 3,
    SwiffFontLanguageCodeSimplifiedChinese  = 4,
    SwiffFontLanguageCodeTraditionalChinese = 5
};
typedef NSInteger SwiffLanguageCode;


enum {
    SwiffBlendModeNormal     = 0,
    SwiffBlendModeLayer      = 2,
    SwiffBlendModeMultiply   = 3,
    SwiffBlendModeScreen     = 4,
    SwiffBlendModeLighten    = 5,
    SwiffBlendModeDarken     = 6,
    SwiffBlendModeDifference = 7,
    SwiffBlendModeAdd        = 8,
    SwiffBlendModeSubtract   = 9,
    SwiffBlendModeInvert     = 10,
    SwiffBlendModeAlpha      = 11,
    SwiffBlendModeErase      = 12,
    SwiffBlendModeOverlay    = 13,
    SwiffBlendModeHardlight  = 14,
    SwiffBlendModeOther      = 256
};
typedef NSInteger SwiffBlendMode;


enum {
    SwiffTagEnd                          = 0,
    SwiffTagShowFrame                    = 1,
    SwiffTagDefineShape                  = 2,
    SwiffTagPlaceObject                  = 4,
    SwiffTagRemoveObject                 = 5,
    SwiffTagDefineBits                   = 6,
    SwiffTagDefineButton                 = 7,
    SwiffTagJPEGTables                   = 8,
    SwiffTagSetBackgroundColor           = 9,
    SwiffTagDefineFont                   = 10,
    SwiffTagDefineText                   = 11,
    SwiffTagDoAction                     = 12,
    SwiffTagDefineFontInfo               = 13,
    SwiffTagDefineSound                  = 14,
    SwiffTagStartSound                   = 15,
    SwiffTagDefineButtonSound            = 17,
    SwiffTagSoundStreamHead              = 18,
    SwiffTagSoundStreamBlock             = 19,
    SwiffTagDefineBitsLossless           = 20,
    SwiffTagDefineBitsJPEG2              = 21, // Mapped to SwiffTagDefineBits, version=2
    SwiffTagDefineShape2                 = 22, // Mapped to SwiffTagDefineShape, version=2
    SwiffTagDefineButtonCxform           = 23,
    SwiffTagProtect                      = 24,
    SwiffTagPlaceObject2                 = 26, // Mapped to SwiffTagPlaceObject, version=2
    SwiffTagRemoveObject2                = 28, // Mapped to SwiffTagRemoveObject, version=2
    SwiffTagDefineShape3                 = 32, // Mapped to SwiffTagDefineShape, version=3
    SwiffTagDefineText2                  = 33, // Mapped to SwiffTagDefineText, version=2
    SwiffTagDefineButton2                = 34, // Mapped to SwiffTagDefineButton, version=1
    SwiffTagDefineBitsJPEG3              = 35, // Mapped to SwiffTagDefineBits, version=3
    SwiffTagDefineBitsLossless2          = 36, // Mapped to SwiffTagDefineBitsLossless, version=2
    SwiffTagDefineEditText               = 37,
    SwiffTagDefineSprite                 = 39,
    SwiffTagFrameLabel                   = 43,
    SwiffTagSoundStreamHead2             = 45, // Mapped to SwiffTagSoundStreamHead, version=2
    SwiffTagDefineMorphShape             = 46,
    SwiffTagDefineFont2                  = 48, // Mapped to SwiffDefineFont, version=2
    SwiffTagExportAssets                 = 56,
    SwiffTagImportAssets                 = 57,
    SwiffTagEnableDebugger               = 58,
    SwiffTagDoInitAction                 = 59,
    SwiffTagDefineVideoStream            = 60,
    SwiffTagVideoFrame                   = 61,
    SwiffTagDefineFontInfo2              = 62, // Mapped to SwiffTagDefineFontInfo, version=2
    SwiffTagEnableDebugger2              = 64, // Mapped to SwiffTagEnableDebugger, version=2
    SwiffTagScriptLimits                 = 65,
    SwiffTagSetTabIndex                  = 66,
    SwiffTagFileAttributes               = 69,
    SwiffTagPlaceObject3                 = 70, // Mapped to SwiffTagPlaceObject, version=3
    SwiffTagImportAssets2                = 71, // Mapped to SwiffTagImportAssets, version=2
    SwiffTagDefineFontAlignZones         = 73,
    SwiffTagCSMTextSettings              = 74,
    SwiffTagDefineFont3                  = 75, // Mapped to SwiffTagDefineFont, version=3
    SwiffTagSymbolClass                  = 76,
    SwiffTagMetadata                     = 77,
    SwiffTagDefineScalingGrid            = 78,
    SwiffTagDoABC                        = 82,
    SwiffTagDefineShape4                 = 83, // Mapped to SwiffTagDefineShape, version=4
    SwiffTagDefineMorphShape2            = 84, // Mapped to SwiffTagDefineMorphShape, version=2
    SwiffTagDefineSceneAndFrameLabelData = 86,
    SwiffTagDefineBinaryData             = 87,
    SwiffTagDefineFontName               = 88,
    SwiffTagStartSound2                  = 89, // Mapped to SwiffTagStartSound, version=2
    SwiffTagDefineBitsJPEG4              = 90, // Mapped to SwiffTagDefineBits, version=4
    SwiffTagDefineFont4                  = 91, // Mapped to SwiffTagDefineFont, version=4

    SwiffTagCount
};
typedef NSInteger SwiffTag;


enum {
    SwiffMPEGVersion25 = 0,
    SwiffMPEGVersion2  = 2,
    SwiffMPEGVersion1  = 3,
};
typedef UInt8 SwiffMPEGVersion;


enum {
    SwiffMPEGLayer3 = 1,
    SwiffMPEGLayer2 = 2,
    SwiffMPEGLayer1 = 3
};
typedef UInt8 SwiffMPEGLayer;


enum {
    SwiffMPEGEmphasisNone     = 0,
    SwiffMPEGEmphasis50_15ms  = 1,
    SwiffMPEGEmphasisCCIT_J17 = 3
};
typedef UInt8 SwiffMPEGEmphasis;


enum {
    SwiffMPEGChannelModeStereo      = 0,
    SwiffMPEGChannelModeJointStereo = 1,
    SwiffMPEGChannelModeDual        = 2,
    SwiffMPEGChannelModeMono        = 3

};
typedef UInt8 SwiffMPEGChannelMode;


enum {
    SwiffMPEGErrorNone                 =  0,
    SwiffMPEGErrorInvalidFrameSync     = -1,
    SwiffMPEGErrorBadBitrate           = -2,

    SwiffMPEGErrorReservedVersion      =  1,
    SwiffMPEGErrorReservedLayer        =  2,
    SwiffMPEGErrorReservedSamplingRate =  3,
    SwiffMPEGErrorReservedEmphasis     =  4
};
typedef NSInteger SwiffMPEGError;


typedef struct SwiffMPEGHeader {
    SwiffMPEGVersion     version;
    SwiffMPEGLayer       layer;
    UInt16               samplingRate;
    UInt32               bitrate;
    SwiffMPEGChannelMode channelMode;
    UInt8                modeExtension;
    BOOL                 hasCRC;
    BOOL                 hasPadding;
    BOOL                 hasCopyright;
    BOOL                 isOriginal;
    SwiffMPEGEmphasis    emphasis;
    UInt32               frameSize;
} SwiffMPEGHeader;

