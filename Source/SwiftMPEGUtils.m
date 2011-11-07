/*
    SwiftMPEGUtils.m
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

#import "SwiftMPEGUtils.h"


SwiftMPEGError SwiftMPEGReadHeader(const UInt8 *buffer, SwiftMPEGHeader *header)
{
    UInt16 frameSync    = 0;
    UInt8  bitrateIndex = 0;
    UInt8  rateIndex    = 0;

    UInt32 i = ntohl(*((UInt32 *)buffer));
 
    frameSync             = ((i >> 21) & 0x7FF);
    header->version       = ((i >> 19) & 0x3);
    header->layer         = ((i >> 17) & 0x3);
    header->hasCRC        = ((i >> 16) & 0x1) ? NO : YES;
    bitrateIndex          = ((i >> 12) & 0xf);
    rateIndex             = ((i >> 10) & 0x3);
    header->hasPadding    = ((i >>  9) & 0x1);
/*  UInt8 reserved        = ((i >>  8) & 0x1); */
    header->channelMode   = ((i >>  6) & 0x3);
    header->modeExtension = ((i >>  4) & 0x3);
    header->hasCopyright  = ((i >>  3) & 0x1);
    header->isOriginal    = ((i >>  2) & 0x1);
    header->emphasis      = ((i      ) & 0x3);

    header->samplingRate  = SwiftMPEGGetSamplingRate(header->version, rateIndex);
    header->bitrate       = SwiftMPEGGetBitrate(header->version, header->layer, bitrateIndex);
    header->frameSize     = SwiftMPEGGetFrameSize(header->version, header->layer, header->bitrate, header->samplingRate, header->hasPadding);

    SwiftMPEGError error = SwiftMPEGErrorNone;

    // Check for errors
    if (frameSync != 0x7FF) {
        error = SwiftMPEGErrorInvalidFrameSync;
    } else if (bitrateIndex == 15) {
        error = SwiftMPEGErrorBadBitrate;
    }
    
    // Check for reserved values
    if (error == SwiftMPEGErrorNone) {
        if      (header->version  == 1) { error = SwiftMPEGErrorReservedVersion;      }
        else if (header->layer    == 0) { error = SwiftMPEGErrorReservedLayer;        }
        else if (rateIndex        == 3) { error = SwiftMPEGErrorReservedSamplingRate; }
        else if (header->emphasis == 2) { error = SwiftMPEGErrorReservedEmphasis;     }
    }   

    return error;
}


UInt32 SwiftMPEGGetBitrate(SwiftMPEGVersion version, SwiftMPEGLayer layer, UInt8 bitrateIndex)
{
    BOOL isVersion2x = (version == SwiftMPEGVersion2) || (version == SwiftMPEGVersion25);

    const NSInteger map[2][4][16] = {
        {
            {   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0 },  // Layer bit reserved
            {   0,  32,  40,  48,  56,  64,  80,  96, 112, 128, 160, 192, 224, 256, 320,   0 },  // MPEG1, Layer 3
            {   0,  32,  48,  56,  64,  80,  96, 112, 128, 160, 192, 224, 256, 320, 384,   0 },  // MPEG1, Layer 2
            {   0,  32,  64,  96, 128, 160, 192, 224, 256, 288, 320, 352, 384, 416, 448,   0 }   // MPEG1, Layer 1
        },{ 
            {   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0 },  // Layer bit reserved
            {   0,   8,  16,  24,  32,  40,  48,  56,  64,  80,  96, 112, 128, 144, 160,   0 },  // MPEG2x, Layer 3
            {   0,   8,  16,  24,  32,  40,  48,  56,  64,  80,  96, 112, 128, 144, 160,   0 },  // MPEG2x, Layer 2
            {   0,  32,  48,  56,  64,  80,  96, 112, 128, 144, 160, 176, 192, 224, 256,   0 }   // MPEG2x, Layer 1
        }
    };

    return map[isVersion2x ? 1 : 0][layer % 4][bitrateIndex % 16] * 1000;
}


UInt32 SwiftMPEGGetSamplesPerFrame(SwiftMPEGVersion version, SwiftMPEGLayer layer)
{
    static const NSInteger map[2][4] = {
        {   0, 1152, 1152, 384 },  // MPEG 1
        {   0,  576, 1152, 384 }   // MPEG 2, MPEG 2.5
    };

    BOOL isVersion2x = (version == SwiftMPEGVersion2) || (version == SwiftMPEGVersion25);
    return map[isVersion2x ? 1 : 0][layer % 4];
}


UInt16 SwiftMPEGGetSamplingRate(SwiftMPEGVersion version, UInt8 rateIndex)
{
    static const NSInteger map[4][3] = {
        { 11025, 12000,  8000 },  // MPEG 2.5
        {     0,     0,     0 },  // reserved
        { 22050, 24000, 16000 },  // MPEG 2
        { 44100, 48000, 32000 }   // MPEG 1
    };

    return map[version % 4][rateIndex % 3];
}


extern NSInteger SwiftMPEGGetCoefficients(SwiftMPEGVersion version, SwiftMPEGLayer layer)
{
    static const NSInteger map[2][4] = {
        {   0, 144, 144,  12 },  // MPEG 1
        {   0,  72, 144,  12 }   // MPEG 2, MPEG 2.5
    };

    BOOL isVersion2x = (version == SwiftMPEGVersion2) || (version == SwiftMPEGVersion25);
    return map[isVersion2x ? 1 : 0][layer % 4];
}


extern NSInteger SwiftMPEGGetSlotSize(SwiftMPEGLayer layer)
{
    static const NSInteger map[4] = { 0, 1, 1, 4 };
    return map[layer % 4];
}


extern UInt32 SwiftMPEGGetFrameSize(SwiftMPEGVersion version, SwiftMPEGLayer layer, NSInteger bitrate, NSInteger samplingRate, BOOL hasPadding)
{
    NSInteger coefficients = SwiftMPEGGetCoefficients(version, layer);
    NSInteger slotSize     = SwiftMPEGGetSlotSize(layer);

    if (samplingRate) {
        return (NSInteger)(((coefficients * bitrate / samplingRate) + (hasPadding ? 1 : 0))) * slotSize;
    } else {
        return 0;
    }
}

