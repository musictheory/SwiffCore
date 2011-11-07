/*
    SwiftMPEGUtils.h
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

#import <SwiftImport.h>


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
