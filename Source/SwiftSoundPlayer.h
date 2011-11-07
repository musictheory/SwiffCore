//
//  SwiftSoundPlayer.h
//  SwiftCore
//
//  Created by Ricci Adams on 2011-10-27.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <SwiftImport.h>

@class SwiftSoundEvent, SwiftMovie, SwiftFrame;
@class _SwiftSoundChannel;


@interface SwiftSoundPlayer : NSObject {
@private
    NSMutableDictionary  *m_libraryIDTChannelArrayMap;
    _SwiftSoundChannel   *m_currentStreamChannel;
}

+ (SwiftSoundPlayer *) sharedInstance;

- (void) processMovie:(SwiftMovie *)movie frame:(SwiftFrame *)frame;
- (void) stopAllSounds;

@property (nonatomic, assign, readonly, getter=isPlaying)   BOOL playing;   // Is playing any sound
@property (nonatomic, assign, readonly, getter=isStreaming) BOOL streaming; // Is playing non-event sound

@end
