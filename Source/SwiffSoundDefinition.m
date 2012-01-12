/*
    SwiffSoundDefinition.m
    Copyright (c) 2011-2012, musictheory.net, LLC.  All rights reserved.

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

#import "SwiffSoundDefinition.h"


#import <SwiffUtils.h>
#import <SwiffSoundStreamBlock.h>


@interface SwiffSoundDefinition ()
- (void) _readMP3FramesFromParser:(SwiffParser *)parser;
@end


@implementation SwiffSoundDefinition

- (id) initWithParser:(SwiffParser *)parser movie:(SwiffMovie *)movie
{
    if ((self = [super init])) {
        SwiffTag tag = SwiffParserGetCurrentTag(parser);

        if (tag == SwiffTagDefineSound) {
            SwiffParserReadUInt16(parser, &m_libraryID);

        } else if (tag == SwiffTagSoundStreamHead) {
            UInt32 reserved, playbackSoundRate, playbackSoundSize, playbackSoundType;
            
            SwiffParserReadUBits(parser, 4, &reserved);
            SwiffParserReadUBits(parser, 2, &playbackSoundRate);
            SwiffParserReadUBits(parser, 1, &playbackSoundSize);
            SwiffParserReadUBits(parser, 1, &playbackSoundType);

            // From documentation:
            // "The PlaybackSoundRate, PlaybackSoundSize, and PlaybackSoundType fields are advisory only;
            //  Flash Player may ignore them."
        }

        UInt32 soundFormat, soundRate, soundSize, soundType;
        SwiffParserReadUBits(parser, 4, &soundFormat);
        SwiffParserReadUBits(parser, 2, &soundRate);
        SwiffParserReadUBits(parser, 1, &soundSize);
        SwiffParserReadUBits(parser, 1, &soundType);
        
        m_movie          = movie;
        m_format         = soundFormat;
        m_rawSampleRate  = soundRate;
        m_bitsPerChannel = (soundSize == 1) ? 16 : 8;
        m_stereo         = (soundType == 1) ? YES : NO;
        m_data           = [[NSMutableData alloc] init];

        if (tag == SwiffTagDefineSound) {
            SwiffParserReadUInt32(parser, &m_sampleCount);

            if (soundFormat == SwiffSoundFormatMP3) {
                SwiffParserReadSInt16(parser, &m_latencySeek);
                [self _readMP3FramesFromParser:parser];
            }

        } else if (tag == SwiffTagSoundStreamHead) {
            SwiffParserReadUInt16(parser, &m_averageSampleCount);
            
            if (soundFormat == SwiffSoundFormatMP3) {
                SwiffParserReadSInt16(parser, &m_latencySeek);
            }

            m_streaming = YES;
        }
    }
    
    return self;
}


- (void) dealloc
{
    free(m_frames);
    m_frames = NULL;

    [m_data release];
    m_data = nil;

    [super dealloc];
}


- (void) clearWeakReferences
{
    m_movie = nil;
}


#pragma mark -
#pragma mark - Private Methods

- (void) _readMP3FramesFromParser:(SwiffParser *)parser
{
    while (SwiffParserGetBytesRemainingInCurrentTag(parser) > 0) {
        const void *frameStart = SwiffParserGetCurrentBytePointer(parser);

        SwiffMPEGHeader header;
        SwiffMPEGError  error = SwiffMPEGReadHeader(frameStart, &header);
        if (error != SwiffMPEGErrorNone) {
            SwiffWarn(@"Sound", @"SwiffMPEGReadHeader() returned %d", error);
        }

        if (m_framesCount == m_framesCapacity) {
            m_framesCapacity = m_framesCapacity ? m_framesCapacity * 2 : 256;
            m_frames = realloc(m_frames, sizeof(NSUInteger) * m_framesCapacity);
        }

        m_frames[m_framesCount] = [m_data length];
        m_framesCount++;
        
        [m_data appendBytes:frameStart length:header.frameSize];

        SwiffParserAdvance(parser, header.frameSize);
    }
}


#pragma mark -
#pragma mark Public Methods

CFDataRef SwiffSoundDefinitionGetData(SwiffSoundDefinition *self)
{
    return (__bridge CFDataRef)self->m_data;
}


extern CFIndex SwiffSoundDefinitionGetOffsetForFrame(SwiffSoundDefinition *self, CFIndex frame)
{
    if ((frame >= 0) && (frame < self->m_framesCount)) {
        return self->m_frames[frame];
    }
    
    return kCFNotFound;
}


extern CFIndex SwiffSoundDefinitionGetLengthForFrame(SwiffSoundDefinition *self, CFIndex frame)
{
    CFIndex offset1 = SwiffSoundDefinitionGetOffsetForFrame(self, frame);
    if (offset1 == kCFNotFound) return 0;

    CFIndex offset2 = SwiffSoundDefinitionGetOffsetForFrame(self, frame + 1);
    if (offset2 == kCFNotFound) {
        offset2 = CFDataGetLength(SwiffSoundDefinitionGetData(self));
    }
    
    return offset2 - offset1;
}


- (SwiffSoundStreamBlock *) readSoundStreamBlockTagFromParser:(SwiffParser *)parser
{
    SwiffSoundStreamBlock *result = nil;

    if (m_streaming) {
        result = [[SwiffSoundStreamBlock alloc] init];
        
        [result setFrameOffset:m_framesCount];
        
        if (m_format == SwiffSoundFormatMP3) {
            UInt16 sampleCount = 0;
            SwiffParserReadUInt16(parser, &sampleCount);
            [result setSampleCount:sampleCount];

            m_sampleCount += sampleCount;

            SInt16 seekSamples = 0;
            SwiffParserReadSInt16(parser, &seekSamples);
            [result setSampleSeek:seekSamples];
        }

        [self _readMP3FramesFromParser:parser];
    }

    return [result autorelease];
}


#pragma mark -
#pragma mark Accessors

- (CGRect) bounds       { return CGRectZero; }
- (CGRect) renderBounds { return CGRectZero; }


- (float) sampleRate
{
    if      (m_rawSampleRate == 0)  return  5512.5f;
    else if (m_rawSampleRate == 1)  return 11025.0f;
    else if (m_rawSampleRate == 2)  return 22050.0f;
    else                            return 44100.0f;
}

- (SwiffSoundFormat) format      { return m_format;             }
- (BOOL)      isStreaming        { return m_libraryID == 0;     }
- (NSInteger) averageSampleCount { return m_averageSampleCount; }
- (NSInteger) latencySeek        { return m_latencySeek;        }

@synthesize stereo             = m_stereo,
            bitsPerChannel     = m_bitsPerChannel,
            movie              = m_movie,
            libraryID          = m_libraryID,
            data               = m_data,
            sampleCount        = m_sampleCount;

@end
