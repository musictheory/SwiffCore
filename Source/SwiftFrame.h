//
//  SWFFrame.h
//  TheoryLessons
//
//  Created by Ricci Adams on 2011-10-05.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SwiftPlacedObject, SwiftSprite, SwiftScene;

@interface SwiftFrame : NSObject <NSCopying> {
@private
    NSInteger    m_indexInScene;
    SwiftScene  *m_parentScene;
    SwiftSprite *m_parentSprite;
    SwiftFrame  *m_nextFrame;

    NSString    *m_label;
    NSArray     *m_placedObjects;
    SwiftColor   m_backgroundColor;
}

@property (nonatomic, assign) SwiftSprite *parentSprite;
@property (nonatomic, assign) SwiftScene  *parentScene;
@property (nonatomic, assign) SwiftFrame  *nextFrame;

@property (nonatomic, copy) NSString *label;
@property (nonatomic, assign) NSInteger indexInScene;

// Sorted by ascending depth 
@property (nonatomic, assign) SwiftColor backgroundColor;

// Inside pointer, valid for lifetime of the SwiftFrame
@property (nonatomic, assign, readonly) SwiftColor *backgroundColorPointer;

@property (nonatomic, copy, readonly) NSArray  *placedObjects;

@end
