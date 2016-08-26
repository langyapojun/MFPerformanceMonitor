//
//  MFPerformanceMonitorWindow.h
//  MakeFriends
//
//  Created by Vic on 25/8/2016.
//
//

#import <UIKit/UIKit.h>
#import "MFPerformanceMonitor.h"

#if _INTERNAL_MFPM_ENABLED

@protocol MFPMWindowEventDelegate <NSObject>

- (BOOL)shouldHandleTouchAtPoint:(CGPoint)pointInWindow;

@end

@interface MFPerformanceMonitorWindow : UIWindow

@property (nonatomic, weak) id <MFPMWindowEventDelegate> eventDelegate;

@end

#endif