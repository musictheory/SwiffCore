/*
    SwiffMPEGUtils.h
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

#import <SwiffImport.h>


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


typedef struct _SwiffMPEGHeader {
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


SwiffMPEGError SwiffMPEGReadHeader(const UInt8 *inBuffer, SwiffMPEGHeader *outHeader);

extern UInt32 SwiffMPEGGetBitrate(SwiffMPEGVersion version, SwiffMPEGLayer layer, UInt8 bitrateIndex);
extern UInt32 SwiffMPEGGetSamplesPerFrame(SwiffMPEGVersion version, SwiffMPEGLayer layer);
extern UInt16 SwiffMPEGGetSamplingRate(SwiffMPEGVersion version, UInt8 rateIndex);

extern NSInteger SwiffMPEGGetCoefficients(SwiffMPEGVersion version, SwiffMPEGLayer layer);
extern NSInteger SwiffMPEGGetSlotSize(SwiffMPEGLayer layer);

extern UInt32 SwiffMPEGGetFrameSize(SwiffMPEGVersion version, SwiffMPEGLayer layer, NSInteger bitrate, NSInteger samplingRate, BOOL hasPadding);
