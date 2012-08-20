/*
    SwiffSoundEvent.m
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

#import "SwiffSoundEvent.h"


@implementation SwiffSoundEvent {
    SwiffSoundEnvelope   *_envelopes;
}


- (id) initWithParser:(SwiffParser *)parser
{
    SwiffTag  tag       = SwiffParserGetCurrentTag(parser);
    NSInteger version   = SwiffParserGetCurrentTagVersion(parser);
    NSString *className = nil;
    UInt16    libraryID = 0;

    // SwiffSoundEvent can be initialized for StartSound, StartSound2, or DefineButtonSound
    if (tag == SwiffTagStartSound) {
        if (version == 1) {
            SwiffParserReadUInt16(parser, &libraryID);
        } else {
            SwiffParserReadString(parser, &className);
        }

    } else if (tag == SwiffTagDefineButtonSound) {
        SwiffParserReadUInt16(parser, &libraryID);

        if (_libraryID == 0) {
            return nil;
        }
    }

    if ((self = [super init])) {
        UInt32 reserved, syncStop, syncNoMultiple, hasEnvelope, hasLoops, hasOutPoint, hasInPoint;
        
        SwiffParserReadUBits(parser, 2, &reserved);
        SwiffParserReadUBits(parser, 1, &syncStop);
        SwiffParserReadUBits(parser, 1, &syncNoMultiple);
        SwiffParserReadUBits(parser, 1, &hasEnvelope);
        SwiffParserReadUBits(parser, 1, &hasLoops);
        SwiffParserReadUBits(parser, 1, &hasOutPoint);
        SwiffParserReadUBits(parser, 1, &hasInPoint);

        _libraryID      = libraryID;
        _className      = className;
        _shouldStop     = syncStop;
        _allowsMultiple = !syncNoMultiple;

        if (hasInPoint) {
            UInt32 inPoint;
            SwiffParserReadUInt32(parser, &inPoint);
            _inPoint = inPoint;
        }
        
        if (hasOutPoint) {
            UInt32 outPoint;
            SwiffParserReadUInt32(parser, &outPoint);
            _outPoint = outPoint;
        }
        
        if (hasLoops) {
            UInt16 loops;
            SwiffParserReadUInt16(parser, &loops);
            _loopCount = loops;
        }

        if (hasEnvelope) {
            UInt8 envPoints = 0;
            SwiffParserReadUInt8(parser, &envPoints);
            
            if (envPoints) {
                _envelopeCount = envPoints;
                SwiffSoundEnvelope *envelopes = (SwiffSoundEnvelope *)malloc(sizeof(SwiffSoundEnvelope) * envPoints);
                
                for (UInt8 i = 0; i < envPoints; i++) {
                    UInt32 position;
                    UInt16 leftLevel;
                    UInt16 rightLevel;

                    SwiffParserReadUInt32(parser, &position);
                    SwiffParserReadUInt16(parser, &leftLevel);
                    SwiffParserReadUInt16(parser, &rightLevel);

                    envelopes[i].position   = position;
                    envelopes[i].leftLevel  = leftLevel  / 32768.0;
                    envelopes[i].rightLevel = rightLevel / 32768.0;
                }

                _envelopes = envelopes;
            }
        }
    }
    
    return self;
}


- (void) dealloc
{
    free(_envelopes);
    _envelopes = NULL;
}


- (SwiffSoundEnvelope) envelopeAtIndex:(NSInteger)index
{
    return _envelopes[index];
}


- (void) getLeftLevel:(float *)outLeftLevel rightLevel:(float *)outRightLevel atPosition:(UInt32)position
{
    float leftLevel  = 1.0;
    float rightLevel = 1.0;
    NSInteger last = _envelopeCount - 1;

    if (_envelopeCount == 0) {
        leftLevel  = 1.0;
        rightLevel = 1.0;

    } else if (_envelopeCount == 1 || (position <= _envelopes[0].position)) {
        leftLevel  = _envelopes[0].leftLevel;
        rightLevel = _envelopes[0].rightLevel;

    } else if (position >= _envelopes[last].position) {
        leftLevel  = _envelopes[last].leftLevel;
        rightLevel = _envelopes[last].rightLevel;
        
    } else {
        for (NSUInteger i = 1; i <= last; i++) {
            SwiffSoundEnvelope start = _envelopes[i - 1];
            SwiffSoundEnvelope end   = _envelopes[i];
            
            if ((position > start.position) && (position <= end.position)) {
                CGFloat value = (position - start.position) / ((end.position - start.position) * 1.0);

                leftLevel  = start.leftLevel  + (value * (end.leftLevel  - start.leftLevel));
                rightLevel = start.rightLevel + (value * (end.rightLevel - start.rightLevel));

                break;
            }
        }
    }

    if (outLeftLevel)  *outLeftLevel  = leftLevel;
    if (outRightLevel) *outRightLevel = rightLevel;
}

@end
