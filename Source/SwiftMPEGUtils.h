//
//  SwiftMPEGUtils.h
//  SwiftCore
//
//  Created by Ricci Adams on 2011-10-29.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

enum {
    SwiftMPEGVersion25 = 0,
    SwiftMPEGVersion2  = 2,
    SwiftMPEGVersion1  = 3,
};
typedef UInt8 SwiftMPEGVersion;


enum {
    SwiftMPEGLayer3 = 1,
    SwiftMPEGLayer2 = 2,
    SwiftMPEGLayer1 = 3
};
typedef UInt8 SwiftMPEGLayer;


enum {
    SwiftMPEGEmphasisNone     = 0,
    SwiftMPEGEmphasis50_15ms  = 1,
    SwiftMPEGEmphasisCCIT_J17 = 3
};
typedef UInt8 SwiftMPEGEmphasis;


enum {
    SwiftMPEGChannelModeStereo      = 0,
    SwiftMPEGChannelModeJointStereo = 1,
    SwiftMPEGChannelModeDual        = 2,
    SwiftMPEGChannelModeMono        = 3

};
typedef UInt8 SwiftMPEGChannelMode;


enum {
    SwiftMPEGErrorNone                 =  0,
    SwiftMPEGErrorInvalidFrameSync     = -1,
    SwiftMPEGErrorBadBitrate           = -2,

    SwiftMPEGErrorReservedVersion      =  1,
    SwiftMPEGErrorReservedLayer        =  2,
    SwiftMPEGErrorReservedSamplingRate =  3,
    SwiftMPEGErrorReservedEmphasis     =  4
};
typedef NSInteger SwiftMPEGError;


typedef struct _SwiftMPEGHeader {
    SwiftMPEGVersion     version;
    SwiftMPEGLayer       layer;
    UInt16               samplingRate;
    UInt32               bitrate;
    SwiftMPEGChannelMode channelMode;
    UInt8                modeExtension;
    BOOL                 hasCRC;
    BOOL                 hasPadding;
    BOOL                 hasCopyright;
    BOOL                 isOriginal;
    SwiftMPEGEmphasis    emphasis;
    UInt32               frameSize;
} SwiftMPEGHeader;


SwiftMPEGError SwiftMPEGReadHeader(const UInt8 *inBuffer, SwiftMPEGHeader *outHeader);

extern UInt32 SwiftMPEGGetBitrate(SwiftMPEGVersion version, SwiftMPEGLayer layer, UInt8 bitrateIndex);
extern UInt32 SwiftMPEGGetSamplesPerFrame(SwiftMPEGVersion version, SwiftMPEGLayer layer);
extern UInt16 SwiftMPEGGetSamplingRate(SwiftMPEGVersion version, UInt8 rateIndex);

extern NSInteger SwiftMPEGGetCoefficients(SwiftMPEGVersion version, SwiftMPEGLayer layer);
extern NSInteger SwiftMPEGGetSlotSize(SwiftMPEGLayer layer);

extern UInt32 SwiftMPEGGetFrameSize(SwiftMPEGVersion version, SwiftMPEGLayer layer, NSInteger bitrate, NSInteger samplingRate, BOOL hasPadding);
