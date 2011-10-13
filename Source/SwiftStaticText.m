//
//  SwiftStaticText.m
//  TheoryLessons
//
//  Created by Ricci Adams on 2011-10-07.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SwiftStaticText.h"

#import "SwiftParser.h"
#import "SwiftTextRecord.h"

@implementation SwiftStaticText

- (id) initWithParser:(SwiftParser *)parser tag:(SwiftTag)tag version:(NSInteger)version
{
    if ((self = [super init])) {
        UInt16 libraryID;
        SwiftParserReadUInt16(parser, &libraryID);
        m_libraryID = libraryID;
        
        SwiftParserReadRect(parser,   &m_bounds);
        SwiftParserReadMatrix(parser, &m_affineTransform);

        UInt8 glyphBits, advanceBits;
        SwiftParserReadUInt8(parser, &glyphBits);
        SwiftParserReadUInt8(parser, &advanceBits);
    
        m_textRecords = [[SwiftTextRecord textRecordArrayWithParser:parser tag:tag version:version glyphBits:glyphBits advanceBits:advanceBits] retain];
    }
    
    return self;
}

- (void) dealloc
{
    [m_textRecords release];
    m_textRecords = nil;

    [super dealloc];
}

- (BOOL) hasEdgeBounds { return NO; }
- (CGRect) edgeBounds { return CGRectZero; }


@synthesize libraryID = m_libraryID,
            bounds    = m_bounds;

@end
