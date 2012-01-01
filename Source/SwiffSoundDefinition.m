/*
    SwiffSoundDefinition.m
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

#import "SwiffSoundDefinition.h"


#import "SwiffMPEGUtils.h"


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
    if (format == SwiffSoundFormatMP3) {
        return sizeof(SwiffSoundStreamBlockMP3);
    } else {
        return sizeof(SwiffSoundStreamBlock);
    }
}


- (SwiffSoundStreamBlock *) _nextStreamBlock
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


- (void) _readMP3FramesFromParser:(SwiffParser *)parser
{

    while (SwiffParserGetBytesRemainingInCurrentTag(parser) > 0) {
        const void *frameStart = SwiffParserGetCurrentBytePointer(parser);

        SwiffMPEGHeader header;
        SwiffMPEGError  error = SwiffMPEGReadHeader(frameStart, &header);
        if (error != SwiffMPEGErrorNone) {
            SwiffWarn(@"Sound", @"SwiffMPEGReadHeader() returned %d", error);
        }
       
        [self _appendMP3Frame:frameStart length:header.frameSize];

        SwiffParserAdvance(parser, header.frameSize);
    }
}


#pragma mark -
#pragma mark Public Methods

void SwiffSoundDefinitionFillBuffer(
    SwiffSoundDefinition *self,
    UInt32 inFrameIndex, void *inBuffer, UInt32 inBufferCapacity,
    UInt32 *outBytesWritten, UInt32 *outFramesWritten
) {
    CFIndex location      = kCFNotFound;
    CFIndex bytesWritten  = 0;
    UInt32  framesWritten = 0;
    
    while (1) {
        NSRange rangeOfFrame = self->m_frameRangeArray[inFrameIndex + framesWritten];
        
        if (location == kCFNotFound) {
            location = rangeOfFrame.location;
        }
        
        if ((bytesWritten + rangeOfFrame.length) < inBufferCapacity) {
            bytesWritten += rangeOfFrame.length;
            framesWritten++;

        } else {
            break;
        }
    }

    CFDataGetBytes((CFDataRef)self->m_data, CFRangeMake(location, bytesWritten), inBuffer);
    *outBytesWritten  = bytesWritten;
    *outFramesWritten = framesWritten;
}


CFDataRef SwiffSoundDefinitionGetData(SwiffSoundDefinition *self)
{
    return (__bridge CFDataRef)self->m_data;
}


CFRange SwiffSoundDefinitionGetFrameRangeAtIndex(SwiffSoundDefinition *self, CFIndex index)
{
    NSRange range = self->m_frameRangeArray[index];
    return CFRangeMake(range.location, range.length);
}


- (NSUInteger) readSoundStreamBlockTagFromParser:(SwiffParser *)parser
{
    NSUInteger index = NSNotFound;

    if (m_streaming) {
        index = m_streamBlockCount;

        SwiffSoundStreamBlock *streamBlock = [self _nextStreamBlock];

        if (m_format == SwiffSoundFormatMP3) {
            UInt16 sampleCount = 0;
            SwiffParserReadUInt16(parser, &sampleCount);
            ((SwiffSoundStreamBlockMP3 *)streamBlock)->sampleCount = sampleCount;

            m_sampleCount += sampleCount;

            SInt16 seekSamples = 0;
            SwiffParserReadSInt16(parser, &seekSamples);
            ((SwiffSoundStreamBlockMP3 *)streamBlock)->seek = seekSamples;
        }

        UInt32 frameRangeCount = m_frameRangeCount;
        [self _readMP3FramesFromParser:parser];
        streamBlock->frameRangeIndex = frameRangeCount;
    }

    return index;
}


- (SwiffSoundStreamBlock *) streamBlockAtIndex:(NSUInteger)index
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
            streamBlockCount   = m_streamBlockCount,
            data               = m_data,
            sampleCount        = m_sampleCount,
            frameRangeCount    = m_frameRangeCount;

@end
