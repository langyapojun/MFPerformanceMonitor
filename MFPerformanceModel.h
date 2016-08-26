//
//  MFPerformanceModel.h
//  MakeFriends
//
//  Created by Vic on 9/8/16.
//
//

#import <Foundation/Foundation.h>
#import "MFPerformanceMonitor.h"

#if _INTERNAL_MFPM_ENABLED

typedef NS_ENUM(NSUInteger,MFMemoryMonitorLifeCycle) {
    MFMemoryMonitorLifeCycleAlloc = 0,
    MFMemoryMonitorLifeCycleDidload,
    MFMemoryMonitorLifeCycleDealloc
};

@interface MFPerformanceInfo : NSObject

@property (nonatomic, assign) CGFloat memoryUsage;
@property (nonatomic, assign) CGFloat cpuUsage;
@property (nonatomic, strong) NSString *intervalSeconds;

@end

@interface MFControllerPerformanceInfo : NSObject

@property (nonatomic, strong) NSMutableArray<MFPerformanceInfo *> *didloadPerformance;
@property (nonatomic, strong) NSMutableArray<MFPerformanceInfo *> *deallocPerformance;
@property (nonatomic, strong) NSMutableArray<MFPerformanceInfo *> *totloadPerformance;

@end

@interface MFPerformanceModel : NSObject

@property (nonatomic, strong, readonly) NSMutableArray<NSString *> *lifecyclePerformanceControllerNameList;
@property (nonatomic, strong, readonly) NSMutableArray<NSString *> *samplingPerformanceControllerNameList;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString *, MFControllerPerformanceInfo *> *lifecyclePerformanceDict;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString *, NSMutableArray<MFPerformanceInfo *> *> *samplingPerformanceDict;
@property (nonatomic, strong, readonly) NSMutableArray<MFPerformanceInfo *> *appPerformanceList;

- (CGFloat)appMemoryUsage;
- (CGFloat)appCpuUsage;
- (void)monitorViewControllerMemory:(NSString *)controllerName lifeCycle:(MFMemoryMonitorLifeCycle)lifeCycle;

- (void)startSamplingTimer;
- (void)cancelSamplingTimer;

@end

#endif
