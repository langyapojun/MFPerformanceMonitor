//
//  MFPerformanceModel.h
//  MakeFriends
//
//  Created by Vic on 9/8/16.
//
//

#import <Foundation/Foundation.h>
#import "MFPerformanceMonitor.h"

extern NSString * const kMFPerformanceMonitorPerformanceInfoMemoryKey;
extern NSString * const kMFPerformanceMonitorPerformanceInfoCpuKey;
extern NSString * const kMFPerformanceMonitorPerformanceInfoTimeKey;
extern NSString * const kMFPerformanceMonitorLifecycleDidloadKey;
extern NSString * const kMFPerformanceMonitorLifecycleDeallocKey;
extern NSString * const kMFPerformanceMonitorLifecycleTotalKey;

#if _INTERNAL_MFPM_ENABLED

typedef NS_ENUM(NSUInteger,MFMemoryMonitorLifeCycle) {
    MFMemoryMonitorLifeCycleAlloc = 0,
    MFMemoryMonitorLifeCycleDidload,
    MFMemoryMonitorLifeCycleDealloc
};

@interface MFPerformanceModel : NSObject

@property (nonatomic, strong) NSMutableArray<NSString *> *lifecyclePerformanceControllerNameList;
@property (nonatomic, strong) NSMutableArray<NSString *> *samplingPerformanceControllerNameList;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableDictionary *> *lifecyclePerformanceDict;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray<NSDictionary *> *> *samplingPerformanceDict;
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *appPerformanceList;

- (void)initWithAppId:(NSString *)appId;

- (void)saveToLocal:(NSString *)fileName;

- (CGFloat)appMemoryUsage;
- (CGFloat)appCpuUsage;
- (void)monitorViewControllerMemory:(NSString *)controllerName lifeCycle:(MFMemoryMonitorLifeCycle)lifeCycle;

- (void)startSamplingTimer;
- (void)cancelSamplingTimer;

- (void)addIgnoreController:(NSArray<Class> *)ignoredController;

@end

#endif
