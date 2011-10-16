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
@private
    CFMutableDictionaryRef m_depthToPlacedObjectMap;
    SwiftFrame      *m_lastFrame;
    NSInteger        m_libraryID;

@protected
    NSMutableArray  *m_frames;
    NSDictionary    *m_labelToFrameMap;
    SwiftSceneAndFrameLabelData *m_sceneAndFrameLabelData;
}

- (id) initWithParser:(SwiftParser *)parser tag:(SwiftTag)tag version:(NSInteger)version;

- (SwiftFrame *) frameWithLabel:(NSString *)label;

- (SwiftFrame *) frameAtIndex1:(NSInteger)index1;
- (NSInteger) index1OfFrame:(SwiftFrame *)frame;

@property (nonatomic, retain, readonly) NSArray *frames;
@property (nonatomic, assign, readonly) NSInteger libraryID;

@end
