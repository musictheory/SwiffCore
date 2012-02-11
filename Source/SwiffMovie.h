/*
    SwiffMovie.h
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
#import <SwiffTypes.h>
#import <SwiffSpriteDefinition.h>

@class SwiffBitmapDefinition, SwiffDynamicTextDefinition, SwiffFontDefinition,
       SwiffShapeDefinition, SwiffStaticTextDefinition, SwiffSoundDefinition,
       SwiffSparseArray;

@protocol SwiffMovieDecoder;


@interface SwiffMovie : SwiffSpriteDefinition

- (id) initWithData:(NSData *)data;

- (id<SwiffDefinition>) definitionWithLibraryID:(UInt16)libraryID;

- (SwiffBitmapDefinition      *) bitmapDefinitionWithLibraryID:(UInt16)libraryID;
- (SwiffDynamicTextDefinition *) dynamicTextDefinitionWithLibraryID:(UInt16)libraryID;
- (SwiffFontDefinition        *) fontDefinitionWithLibraryID:(UInt16)libraryID;
- (SwiffShapeDefinition       *) shapeDefinitionWithLibraryID:(UInt16)libraryID;
- (SwiffSoundDefinition       *) soundDefinitionWithLibraryID:(UInt16)libraryID;
- (SwiffSpriteDefinition      *) spriteDefinitionWithLibraryID:(UInt16)libraryID;
- (SwiffStaticTextDefinition  *) staticTextDefinitionWithLibraryID:(UInt16)libraryID;

@property (nonatomic, assign) NSInteger version;
@property (nonatomic, assign) CGRect stageRect;

@property (nonatomic, assign) CGFloat frameRate;

@property (nonatomic, assign) SwiffColor backgroundColor;
@property (nonatomic, assign, readonly) SwiffColor *backgroundColorPointer;

@end

extern id<SwiffDefinition> SwiffMovieGetDefinition(SwiffMovie *movie, UInt16 libraryID);
