/*
    SwiftSoundDefinition.m
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

#import "SwiftSoundDefinition.h"

@interface SwiftSoundDefinition ()
- (void) _readMP3FramesFromParser:(SwiftParser *)parser;
@end


@implementation SwiftSoundDefinition

- (id) initWithParser:(SwiftParser *)parser movie:(SwiftMovie *)movie
{
    if ((self = [super init])) {
        SwiftTag tag = SwiftParserGetCurrentTag(parser);

        if (tag == SwiftTagDefineSound) {
            SwiftParserReadUInt16(parser, &m_libraryID);

        } else if (tag == SwiftTagSoundStreamHead) {
            UInt32 reserved, playbackSoundRate, playbackSoundSize, playbackSoundType;
            
            SwiftParserReadUBits(parser, 4, &reserved);
            SwiftParserReadUBits(parser, 2, &playbackSoundRate);
            SwiftParserReadUBits(parser, 1, &playbackSoundSize);
            SwiftParserReadUBits(parser, 1, &playbackSoundType);

            // From documentation:
            // "The PlaybackSoundRate, PlaybackSoundSize, and PlaybackSoundType fields are advisory only;
            //  Flash Player may ignore them."
        }

        UInt32 soundFormat, soundRate, soundSize, soundType;
        SwiftParserReadUBits(parser, 4, &soundFormat);
        SwiftParserReadUBits(parser, 2, &soundRate);
        SwiftParserReadUBits(parser, 1, &soundSize);
        SwiftParserReadUBits(parser, 1, &soundType);
        
        m_movie          = movie;
        m_format         = soundFormat;
        m_rawSampleRate  = soundRate;
        m_bitsPerChannel = (soundSize == 1) ? 16 : 8;
        m_stereo         = (soundType == 1) ? YES : NO;
        m_data           = [[NSMutableData alloc] init];

        if (tag == SwiftTagDefineSound) {
            SwiftParserReadUInt32(parser, &m_sampleCount);

            if (soundFormat == SwiftSoundFormatMP3) {
                SwiftParserReadSInt16(parser, &m_latencySeek);
                [self _readMP3FramesFromParser:parser];
            }

        } else if (tag == SwiftTagSoundStreamHead) {
            SwiftParserReadUInt16(parser, &m_averageSampleCount);
            
            if (soundFormat == SwiftSoundFormatMP3) {
                SwiftParserReadSInt16(parser, &m_latencySeek);
                [self _readMP3FramesFromParser:parser];
            }

            m_streaming = YES;
        }
    }
    
    return self;
}


- (void) dealloc
{
    free(m_streamBlockArray);
    m_streamBlockArray = NULL;
    
    free(m_frameRangeArray);
    m_frameRangeArray = NULL;

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

static size_t sGetStreamBlockSizeForFormat(UInt8 format)
{
    if (format == SwiftSoundFormatMP3) {
        return sizeof(SwiftSoundStreamBlockMP3);
    } else {
        return sizeof(SwiftSoundStreamBlock);
    }
}


- (SwiftSoundStreamBlock *) _nextStreamBlock
{
    size_t streamBlockSize = sGetStreamBlockSizeForFormat(m_format);

    if (m_streamBlockCount == m_streamBlockCapacity) {
        m_streamBlockCapacity = m_streamBlockCapacity ? m_streamBlockCapacity * 2 : 32;
        m_streamBlockArray = realloc(m_streamBlockArray, streamBlockSize * m_streamBlockCapacity);
    }

    void *nextStreamBlock = m_streamBlockArray + (m_streamBlockCount * streamBlockSize);
    m_streamBlockCount++;
    
    return nextStreamBlock;
}


- (NSRange *) _nextFrameRange
{
    if (m_frameRangeCount == m_frameRangeCapacity) {
        m_frameRangeCapacity = m_frameRangeCapacity ? m_frameRangeCapacity * 2 : 256;
        m_frameRangeArray = realloc(m_frameRangeArray, sizeof(NSRange) * m_frameRangeCapacity);
    }

    NSRange *nextFrameRange = &m_frameRangeArray[m_frameRangeCount];
    m_frameRangeCount++;
    
    return nextFrameRange;
}


- (void) _appendMP3Frame:(const void *)bytes length:(NSUInteger)length
{
    NSRange *frameRange = [self _nextFrameRange];
    
    frameRange->location = [m_data length];
    frameRange->length   = length;
    
    [m_data appendBytes:bytes length:length];
}


- (void) _readMP3FramesFromParser:(SwiftParser *)parser
{
    enum {
        MpegVersion25 = 0,
        MpegVersion2  = 2,
        MpegVersion1  = 3
    };

    while (SwiftParserGetBytesRemainingInCurrentTag(parser) > 0) {
        const void *frameStart = SwiftParserGetBytePointer(parser);

        UInt32 syncWord, mpegVersion, layer, protectionBit,
               rawBitrate, rawSamplingRate, paddingBit, reserved,
               channelMode, modeExtension, copyright, original, emphasis;
        
        SwiftParserReadUBits(parser, 11, &syncWord);
        SwiftParserReadUBits(parser,  2, &mpegVersion);
        SwiftParserReadUBits(parser,  2, &layer);
        SwiftParserReadUBits(parser,  1, &protectionBit);

        SwiftParserReadUBits(parser,  4, &rawBitrate);
        SwiftParserReadUBits(parser,  2, &rawSamplingRate);
        SwiftParserReadUBits(parser,  1, &paddingBit);
        SwiftParserReadUBits(parser,  1, &reserved);

        SwiftParserReadUBits(parser,  2, &channelMode);
        SwiftParserReadUBits(parser,  2, &modeExtension);
        SwiftParserReadUBits(parser,  1, &copyright);
        SwiftParserReadUBits(parser,  1, &original);
        SwiftParserReadUBits(parser,  2, &emphasis);

        UInt32 bitrate = 0;
        if (mpegVersion == MpegVersion1) {
            switch (rawBitrate) {
            case 1:   bitrate =  32000;  break;
            case 2:   bitrate =  40000;  break;
            case 3:   bitrate =  48000;  break;
            case 4:   bitrate =  56000;  break;
            case 5:   bitrate =  64000;  break;
            case 6:   bitrate =  80000;  break;
            case 7:   bitrate =  96000;  break;
            case 8:   bitrate = 112000;  break;
            case 9:   bitrate = 128000;  break;
            case 10:  bitrate = 160000;  break;
            case 11:  bitrate = 192000;  break;
            case 12:  bitrate = 224000;  break;
            case 13:  bitrate = 256000;  break;
            case 14:  bitrate = 320000;  break;
            }
        } else {
            switch (rawBitrate) {
            case 1:   bitrate =   8000;  break;
            case 2:   bitrate =  16000;  break;
            case 3:   bitrate =  24000;  break;
            case 4:   bitrate =  32000;  break;
            case 5:   bitrate =  40000;  break;
            case 6:   bitrate =  48000;  break;
            case 7:   bitrate =  56000;  break;
            case 8:   bitrate =  64000;  break;
            case 9:   bitrate =  80000;  break;
            case 10:  bitrate =  96000;  break;
            case 11:  bitrate = 112000;  break;
            case 12:  bitrate = 128000;  break;
            case 13:  bitrate = 144000;  break;
            case 14:  bitrate = 160000;  break;
            }
        }
        
        UInt32 samplingRate = 0;
        if (mpegVersion == MpegVersion1) {
            if      (rawSamplingRate == 0) samplingRate = 44100;
            else if (rawSamplingRate == 1) samplingRate = 48000;
            else if (rawSamplingRate == 2) samplingRate = 32000;

        } else if (mpegVersion == MpegVersion2) {
            if      (rawSamplingRate == 0) samplingRate = 22050;
            else if (rawSamplingRate == 1) samplingRate = 24000;
            else if (rawSamplingRate == 2) samplingRate = 16000;

        } else if (mpegVersion == MpegVersion25) {
            if      (rawSamplingRate == 0) samplingRate = 11025;
            else if (rawSamplingRate == 1) samplingRate = 12000;
            else if (rawSamplingRate == 2) samplingRate =  8000;
        }

        UInt32 size = samplingRate ? ((((mpegVersion == MpegVersion1) ? 144 : 72) * bitrate) / samplingRate) + paddingBit - 4 : 0;

        const void *frameEnd = SwiftParserGetBytePointer(parser);
        frameEnd += size;
        
        [self _appendMP3Frame:frameStart length:(frameEnd - frameStart)];
    }
}


#pragma mark -
#pragma mark Public Methods

- (NSUInteger) readSoundStreamBlockTagFromParser:(SwiftParser *)parser
{
    NSUInteger index = NSNotFound;

    if (m_streaming) {
        index = m_streamBlockCount;

        SwiftSoundStreamBlock *streamBlock = [self _nextStreamBlock];

        if (m_format == SwiftSoundFormatMP3) {
            UInt16 sampleCount = 0;
            SwiftParserReadUInt16(parser, &sampleCount);
            ((SwiftSoundStreamBlockMP3 *)streamBlock)->sampleCount = sampleCount;

            m_sampleCount += sampleCount;

            SInt16 seekSamples = 0;
            SwiftParserReadSInt16(parser, &seekSamples);
            ((SwiftSoundStreamBlockMP3 *)streamBlock)->seek = seekSamples;
        }

        UInt32 frameRangeCount = m_frameRangeCount;
        [self _readMP3FramesFromParser:parser];
        streamBlock->frameRangeIndex = frameRangeCount;
    }

    return index;
}


- (SwiftSoundStreamBlock *) streamBlockAtIndex:(NSUInteger)index
{
    size_t streamBlockSize = sGetStreamBlockSizeForFormat(m_format);
    return m_streamBlockArray ? m_streamBlockArray + (streamBlockSize * index) : NULL; 
}


- (NSRange) frameRangeAtIndex:(NSUInteger)index
{
    return m_frameRangeArray[index];
}


#pragma mark -
#pragma mark Accessors

- (float) sampleRate
{
    if      (m_rawSampleRate == 0)  return  5512.5f;
    else if (m_rawSampleRate == 1)  return 11025.0f;
    else if (m_rawSampleRate == 2)  return 22050.0f;
    else                            return 44100.0f;
}

- (SwiftSoundFormat) format      { return m_format;             }
- (BOOL)      isStreaming        { return m_libraryID == 0;     }
- (NSInteger) averageSampleCount { return m_averageSampleCount; }
- (NSInteger) latencySeek        { return m_latencySeek;        }

@synthesize stereo             = m_stereo,
            bitsPerChannel     = m_bitsPerChannel,
            movie              = m_movie,
            libraryID          = m_libraryID,
            streamBlockCount   = m_streamBlockCount,
            data               = m_data,
            sampleCount        = m_sampleCount,
            frameRangeCount    = m_frameRangeCount;

@end
