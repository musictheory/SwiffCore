//
//  SwiftGradient.h
//  TheoryLessons
//
//  Created by Ricci Adams on 2011-10-05.
//  Copyright (c) 2011 musictheory.net, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

enum {
    SwiftGradientSpreadModePad = 0,
    SwiftGradientSpreadModeReflect,
    SwiftGradientSpreadModeRepeat
};
typedef NSInteger SwiftGradientSpreadMode;


enum {
    SwiftGradientInterpolationModeNormalRGB = 0,
    SwiftGradientInterpolationModeLinearRGB = 1
};
typedef NSInteger SwiftGradientInterpolationMode;


@interface SwiftGradient : NSObject {
@private
    NSInteger     m_spreadMode;
    NSInteger     m_interpolationMode;
    NSInteger     m_recordCount;
    CGFloat       m_ratios[15];
    SwiftColor    m_colors[15];
    CGGradientRef m_cgGradient;
    CGFloat       m_focalPoint;
}

- (id) initWithParser: (SwiftParser *)parser
                  tag: (SwiftTag) tag
              version: (NSInteger) version
      isFocalGradient: (BOOL) isFocalGradient;

@property (nonatomic, readonly, assign) NSInteger recordCount;
- (void) getColor:(SwiftColor *)outColor ratio:(CGFloat *)outRatio forRecord:(NSInteger)index;

@property (nonatomic, readonly /*strong*/) CGGradientRef CGGradient;

@property (nonatomic, readonly, assign) SwiftGradientSpreadMode spreadMode;
@property (nonatomic, readonly, assign) SwiftGradientInterpolationMode interpolationMode;
@property (nonatomic, readonly, assign) CGFloat focalPoint;

@end
