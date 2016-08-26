//
//  MFPerformanceMonitorRootViewController.h
//  MakeFriends
//
//  Created by Vic on 25/8/2016.
//
//

#import <UIKit/UIKit.h>
#import "MFPerformanceMonitor.h"

#if _INTERNAL_MFPM_ENABLED

@interface MFPerformanceMonitorRootViewController : UIViewController

- (BOOL)shouldReceiveTouchAtWindowPoint:(CGPoint)pointInWindowCoordinates;

@end

#endif