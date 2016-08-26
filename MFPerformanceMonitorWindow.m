//
//  MFPerformanceMonitorWindow.m
//  MakeFriends
//
//  Created by Vic on 25/8/2016.
//
//

#import "MFPerformanceMonitorWindow.h"

#if _INTERNAL_MFPM_ENABLED

@implementation MFPerformanceMonitorWindow

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        self.windowLevel = UIWindowLevelStatusBar + 150.0;
    }
    return self;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    BOOL pointInside = NO;
    if ([self.eventDelegate shouldHandleTouchAtPoint:point]) {
        pointInside = [super pointInside:point withEvent:event];
    }
    return pointInside;
}

@end

#endif
