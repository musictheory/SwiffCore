/*
    SwiffSoundPlayer.m
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
#import "SwiffSoundPlayer.h"

#import "SwiffFrame.h"
#import "SwiffMovie.h"
#import "SwiffSoundEvent.h"
#import "SwiffSoundDefinition.h"
#import "SwiffSoundStreamBlock.h"
#import "SwiffUtils.h"

#import <AudioToolbox/AudioToolbox.h>


#define kBytesPerAudioBuffer  (1024 * 4)
#define kNumberOfAudioBuffers 2
#define kMaxPacketsPerAudioBuffer 32


@interface SwiffSoundChannel : NSObject {
@private
    AudioQueueRef         m_queue;
    AudioQueueBufferRef   m_buffer[kNumberOfAudioBuffers];
    AudioStreamPacketDescription m_packetDescription[kNumberOfAudioBuffers][kMaxPacketsPerAudioBuffer];
    SwiffSoundEvent      *m_event;
    SwiffSoundDefinition *m_definition;
    UInt32                m_frameIndex;
}

- (id) initWithEvent:(SwiffSoundEvent *)event definition:(SwiffSoundDefinition *)definition;

- (void) stop;

@property (nonatomic, retain, readonly) SwiffSoundEvent *event;
@property (nonatomic, retain, readonly) SwiffSoundDefinition *definition;

@end


@interface SwiffSoundPlayer ()
- (void) _channelDidReachEnd:(SwiffSoundChannel *)channel;
@end


static void sFillASBDForSoundDefinition(AudioStreamBasicDescription *asbd, SwiffSoundDefinition *definition)
{
    UInt32 formatID        = 0;
    UInt32 formatFlags     = 0;
    UInt32 bytesPerPacket  = 0;
    UInt32 framesPerPacket = 0;
    UInt32 bytesPerFrame   = 0;

    SwiffSoundFormat format = [definition format];
    
    if ((format == SwiffSoundFormatUncompressedNativeEndian) || (format == SwiffSoundFormatUncompressedLittleEndian)) {
        formatID    = kAudioFormatLinearPCM;
        formatFlags = kAudioFormatFlagsCanonical;

#if TARGET_RT_BIG_ENDIAN
        if ([definition format] == SwiffSoundFormatUncompressedLittleEndian) {
            formatFlags &= ~kAudioFormatFlagIsBigEndian;
        }
#endif
        bytesPerPacket  = 0; //!i: fill out
        bytesPerFrame   = 0; //!i: fill out
        framesPerPacket = 0; //!i: fill out

    } else if (format == SwiffSoundFormatMP3) {
        formatID = kAudioFormatMPEGLayer3;
    }

    asbd->mSampleRate       = [definition sampleRate];
    asbd->mFormatID         = formatID;
    asbd->mFormatFlags      = formatFlags;
    asbd->mBytesPerPacket   = bytesPerPacket;
    asbd->mFramesPerPacket  = framesPerPacket;
    asbd->mBytesPerFrame    = bytesPerFrame;
    asbd->mChannelsPerFrame = [definition isStereo] ? 2 : 1;
    asbd->mBitsPerChannel   = [definition bitsPerChannel];
    asbd->mReserved         = 0;
}


@implementation SwiffSoundChannel

static void sAudioQueueCallback(void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer)
{
    SwiffSoundChannel    *channel    = (SwiffSoundChannel *)inUserData;
    SwiffSoundDefinition *definition = channel->m_definition;
    
    AudioStreamPacketDescription *aspd = inBuffer->mUserData;
    
    CFIndex firstOffset   = kCFNotFound;
    CFIndex bytesWritten  = 0;
    UInt32  framesWritten = 0;
    UInt32  frameIndex    = channel->m_frameIndex;

    while (framesWritten < kMaxPacketsPerAudioBuffer) {
        CFIndex offset = SwiffSoundDefinitionGetOffsetForFrame(definition, frameIndex);
        if (offset == kCFNotFound) break;

        if (firstOffset == kCFNotFound) {
            firstOffset = offset;
        }
        
        CFIndex length = SwiffSoundDefinitionGetLengthForFrame(definition, frameIndex);
        if ((bytesWritten + length) < inBuffer->mAudioDataBytesCapacity) {
            aspd[framesWritten].mStartOffset = bytesWritten;
            aspd[framesWritten].mDataByteSize = length;
            aspd[framesWritten].mVariableFramesInPacket = 0;

            bytesWritten += length;
            framesWritten++;
            frameIndex++;

        } else {
            break;
        }
    }

    if (bytesWritten > 0) {
        CFDataRef data = SwiffSoundDefinitionGetData(definition);
        CFDataGetBytes(data, CFRangeMake(firstOffset, bytesWritten), inBuffer->mAudioData);

        inBuffer->mAudioDataByteSize = bytesWritten;

        OSStatus err = AudioQueueEnqueueBuffer(inAQ, inBuffer, framesWritten, aspd);
        if (err != noErr) {
            SwiffWarn(@"Sound", @"AudioQueueEnqueueBuffer() returned %d (0x%x)", err, err);
        }
    }

    channel->m_frameIndex = frameIndex; 
}


static void sAudioQueuePropertyCallback(void *inUserData, AudioQueueRef inAQ, AudioQueuePropertyID inID)
{
    SwiffSoundChannel *channel = (SwiffSoundChannel *)inUserData;

    if (inID == kAudioQueueProperty_IsRunning) {
        UInt32 isRunning = 0;
        UInt32 isRunningSize = sizeof(isRunning);

        AudioQueueGetProperty(inAQ, kAudioQueueProperty_IsRunning, &isRunning, &isRunningSize);

        if (!isRunning) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[SwiffSoundPlayer sharedInstance] _channelDidReachEnd:channel];
            });
        }
    }
}


- (id) _initWithEvent:(SwiffSoundEvent *)event definition:(SwiffSoundDefinition *)definition streamBlock:(SwiffSoundStreamBlock *)streamBlock
{
    if ((self = [super init])) {
        m_event      = [event retain];
        m_definition = [definition retain];
        m_frameIndex = [streamBlock frameOffset];

        OSStatus err = noErr;
        
        AudioStreamBasicDescription inFormat;
        sFillASBDForSoundDefinition(&inFormat, definition);

        if (err == noErr) {
            err = AudioQueueNewOutput(&inFormat, sAudioQueueCallback, self, CFRunLoopGetMain(), kCFRunLoopCommonModes, 0, &m_queue);
            if (err != noErr) {
                SwiffWarn(@"Sound", @"AudioQueueNewOutput() returned 0x%x", err);
            }
        }

        if (err == noErr) {
            err = AudioQueueAddPropertyListener(m_queue, kAudioQueueProperty_IsRunning, sAudioQueuePropertyCallback, self);
            if (err != noErr) {
                SwiffWarn(@"Sound", @"AudioQueueAddPropertyListener() returned 0x%x", err);
            }
        }

        if (err == noErr) {
            NSUInteger i;
            for (i = 0; i < kNumberOfAudioBuffers; i++) {
                err = AudioQueueAllocateBuffer(m_queue, kBytesPerAudioBuffer, &m_buffer[i]);
                
                m_buffer[i]->mUserData = (void *)&m_packetDescription[i][0];
                
                if (err != noErr) {
                    SwiffWarn(@"Sound", @"AudioQueueAllocateBuffer() returned 0x%x", err);
                } else {
                    sAudioQueueCallback(self, m_queue, m_buffer[i]);
                }
            }
        }

        if (err == noErr) {
            err = AudioQueueStart(m_queue, NULL);
            if (err != noErr) {
                SwiffWarn(@"Sound", @"AudioQueueStart() returned 0x%x", err);
            }
        }

        if (err != noErr) {
            [self release];
            return nil;
        }
    }
    
    return self;
}


- (id) initWithEvent:(SwiffSoundEvent *)event definition:(SwiffSoundDefinition *)definition
{
    return [self _initWithEvent:event definition:definition streamBlock:nil];
}


- (id) initWithDefinition:(SwiffSoundDefinition *)definition streamBlock:(SwiffSoundStreamBlock *)streamBlock
{
    return [self _initWithEvent:nil definition:definition streamBlock:streamBlock];
}


- (void) dealloc
{
    if (m_queue) {
        AudioQueueDispose(m_queue, false);
        m_queue = NULL;
    }

    [m_event      release];  m_event      = nil;
    [m_definition release];  m_definition = nil;

    [super dealloc];
}


- (void) stop
{
    AudioQueuePause(m_queue);
}


@synthesize event      = m_event,
            definition = m_definition;

@end



@implementation SwiffSoundPlayer

+ (SwiffSoundPlayer *) sharedInstance
{
    static id sharedInstance = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}


#pragma mark -
#pragma mark Private Methods

- (void) _startEventSound:(SwiffSoundEvent *)event
{
    SwiffSoundChannel *channel = [[SwiffSoundChannel alloc] initWithEvent:event definition:[event definition]];

    NSNumber       *libraryID = [[NSNumber alloc] initWithUnsignedShort:[event libraryID]];
    NSMutableArray *channels  = [m_libraryIDTChannelArrayMap objectForKey:libraryID];

    if (!channels) {
        if (!m_libraryIDTChannelArrayMap) {
            m_libraryIDTChannelArrayMap = [[NSMutableDictionary alloc] init];
        }
    
        channels = [[NSMutableArray alloc] init];
        [m_libraryIDTChannelArrayMap setObject:channels forKey:libraryID];
        [channels release];
    }
    
    if (channel) {
        [channels addObject:channel];
    }

    [channel release];
    [libraryID release];
}


- (void) _stopEventSound:(SwiffSoundEvent *)event
{
    NSNumber       *libraryID = [[NSNumber alloc] initWithUnsignedShort:[event libraryID]];
    NSMutableArray *channels  = [m_libraryIDTChannelArrayMap objectForKey:libraryID];

    [channels makeObjectsPerformSelector:@selector(stop)];
    [m_libraryIDTChannelArrayMap removeObjectForKey:libraryID]; 

    [libraryID release];
    
    if ([m_libraryIDTChannelArrayMap count] == 0) {
        [m_libraryIDTChannelArrayMap release];
        m_libraryIDTChannelArrayMap = nil;
    }
}


- (void) _stopAllEventSounds
{
    for (NSArray *channels in [m_libraryIDTChannelArrayMap allValues]) {
        [channels makeObjectsPerformSelector:@selector(stop)];
    }

    [m_libraryIDTChannelArrayMap release];
    m_libraryIDTChannelArrayMap = nil;
}


- (void) _channelDidReachEnd:(SwiffSoundChannel *)channel
{
    if ([channel event]) {
        [self _stopEventSound:[channel event]];
    } else {
        [self stopStream];
    }
}


#pragma mark -
#pragma mark Public Methods

- (void) processMovie:(SwiffMovie *)movie frame:(SwiffFrame *)frame
{
    for (SwiffSoundEvent *event in [frame soundEvents]) {
        NSNumber       *libraryID = [[NSNumber alloc] initWithUnsignedShort:[event libraryID]];
        NSMutableArray *channels  = [m_libraryIDTChannelArrayMap objectForKey:libraryID];

        if ([event shouldStop]) {
            [self _stopEventSound:event];
        } else if (![channels count] || [event allowsMultiple]) {
            [self _startEventSound:event];
        }
        
        [libraryID release];
    }
    
    SwiffSoundDefinition *streamSound = [frame streamSound];
    if (streamSound) {
        if ([m_currentStreamChannel definition] != streamSound) {
            [self stopStream];
            m_currentStreamChannel = [[SwiffSoundChannel alloc] initWithDefinition:streamSound streamBlock:[frame streamBlock]];
        }
    }
}


- (void) stopStream
{
    [m_currentStreamChannel stop];
    [m_currentStreamChannel release];
    m_currentStreamChannel = nil;
}


- (void) stopAllSounds
{
    [self stopStream];
    [self _stopAllEventSounds];
}


#pragma mark -
#pragma mark Accessors

- (BOOL) isPlaying
{
    return (m_libraryIDTChannelArrayMap != nil) || [self isStreaming];
}

- (BOOL) isStreaming
{
    return (m_currentStreamChannel != nil);
}   

@end
