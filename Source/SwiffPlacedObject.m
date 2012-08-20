/*
    SwiffPlacedObject.m
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


#import "SwiffPlacedObject.h"
#import "SwiffMovie.h"
#import "SwiffUtils.h"

typedef struct SwiffPlacedObjectAdditionalStorage
{
    CFStringRef name;
    CFStringRef className;
    CFArrayRef  filters;
    CFStringRef layerID;
    SwiffColorTransform colorTransform;
    SwiffBlendMode blendMode;
    UInt16 clipDepth;
    UInt16 ratio;
    BOOL   hasColorTransform;
    BOOL   hidden;
    BOOL   wantsLayer;
    BOOL   placesImage;
    BOOL   cachesAsBitmap;
} SwiffPlacedObjectAdditionalStorage;

#define ADDITIONAL ((SwiffPlacedObjectAdditionalStorage *)_additional)
#define MAKE_ADDITIONAL { if (!_additional) _additional = calloc(1, sizeof(SwiffPlacedObjectAdditionalStorage)); }

SwiffPlacedObject *SwiffPlacedObjectCreate(SwiffMovie *movie, UInt16 libraryID, SwiffPlacedObject *existingPlacedObject)
{
    id<SwiffDefinition> definition = nil;
    SwiffPlacedObject *result = nil;
    Class cls = [SwiffPlacedObject class];

    if (libraryID) {
        definition = [movie definitionWithLibraryID:libraryID];

        if ([[definition class] respondsToSelector:@selector(placedObjectClass)]) {
            cls = [[definition class] placedObjectClass];
        }
    }

    if (existingPlacedObject) {
        if (libraryID == 0) cls = [existingPlacedObject class];
        result = existingPlacedObject ? [[cls alloc] initWithPlacedObject:existingPlacedObject] : nil;
    }

    if (!result) {
        result = [[cls alloc] init];
    }
    
    if (libraryID) {
        [result setLibraryID:libraryID];
        [result setupWithDefinition:definition];
    }
    
    return result;
}


@implementation SwiffPlacedObject


- (id) init
{
    if ((self = [super init])) {
        _affineTransform = CGAffineTransformIdentity;
    }

    return self;
}


- (id) initWithPlacedObject:(SwiffPlacedObject *)placedObject
{
    if ((self = [self init])) {
        _depth             = placedObject->_depth;
        _libraryID         = placedObject->_libraryID;
        _affineTransform   = placedObject->_affineTransform;

        if (placedObject->_additional) {
            _additional = malloc(sizeof(SwiffPlacedObjectAdditionalStorage));
            memcpy(_additional, placedObject->_additional, sizeof(SwiffPlacedObjectAdditionalStorage));
            
            SwiffPlacedObjectAdditionalStorage *other = placedObject->_additional;
            ADDITIONAL->name      = other->name      ? CFStringCreateCopy(NULL, other->name)      : NULL;
            ADDITIONAL->className = other->className ? CFStringCreateCopy(NULL, other->className) : NULL;
            ADDITIONAL->filters   = other->filters   ? CFArrayCreateCopy (NULL, other->filters)   : NULL;
            ADDITIONAL->layerID   = other->layerID   ? CFStringCreateCopy(NULL, other->layerID)   : NULL;
        }
    }
    
    return self;
}


- (void) dealloc
{
    if (_additional) {
        if (ADDITIONAL->name)      CFRelease(ADDITIONAL->name);
        if (ADDITIONAL->className) CFRelease(ADDITIONAL->className);
        if (ADDITIONAL->filters)   CFRelease(ADDITIONAL->filters);
        if (ADDITIONAL->layerID)   CFRelease(ADDITIONAL->layerID);

        free(_additional);
        _additional = NULL;
    }
}


#pragma mark -
#pragma mark Public Methods

- (void) setupWithDefinition:(id<SwiffDefinition>)definition
{
    // ABSTRACT
}


#pragma mark -
#pragma mark Accessors

- (BOOL) hasAffineTransform
{
    return !CGAffineTransformIsIdentity(_affineTransform);
}


- (CGAffineTransform *) affineTransformPointer
{
    return &_affineTransform;
}


- (void) setHidden:(BOOL)hidden
{
    MAKE_ADDITIONAL;
    ADDITIONAL->hidden = hidden;
}


- (BOOL) isHidden
{
    return _additional ? ADDITIONAL->hidden : NO;
}


- (void) setWantsLayer:(BOOL)wantsLayer
{
    MAKE_ADDITIONAL;
    ADDITIONAL->wantsLayer = wantsLayer;
}


- (BOOL) wantsLayer
{
    return _additional ? ADDITIONAL->wantsLayer : NO;
}


- (void) setLayerIdentifier:(NSString *)layerID
{
    if (layerID != [self layerIdentifier]) {
        MAKE_ADDITIONAL;
        if (ADDITIONAL->layerID) CFRelease(ADDITIONAL->layerID);
        ADDITIONAL->layerID = CFStringCreateCopy(NULL, (__bridge CFStringRef) layerID);
    }
}


- (NSString *) layerIdentifier
{
    return _additional ? (__bridge NSString *) ADDITIONAL->layerID : nil;
}


- (void) setPlacesImage:(BOOL)placesImage
{
    MAKE_ADDITIONAL;
    ADDITIONAL->placesImage = placesImage;
}


- (BOOL) placesImage
{
    return _additional ? ADDITIONAL->placesImage : NO;
}


- (void) setRatio:(CGFloat)ratio
{
    MAKE_ADDITIONAL;
    ADDITIONAL->ratio = SwiffRound(ratio * 65535.0);
}


- (CGFloat) ratio
{
    return _additional ? (ADDITIONAL->ratio / 65535.0) : 0;
}


- (void) setColorTransform:(SwiffColorTransform)colorTransform
{
    MAKE_ADDITIONAL;
    ADDITIONAL->colorTransform = colorTransform;
    ADDITIONAL->hasColorTransform = YES;
}


- (SwiffColorTransform) colorTransform
{
    if (_additional && ADDITIONAL->hasColorTransform) {
        return ADDITIONAL->colorTransform;
    } else {
        return SwiffColorTransformIdentity;
    }
}


- (SwiffColorTransform *) colorTransformPointer
{
    if (_additional && ADDITIONAL->hasColorTransform) {
        return &(ADDITIONAL->colorTransform);
    } else {
        return NULL;
    }
}


- (BOOL) hasColorTransform
{
    return _additional && ADDITIONAL->hasColorTransform;
}


- (void) setName:(NSString *)name
{
    if (name != [self name]) {
        MAKE_ADDITIONAL;

        if (ADDITIONAL->name) CFRelease(ADDITIONAL->name);
        ADDITIONAL->name = CFStringCreateCopy(NULL, (__bridge CFStringRef) name);
    }
}


- (NSString *) name
{
    return _additional ? (__bridge NSString *) ADDITIONAL->name : nil;
}


- (void) setClipDepth:(UInt16)clipDepth
{
    if (clipDepth != [self clipDepth]) {
        MAKE_ADDITIONAL;
        ADDITIONAL->clipDepth = clipDepth;
    }
}


- (UInt16) clipDepth
{
    return _additional ? ADDITIONAL->clipDepth : 0;
}


- (void) setClassName:(NSString *)className
{
    if (className != [self className]) {
        MAKE_ADDITIONAL;

        if (ADDITIONAL->className) CFRelease(ADDITIONAL->className);
        ADDITIONAL->className = CFStringCreateCopy(NULL, (__bridge CFStringRef) className);
    }
}


- (NSString *) className
{
    return _additional ? (__bridge NSString *) ADDITIONAL->className : nil;
}


- (void) setBlendMode:(SwiffBlendMode)blendMode
{
    if (blendMode != [self blendMode]) {
        MAKE_ADDITIONAL;
        ADDITIONAL->blendMode = blendMode;
    }
}


- (SwiffBlendMode) blendMode
{
    return _additional ? ADDITIONAL->blendMode : SwiffBlendModeNormal;
}



- (void) setCachesAsBitmap:(BOOL)cachesAsBitmap
{
    if (cachesAsBitmap != [self cachesAsBitmap]) {
        MAKE_ADDITIONAL;
        ADDITIONAL->cachesAsBitmap = cachesAsBitmap;
    }
}


- (BOOL) cachesAsBitmap
{
    return _additional ? ADDITIONAL->cachesAsBitmap : NO;
}


- (void) setCGBlendMode:(CGBlendMode)inBlendMode
{
    SwiffBlendMode swiffBlendMode;

    if (inBlendMode == kCGBlendModeNormal) {
        swiffBlendMode = SwiffBlendModeNormal;

    } else if (inBlendMode == kCGBlendModeMultiply) {
        swiffBlendMode = SwiffBlendModeMultiply;

    } else if (inBlendMode == kCGBlendModeScreen) {
        swiffBlendMode = SwiffBlendModeScreen;

    } else if (inBlendMode == kCGBlendModeLighten) {
        swiffBlendMode = SwiffBlendModeLighten;

    } else if (inBlendMode == kCGBlendModeDarken) {
        swiffBlendMode = SwiffBlendModeDarken;

    } else if (inBlendMode == kCGBlendModeDifference) {
        swiffBlendMode = SwiffBlendModeDifference;

    } else if (inBlendMode == kCGBlendModeOverlay) {
        swiffBlendMode = SwiffBlendModeOverlay;

    } else if (inBlendMode == kCGBlendModeHardLight) {
        swiffBlendMode = SwiffBlendModeHardlight;
    
    } else {
        swiffBlendMode = inBlendMode + SwiffBlendModeOther;
    }

    [self setBlendMode:swiffBlendMode];
}


- (CGBlendMode) CGBlendMode
{
    SwiffBlendMode swiffBlendMode = [self blendMode];

    if (swiffBlendMode <= SwiffBlendModeHardlight) {
        CGBlendMode lookup[] = {
            kCGBlendModeNormal,     // 0  = SwiffBlendModeNormal
            kCGBlendModeNormal,     // 1  = SwiffBlendModeNormal
            0,                      // 2  = SwiffBlendModeLayer
            kCGBlendModeMultiply,   // 3  = SwiffBlendModeMultiply
            kCGBlendModeScreen,     // 4  = SwiffBlendModeScreen
            kCGBlendModeLighten,    // 5  = SwiffBlendModeLighten
            kCGBlendModeDarken,     // 6  = SwiffBlendModeDarken
            kCGBlendModeDifference, // 7  = SwiffBlendModeDifference
            0,                      // 8  = SwiffBlendModeAdd
            0,                      // 9  = SwiffBlendModeSubtract
            0,                      // 10 = SwiffBlendModeInvert
            0,                      // 11 = SwiffBlendModeAlpha
            0,                      // 12 = SwiffBlendModeErase
            kCGBlendModeOverlay,    // 13 = SwiffBlendModeOverlay
            kCGBlendModeHardLight,  // 14 = SwiffBlendModeHardlight
        };

        return lookup[swiffBlendMode];

    } else if (swiffBlendMode > SwiffBlendModeOther) {
        return swiffBlendMode - SwiffBlendModeOther;

    } else {
        return kCGBlendModeNormal;
    }
}


- (void) setFilters:(NSArray *)filters
{
    if (filters != [self filters]) {
        MAKE_ADDITIONAL;
        
        if (ADDITIONAL->filters) CFRelease(ADDITIONAL->filters);
        ADDITIONAL->filters = (filters ? CFBridgingRetain(filters) : NULL);
    }
}


- (NSArray *) filters
{
    return _additional ? (__bridge NSArray *)ADDITIONAL->filters : nil;
}


@end
