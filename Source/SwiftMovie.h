//
//  SWFMovie.h
//  TheoryLessons
//
//  Created by Ricci Adams on 2011-10-05.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SwiftDynamicText, SwiftFont, SwiftShape, SwiftStaticText, SwiftScene;

@interface SwiftMovie : SwiftSprite {
@private
    NSData              *m_data;

    NSArray             *m_scenes;
    NSDictionary        *m_sceneNameToSceneMap;

    NSMutableDictionary *m_objects;
    NSMutableDictionary *m_shapes;
    NSMutableDictionary *m_sprites;
    NSMutableDictionary *m_fonts;
    NSMutableDictionary *m_dynamicTexts;
    NSMutableDictionary *m_staticTexts;

    NSInteger            m_version;
    CGPoint              m_stageOrigin;
    CGSize               m_stageSize;
    CGFloat              m_frameRate;
    SwiftColor           m_backgroundColor;
}

- (id) initWithData:(NSData *)data;
- (id) initWithData:(NSData *)data parserOptions:(SwiftParserOptions)parserOptions;

- (id) objectWithID:(NSInteger)objectID;

- (SwiftSprite *) spriteWithID:(NSInteger)spriteID;
- (SwiftShape  *) shapeWithID:(NSInteger)shapeID;
- (SwiftFont   *) fontWithID:(NSInteger)fontID;
- (SwiftStaticText  *) staticTextWithID:(NSInteger)textID;
- (SwiftDynamicText *) dynamicTextWithID:(NSInteger)textID;

- (SwiftScene *) sceneWithName:(NSString *)name;

@property (nonatomic, retain, readonly) NSArray *scenes;

@property (nonatomic, assign, readonly) NSInteger version;
@property (nonatomic, assign, readonly) CGFloat frameRate;
@property (nonatomic, assign, readonly) CGPoint stageOrigin;
@property (nonatomic, assign, readonly) CGSize  stageSize;


@end
