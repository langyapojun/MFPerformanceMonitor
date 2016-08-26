//
//  MFPerformanceMonitorLifecycleDetailViewController.h
//  MakeFriends
//
//  Created by Vic on 15/8/16.
//
//

#import <UIKit/UIKit.h>
#import "MFPerformanceMonitor.h"

#if _INTERNAL_MFPM_ENABLED

@interface MFPerformanceMonitorLifecycleDetailViewController : UIViewController

@property (nonatomic, strong) NSString *controllerName;

@end

#endif
