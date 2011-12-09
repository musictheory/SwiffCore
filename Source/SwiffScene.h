/*
    SwiffScene.h
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

@class SwiffFrame, SwiffMovie;


@interface SwiffScene : NSObject {
@private
    SwiffMovie   *m_movie;
    NSString     *m_name;
    NSArray      *m_frames;
    NSDictionary *m_labelToFrameMap;
    NSUInteger    m_indexInMovie;
}

- (id) initWithMovie:(SwiffMovie *)movie name:(NSString *)name indexInMovie:(NSUInteger)indexInMovie frames:(NSArray *)frames;

- (void) clearWeakReferences;

- (SwiffFrame *) frameWithLabel:(NSString *)label;
- (SwiffFrame *) firstFrame;

- (SwiffFrame *) frameAtIndex1:(NSUInteger)index1;
- (NSUInteger) index1OfFrame:(SwiffFrame *)frame;

- (SwiffFrame *) frameAtIndex:(NSUInteger)index;
- (NSUInteger) indexOfFrame:(SwiffFrame *)frame;

@property (nonatomic, assign, readonly) NSUInteger indexInMovie;
@property (nonatomic, assign, readonly) NSUInteger index1InMovie;

@property (nonatomic, assign, readonly) SwiffMovie *movie;
@property (nonatomic, assign, readonly) NSString *name;
@property (nonatomic, assign, readonly) NSArray *frames;

@end
