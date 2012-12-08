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
@end


@implementation SwiffSoundDefinition {
    NSMutableData *_data;
    NSUInteger    *_frames;
    NSInteger      _framesCount;
    NSInteger      _framesCapacity;
    UInt8          _rawSampleRate;
    SInt16         _latencySeek;
    UInt16         _averageSampleCount;
}

@synthesize movie     = _movie,
            libraryID = _libraryID;


- (id) initWithParser:(SwiffParser *)parser movie:(SwiffMovie *)movie
{
    if ((self = [super init])) {
        SwiffTag tag = SwiffParserGetCurrentTag(parser);

        if (tag == SwiffTagDefineSound) {
            SwiffParserReadUInt16(parser, &_libraryID);

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
        
        _movie          = movie;
        _format         = soundFormat;
        _rawSampleRate  = soundRate;
        _bitsPerChannel = (soundSize == 1) ? 16 : 8;
        _stereo         = (soundType == 1) ? YES : NO;
        _data           = [[NSMutableData alloc] init];

        if (tag == SwiffTagDefineSound) {
            SwiffParserReadUInt32(parser, &_sampleCount);

            if (soundFormat == SwiffSoundFormatMP3) {
                SwiffParserReadSInt16(parser, &_latencySeek);
                [self _readMP3FramesFromParser:parser];
            }

        } else if (tag == SwiffTagSoundStreamHead) {
            SwiffParserReadUInt16(parser, &_averageSampleCount);
            
            if (soundFormat == SwiffSoundFormatMP3) {
                SwiffParserReadSInt16(parser, &_latencySeek);
            }
        }
    }
    
    return self;
}


- (void) dealloc
{
    free(_frames);
    _frames = NULL;
}


- (void) clearWeakReferences
{
    _movie = nil;
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
            SwiffWarn(@"Sound", @"SwiffMPEGReadHeader() returned %ld", (long)error);
        }

        if (_framesCount == _framesCapacity) {
            _framesCapacity = _framesCapacity ? _framesCapacity * 2 : 256;
            _frames = realloc(_frames, sizeof(NSUInteger) * _framesCapacity);
        }

        _frames[_framesCount] = [_data length];
        _framesCount++;
        
        [_data appendBytes:frameStart length:header.frameSize];

        SwiffParserAdvance(parser, header.frameSize);
    }
}


#pragma mark -
#pragma mark Public Methods

CFDataRef SwiffSoundDefinitionGetData(SwiffSoundDefinition *self)
{
    return (__bridge CFDataRef)self->_data;
}


extern CFIndex SwiffSoundDefinitionGetOffsetForFrame(SwiffSoundDefinition *self, CFIndex frame)
{
    if ((frame >= 0) && (frame < self->_framesCount)) {
        return self->_frames[frame];
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

    if ([self isStreaming]) {
        result = [[SwiffSoundStreamBlock alloc] init];
        
        [result setFrameOffset:_framesCount];
        
        if (_format == SwiffSoundFormatMP3) {
            UInt16 sampleCount = 0;
            SwiffParserReadUInt16(parser, &sampleCount);
            [result setSampleCount:sampleCount];

            _sampleCount += sampleCount;

            SInt16 seekSamples = 0;
            SwiffParserReadSInt16(parser, &seekSamples);
            [result setSampleSeek:seekSamples];
        }

        [self _readMP3FramesFromParser:parser];
    }

    return result;
}


#pragma mark -
#pragma mark Accessors

- (CGRect) bounds       { return CGRectZero; }
- (CGRect) renderBounds { return CGRectZero; }


- (float) sampleRate
{
    if      (_rawSampleRate == 0)  return  5512.5f;
    else if (_rawSampleRate == 1)  return 11025.0f;
    else if (_rawSampleRate == 2)  return 22050.0f;
    else                           return 44100.0f;
}

- (BOOL)      isStreaming        { return _libraryID == 0;     }
- (NSInteger) averageSampleCount { return _averageSampleCount; }
- (NSInteger) latencySeek        { return _latencySeek;        }

@end
