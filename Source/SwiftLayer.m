/*
    SwiftLayer.m
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

#import "SwiftLayer.h"


@implementation SwiftLayer

- (id) initWithMovie:(SwiftMovie *)movie;
{
    if ((self = [super init])) {
        m_movie = [movie retain];
        [self setMasksToBounds:YES];
    }
    
    return self;
}


- (void) dealloc
{
    [m_movie release];
    m_movie = nil;

    [m_currentFrame release];
    m_currentFrame = nil;
    
    [super dealloc];
}


#pragma mark -
#pragma mark CALayer Logic

- (id<CAAction>) actionForKey:(NSString *)event
{
    return nil;
}


- (id<CAAction>) actionForLayer:(CALayer *)layer forKey:(NSString *)event
{
    if (m_frameAnimationDuration > 0.0) {
        CABasicAnimation *basicAnimation = [CABasicAnimation animationWithKeyPath:event];
        
        [basicAnimation setDuration:m_frameAnimationDuration];
        [basicAnimation setCumulative:YES];

        return basicAnimation;

    } else {
        return (id)[NSNull null];
    }
}


#pragma mark -
#pragma mark Subclasses to Override

- (void) transitionToFrame:(SwiftFrame *)newFrame fromFrame:(SwiftFrame *)oldFrame
{
    // Subclasses to override
}


#pragma mark -
#pragma mark Accessors

- (void) setCurrentFrame:(SwiftFrame *)frame
{
    if (frame != m_currentFrame) {
        [self transitionToFrame:frame fromFrame:m_currentFrame];

        [m_currentFrame release];
        m_currentFrame = [frame retain];
    }
}

@synthesize movie                  = m_movie,
            currentFrame           = m_currentFrame,
            frameAnimationDuration = m_frameAnimationDuration;

@end
