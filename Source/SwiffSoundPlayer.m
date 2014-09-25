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


@interface SwiffSoundChannel : NSObject

- (id) initWithEvent:(SwiffSoundEvent *)event definition:(SwiffSoundDefinition *)definition;

- (OSStatus) _start;
- (void) stop;

@property (nonatomic, strong, readonly) SwiffSoundEvent *event;
@property (nonatomic, strong, readonly) SwiffSoundDefinition *definition;

@end


@interface SwiffSoundPlayer ()
- (void) _channelDidReachEnd:(SwiffSoundChannel *)channel;
@end

static NSString *sGetStringForAudioError(SInt32 err)
{
    NSMutableString *result = [NSMutableString string];
    
    [result appendFormat:@"0x%lx, %ld", (long)err, (long)err];
    
    #define IsPrintable(C) ((C) >= 0x20 && (C) < 0x80)
    UInt32 fourcc = ntohl(*((UInt32 *)&err));
    UInt8 *c = (UInt8 *)&fourcc;
    if (IsPrintable(c[0]) && IsPrintable(c[1]) && IsPrintable(c[2]) && IsPrintable(c[3])) {
        [result appendFormat:@", '%c%c%c%c'", c[0], c[1], c[2], c[3]];
    }
    
    return result;
}


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
        formatFlags = (kAudioFormatFlagIsSignedInteger | kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked);

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


@implementation SwiffSoundChannel {
    AudioQueueRef         _queue;
    AudioQueueBufferRef   _buffer[kNumberOfAudioBuffers];
    AudioStreamPacketDescription _packetDescription[kNumberOfAudioBuffers][kMaxPacketsPerAudioBuffer];
    CFIndex               _frameIndex;
    BOOL                  _isStopping;
}

@synthesize definition = _definition;


static void sAudioQueueCallback(void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer)
{
    SwiffSoundChannel    *channel    = (__bridge SwiffSoundChannel *)inUserData;
    SwiffSoundDefinition *definition = channel->_definition;

    AudioStreamPacketDescription *aspd = inBuffer->mUserData;
    
    CFIndex firstOffset   = kCFNotFound;
    CFIndex bytesWritten  = 0;
    UInt32  framesWritten = 0;
    CFIndex frameIndex    = channel->_frameIndex;

    while (framesWritten < kMaxPacketsPerAudioBuffer) {
        CFIndex offset = SwiffSoundDefinitionGetOffsetForFrame(definition, frameIndex);
        if (offset == kCFNotFound) break;

        if (firstOffset == kCFNotFound) {
            firstOffset = offset;
        }
        
        CFIndex length = SwiffSoundDefinitionGetLengthForFrame(definition, frameIndex);
        if ((bytesWritten + length) < inBuffer->mAudioDataBytesCapacity) {
            aspd[framesWritten].mStartOffset = bytesWritten;
            aspd[framesWritten].mDataByteSize = (UInt32)length;
            aspd[framesWritten].mVariableFramesInPacket = 0;

            bytesWritten += length;
            framesWritten++;
            frameIndex++;

        } else {
            break;
        }
    }

    if (!channel->_isStopping) {
        if (bytesWritten > 0) {
            CFDataRef data = SwiffSoundDefinitionGetData(definition);
            CFDataGetBytes(data, CFRangeMake(firstOffset, bytesWritten), inBuffer->mAudioData);

            inBuffer->mAudioDataByteSize = (UInt32)bytesWritten;

            OSStatus err = AudioQueueEnqueueBuffer(inAQ, inBuffer, framesWritten, aspd);
            if (err != noErr) {
                SwiffWarn(@"Sound", @"AudioQueueEnqueueBuffer() returned %@", sGetStringForAudioError(err));
            }
        } else {
            AudioQueueStop(inAQ, false);
        }
    }

    channel->_frameIndex = frameIndex; 
}


static void sAudioQueuePropertyCallback(void *inUserData, AudioQueueRef inAQ, AudioQueuePropertyID inID)
{
    SwiffSoundChannel *channel = (__bridge SwiffSoundChannel *)inUserData;

    if (inID == kAudioQueueProperty_IsRunning) {
        UInt32 isRunning = 0;
        UInt32 isRunningSize = sizeof(isRunning);

        AudioQueueGetProperty(inAQ, kAudioQueueProperty_IsRunning, &isRunning, &isRunningSize);

        if (!isRunning) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[SwiffSoundPlayer sharedInstance] _channelDidReachEnd:channel];
            });
        }

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
    } else if (inID == kAudioQueueProperty_ConverterError) {
        SInt32 converterError = 0;
        UInt32 converterErrorSize = sizeof(converterError);

        AudioQueueGetProperty(inAQ, kAudioQueueProperty_IsRunning, &converterError, &converterErrorSize);

        dispatch_async(dispatch_get_main_queue(), ^{
            SwiffWarn(@"Sound", @"%@ reported converter error: %@", inAQ, sGetStringForAudioError(converterError));
        });
#endif
    }
}


- (id) _initWithEvent:(SwiffSoundEvent *)event definition:(SwiffSoundDefinition *)definition streamBlock:(SwiffSoundStreamBlock *)streamBlock
{
    if ((self = [super init])) {
        _event      = event;
        _definition = definition;
        _frameIndex = [streamBlock frameOffset];

        OSStatus err = noErr;
        
        AudioStreamBasicDescription inFormat;
        sFillASBDForSoundDefinition(&inFormat, definition);

        if (err == noErr) {
            err = AudioQueueNewOutput(&inFormat, sAudioQueueCallback, (__bridge void *)(self), CFRunLoopGetMain(), kCFRunLoopCommonModes, 0, &_queue);
            if (err != noErr) {
                SwiffWarn(@"Sound", @"AudioQueueNewOutput() returned %@", sGetStringForAudioError(err));
            }
        }

        if (err == noErr) {
            err = AudioQueueAddPropertyListener(_queue, kAudioQueueProperty_IsRunning, sAudioQueuePropertyCallback, (__bridge void *)(self));
            if (err != noErr) {
                SwiffWarn(@"Sound", @"AudioQueueAddPropertyListener() for kAudioQueueProperty_IsRunning returned %@", sGetStringForAudioError(err));
            }
        }

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
        if (err == noErr) {
            err = AudioQueueAddPropertyListener(_queue, kAudioQueueProperty_ConverterError, sAudioQueuePropertyCallback, (__bridge void *)(self));
            if (err != noErr) {
                SwiffWarn(@"Sound", @"AudioQueueAddPropertyListener() for kAudioQueueProperty_ConverterError returned %@", sGetStringForAudioError(err));
            }
        }
#endif

        if (err == noErr) {
            err = [self _start];
        }

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
        if (err == kAudioConverterErr_HardwareInUse) {
            UInt32 policy = kAudioQueueHardwareCodecPolicy_PreferSoftware;
            err = AudioQueueSetProperty(_queue, kAudioQueueProperty_HardwareCodecPolicy, &policy, sizeof(policy));

            SwiffWarn(@"Sound", @"Falling back to software codec.");
            
            if (err == noErr) {
                err = [self _start];
            } else {
                SwiffWarn(@"Sound", @"AudioQueueSetProperty() for kAudioQueueProperty_HardwareCodecPolicy returned %@", sGetStringForAudioError(err));
            }
        }
#endif
        
        if (err != noErr) {
            SwiffWarn(@"Sound", @"err is %@, returning nil for SoundChannelPlayer", sGetStringForAudioError(err));
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
    if (_queue) {
        AudioQueueDispose(_queue, false);
        _queue = NULL;
    }
}


- (OSStatus) _start
{
    OSStatus err = noErr;

    _frameIndex = 0;

    NSUInteger i;
    for (i = 0; i < kNumberOfAudioBuffers; i++) {
        err = AudioQueueAllocateBuffer(_queue, kBytesPerAudioBuffer, &_buffer[i]);
        
        _buffer[i]->mUserData = (void *)&_packetDescription[i][0];
        
        if (err != noErr) {
            SwiffWarn(@"Sound", @"AudioQueueAllocateBuffer() returned %@", sGetStringForAudioError(err));
        } else {
            sAudioQueueCallback((__bridge void *)(self), _queue, _buffer[i]);
        }
    }

    if (err == noErr) {
        err = AudioQueueStart(_queue, NULL);
    }

    return err;
}


- (void) stop
{
    _isStopping = YES;
    AudioQueueStop(_queue, true);
}


@end



@implementation SwiffSoundPlayer {
    NSMutableArray      *_eventChannels;
    SwiffSoundChannel   *_currentStreamChannel;
}


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

- (NSArray *) _copyCurrentChannelsForEvent:(SwiffSoundEvent *)event
{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    id<SwiffDefinition> definition = [event definition];

    for (SwiffSoundChannel *channel in _eventChannels) {
        if ([channel definition] == definition) {
            [result addObject:channel];
        }
    }
    return result;
}


- (void) _channelDidReachEnd:(SwiffSoundChannel *)channel
{
    if ([channel event]) {
        [channel stop];
        [_eventChannels removeObject:channel];
    } else {
        [self stopStream];
    }
}


#pragma mark -
#pragma mark Public Methods

- (void) processMovie:(SwiffMovie *)movie frame:(SwiffFrame *)frame
{
    for (SwiffSoundEvent *event in [frame soundEvents]) {
        NSArray *channels  = [self _copyCurrentChannelsForEvent:event];
        
        if ([event shouldStop]) {
            [channels makeObjectsPerformSelector:@selector(stop)];
            [_eventChannels removeObjectsInArray:channels];

        } else if (![channels count] || [event allowsMultiple]) {
            if (!_eventChannels) {
                _eventChannels = [[NSMutableArray alloc] init];
            }

            SwiffSoundChannel *channel = [[SwiffSoundChannel alloc] initWithEvent:event definition:[event definition]];
            if (channel) {
                [_eventChannels addObject:channel];
            }
        }
    }
    
    SwiffSoundDefinition *streamSound = [frame streamSound];
    if (streamSound) {
        if ([_currentStreamChannel definition] != streamSound) {
            [self stopStream];
            _currentStreamChannel = [[SwiffSoundChannel alloc] initWithDefinition:streamSound streamBlock:[frame streamBlock]];
        }
    }
}


- (void) stopStream
{
    [_currentStreamChannel stop];
    _currentStreamChannel = nil;
}


- (void) stopAllSoundsForMovie:(SwiffMovie *)movie
{
    NSMutableArray *channelsToRemove = [[NSMutableArray alloc] init];

    for (SwiffSoundChannel *channel in _eventChannels) {
        if ([[channel definition] movie] == movie) {
            [channelsToRemove addObject:channel];
        }
    }

    [channelsToRemove makeObjectsPerformSelector:@selector(stop)];
    [_eventChannels removeObjectsInArray:channelsToRemove];

    if ([[_currentStreamChannel definition] movie] == movie) {
        [self stopStream];
    }
}


- (void) stopAllSounds
{
    [self stopStream];

    [_eventChannels makeObjectsPerformSelector:@selector(stop)];
    [_eventChannels removeAllObjects];
}


#pragma mark -
#pragma mark Accessors

- (BOOL) isPlaying
{
    return ([_eventChannels count] > 0) || [self isStreaming];
}


- (BOOL) isStreaming
{
    return (_currentStreamChannel != nil);
}   

@end
