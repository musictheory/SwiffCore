//
//  SwiffSoundStreamBlock.h
//  SwiffCore
//
//  Created by Ricci Adams on 2012-01-03.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SwiffSoundStreamBlock : NSObject {
@private
    NSInteger m_frameOffset;
    NSInteger m_sampleCount;
    NSInteger m_sampleSeek;
}

@property (nonatomic, assign) NSInteger frameOffset;
@property (nonatomic, assign) NSInteger sampleCount;
@property (nonatomic, assign) NSInteger sampleSeek;

@end
