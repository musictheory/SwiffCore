/*
    SwiffSoundDefinition.h
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
#import <SwiffBase.h>
#import <SwiffDefinition.h>
#import <SwiffParser.h>

@class SwiffMovie, SwiffSoundDefinition;


typedef struct _SwiffSoundStreamBlock {
    UInt32  frameRangeIndex;
} SwiffSoundStreamBlock;


typedef struct _SwiffSoundStreamBlockMP3 {
    UInt32  frameRangeIndex;
    UInt16  sampleCount;
    SInt16  seek;
} SwiffSoundStreamBlockMP3;


extern void SwiffSoundDefinitionFillBuffer(
    SwiffSoundDefinition *definition,
    UInt32 inFrameIndex, void *inBuffer, UInt32 inBufferCapacity,
    UInt32 *outBytesWritten, UInt32 *outFramesWritten
);

// C-based API, for audio callbacks
extern CFDataRef SwiffSoundDefinitionGetData(SwiffSoundDefinition *definition);
extern CFRange   SwiffSoundDefinitionGetFrameRangeAtIndex(SwiffSoundDefinition *definition, CFIndex index);


@interface SwiffSoundDefinition : NSObject <SwiffDefinition> {
@private
    SwiffMovie    *m_movie;
    NSMutableData *m_data;

    void          *m_streamBlockArray;
    NSUInteger     m_streamBlockCount;
    NSUInteger     m_streamBlockCapacity;

    NSRange       *m_frameRangeArray;
    NSUInteger     m_frameRangeCount;
    NSUInteger     m_frameRangeCapacity;

    UInt32         m_sampleCount;
    UInt16         m_averageSampleCount;
    UInt16         m_libraryID;
    SInt16         m_latencySeek;
    UInt8          m_format;
    UInt8          m_rawSampleRate;
    UInt8          m_bitsPerChannel;
    BOOL           m_stereo;
    BOOL           m_streaming;
}

- (id) initWithParser:(SwiffParser *)parser movie:(SwiffMovie *)movie;

@property (nonatomic, assign, readonly) SwiffSoundFormat format;

@property (nonatomic, readonly, retain) NSData *data;
@property (nonatomic, readonly, assign) UInt32  sampleCount;

@property (nonatomic, assign, readonly) NSInteger latencySeek;

@property (nonatomic, assign, readonly) float sampleRate;
@property (nonatomic, assign, readonly) UInt8 bitsPerChannel;
@property (nonatomic, assign, readonly, getter=isStereo) BOOL stereo;
@property (nonatomic, assign, readonly, getter=isStreaming) BOOL streaming;

- (NSRange) frameRangeAtIndex:(NSUInteger)index;
@property (nonatomic, assign, readonly) NSUInteger frameRangeCount;

// Only applicable for streaming

// Reads a SwiffSoundStreamBlock tag and adds an entry to the internal stream block array.  Returns the index
// of the added entry
- (NSUInteger) readSoundStreamBlockTagFromParser:(SwiffParser *)parser;

- (SwiffSoundStreamBlock *) streamBlockAtIndex:(NSUInteger)index;
@property (nonatomic, assign, readonly) NSUInteger streamBlockCount;

@property (nonatomic, assign, readonly) NSInteger averageSampleCount;

@end
