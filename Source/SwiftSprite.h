//
//  SWFSprite.h
//  TheoryLessons
//
//  Created by Ricci Adams on 2011-10-05.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SwiftFrame, SwiftMovie, SwiftSceneAndFrameLabelData;

@interface SwiftSprite : NSObject <SwiftPlacableObject> {
@protected
    NSInteger       m_libraryID;
    NSMutableArray *m_frames;
    NSDictionary   *m_labelToFrameMap;
    SwiftFrame     *m_workingFrame;
    SwiftFrame     *m_lastFrame;
    
    SwiftSceneAndFrameLabelData *m_sceneAndFrameLabelData;
}

- (id) initWithParser:(SwiftParser *)parser tag:(SwiftTag)tag version:(NSInteger)version;

- (SwiftFrame *) frameWithLabel:(NSString *)label;

- (SwiftFrame *) frameAtIndex1:(NSInteger)index1;
- (NSInteger) index1OfFrame:(SwiftFrame *)frame;

@property (nonatomic, retain, readonly) NSArray *frames;
@property (nonatomic, assign, readonly) NSInteger libraryID;

@end
