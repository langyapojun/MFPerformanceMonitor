//
//  MFPerformanceMonitorSamplingDetailViewController.h
//  MakeFriends
//
//  Created by Vic on 18/8/2016.
//
//

#import <UIKit/UIKit.h>
#import "MFPerformanceMonitor.h"

#if _INTERNAL_MFPM_ENABLED

@interface MFPerformanceMonitorSamplingDetailViewController : UIViewController

@property (nonatomic, strong) NSString *controllerName;

@end

#endif
