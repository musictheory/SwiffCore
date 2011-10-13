//
//  SwiftScene.h
//  SwiftCore
//
//  Created by Ricci Adams on 2011-10-11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SwiftFrame;

@interface SwiftScene : NSObject {
@private
    NSString     *m_name;
    NSArray      *m_frames;
    NSDictionary *m_labelToFrameMap;
}

- (id) initWithName:(NSString *)name frames:(NSArray *)frames;

- (SwiftFrame *) frameWithLabel:(NSString *)label;

- (SwiftFrame *) frameAtIndex1:(NSInteger)index1;
- (NSInteger) index1OfFrame:(SwiftFrame *)frame;

@property (nonatomic, assign, readonly) NSString *name;
@property (nonatomic, assign, readonly) NSArray *frames;

@end
