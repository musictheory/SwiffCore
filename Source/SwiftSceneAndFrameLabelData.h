//
//  SwiftSceneAndFrameLabelData.h
//  SwiftCore
//
//  Created by Ricci Adams on 2011-10-12.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SwiftSceneAndFrameLabelData : NSObject {
@private
    NSDictionary *m_offsetToSceneNameMap;
    NSDictionary *m_numberToFrameLabelMap;
}

- (id) initWithParser:(SwiftParser *)parser tag:(SwiftTag)tag version:(NSInteger)version;

- (void) applyLabelsToFrames:(NSArray *)frames;
- (NSArray *) scenesForFrames:(NSArray *)frames;

@end
