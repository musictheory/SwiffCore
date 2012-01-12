/*
    SwiffShape.h
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

#import <SwiffImport.h>
#import <SwiffDefinition.h>
#import <SwiffParser.h>

@class SwiffMovie;


@interface SwiffShapeDefinition : NSObject <SwiffDefinition> {
@private
    SwiffMovie *m_movie;
    UInt16      m_libraryID;
    CFArrayRef  m_groups;
    NSArray    *m_fillStyles;
    NSArray    *m_lineStyles;
    NSArray    *m_paths;
    
    CGRect      m_bounds;
    CGRect      m_renderBounds;
    CGRect      m_edgeBounds;

    BOOL        m_usesFillWindingRule;
    BOOL        m_usesNonScalingStrokes;
    BOOL        m_usesScalingStrokes;
    BOOL        m_hasEdgeBounds;
}

- (id) initWithParser:(SwiffParser *)parser movie:(SwiffMovie *)movie;

@property (nonatomic, assign, readonly) UInt16 libraryID;
@property (nonatomic, assign, readonly) CGRect bounds;
@property (nonatomic, assign, readonly) CGRect edgeBounds;

@property (nonatomic, retain, readonly) NSArray *paths;

@property (nonatomic, assign, readonly) BOOL usesFillWindingRule;
@property (nonatomic, assign, readonly) BOOL usesNonScalingStrokes;
@property (nonatomic, assign, readonly) BOOL usesScalingStrokes;
@property (nonatomic, assign, readonly) BOOL hasEdgeBounds;

@end
