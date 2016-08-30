//
//  MFPerformanceModel.m
//  MakeFriends
//
//  Created by Vic on 9/8/16.
//
//

#import "MFPerformanceModel.h"
#import "MFPerformanceMonitorManager.h"
#import <mach/mach.h>

#if _INTERNAL_MFPM_ENABLED

@implementation MFPerformanceInfo

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeFloat:self.memoryUsage forKey:@"memoryUsage"];
    [aCoder encodeFloat:self.cpuUsage forKey:@"cpuUsage"];
    [aCoder encodeObject:self.intervalSeconds forKey:@"intervalSeconds"];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self)
    {
        self.memoryUsage = [aDecoder decodeFloatForKey:@"memoryUsage"];
        self.cpuUsage = [aDecoder decodeFloatForKey:@"cpuUsage"];
        self.intervalSeconds = [aDecoder decodeObjectForKey:@"intervalSeconds"];
    }
    return self;
}

@end

@implementation MFControllerPerformanceInfo

@end

static NSString const * kMFPerformanceMonitorTempSamplingPerformanceDictFile = @"MFPerformanceMonitorTempSamplingPerformanceDictFile";
static NSString const * kMFPerformanceMonitorTempAppPerformanceListFile = @"MFPerformanceMonitorTempAppPerformanceListFile";
static NSInteger const kMFPerformanceMonitorMaxArrayCount = 10000;         // 最大的数组个数，超过后写入本地文件，目的是减少内存

@interface MFPerformanceModel ()

@property (nonatomic, strong) dispatch_source_t timeSource;
@property (nonatomic, assign) CFTimeInterval startMediaTime;
@property (nonatomic, strong) NSMutableDictionary<NSString *,NSNumber *> *memoryWithAllocLifeCycleDict;
@end

@implementation MFPerformanceModel

- (instancetype)init
{
    if (self = [super init]) {
        [self initData];
        [self initLoaclFile];
        [self startSamplingTimer];
    }
    return self;
}

- (void)dealloc
{
    [self cancelSamplingTimer];
}

- (void)initData
{
    _lifecyclePerformanceDict = [NSMutableDictionary dictionary];
    _samplingPerformanceDict = [NSMutableDictionary dictionary];
    _lifecyclePerformanceControllerNameList = [NSMutableArray array];
    _samplingPerformanceControllerNameList = [NSMutableArray array];
    _memoryWithAllocLifeCycleDict = [NSMutableDictionary dictionary];
    _appPerformanceList = [NSMutableArray array];
    _startMediaTime = CACurrentMediaTime();
}

- (void)initLoaclFile
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self tempSamplingPerformanceDictFilePath]]) {
        NSError *error;
        [[NSFileManager defaultManager] removeItemAtPath:[self tempSamplingPerformanceDictFilePath] error:&error];
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self tempAppPerformanceListFilePath]]) {
        NSError *error;
        [[NSFileManager defaultManager] removeItemAtPath:[self tempAppPerformanceListFilePath] error:&error];
    }
    
}

- (void)startSamplingTimer
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    _timeSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    dispatch_source_set_timer(_timeSource, DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC, 0.01 * NSEC_PER_SEC);
    
    __weak __typeof(self) weak_self = self;
    dispatch_source_set_event_handler(_timeSource, ^{
        [weak_self samplingPerformance];
    });
    
    dispatch_resume(_timeSource);
}

- (void)cancelSamplingTimer
{
    if (_timeSource) {
        dispatch_source_cancel(_timeSource);
        _timeSource = nil;
    }
}

- (void)samplingPerformance
{
    if (![MFPerformanceMonitorManager sharedManager].isEnable) {
        return;
    }
    
    CGFloat totMem = [self appMemoryUsage];
    CGFloat totCpu = [self appCpuUsage];
    if (totMem < 0 || totCpu < 0) {
        return;
    }
    
    MFPerformanceInfo *performanceInfo = [MFPerformanceInfo new];
    performanceInfo.memoryUsage = totMem;
    performanceInfo.cpuUsage = totCpu;
    performanceInfo.intervalSeconds = [NSString stringWithFormat:@"%.0f", CACurrentMediaTime() - _startMediaTime];
    [_appPerformanceList addObject:performanceInfo];
    
    NSString *controllerName = [self currentViewControllerName];
    if (!controllerName) {
        return;
    }
    
    if ([_samplingPerformanceDict objectForKey:controllerName]) {
        NSMutableArray *controllerPerformanceInfoList = [_samplingPerformanceDict objectForKey:controllerName];
        [controllerPerformanceInfoList addObject:performanceInfo];
    } else {
        if (![self.samplingPerformanceDict objectForKey:controllerName]) {
            [_samplingPerformanceControllerNameList addObject:controllerName];
        }
        
        NSMutableArray *controllerPerformanceInfoList = [NSMutableArray array];
        [controllerPerformanceInfoList addObject:performanceInfo];
        [_samplingPerformanceDict setObject:controllerPerformanceInfoList forKey:controllerName];
    }
    
    NSArray<NSMutableArray<MFPerformanceInfo *> *>*performanceArray = _samplingPerformanceDict.allValues;
    int count = 0;
    for (NSMutableArray<MFPerformanceInfo *>*performances in performanceArray) {
        count += performances.count;
    }
    count += _appPerformanceList.count;
    
    if (count >= kMFPerformanceMonitorMaxArrayCount) {
        [self saveSamplingPerformanceDictToLocal];
        [self saveAppPerformanceListToLocal];
    }
}

- (CGFloat)appMemoryUsage
{
    task_basic_info_data_t taskInfo;
    mach_msg_type_number_t infoCount = TASK_BASIC_INFO_COUNT;
    kern_return_t kernReturn = task_info(mach_task_self(),
                                         TASK_BASIC_INFO, (task_info_t)&taskInfo, &infoCount);
    
    if(kernReturn != KERN_SUCCESS) {
        return -1;
    }
    
    CGFloat memoryUsage = taskInfo.resident_size / 1024.0 / 1024.0;
    return memoryUsage;
}

- (CGFloat)appCpuUsage
{
    kern_return_t kr;
    task_info_data_t tinfo;
    mach_msg_type_number_t task_info_count;
    
    task_info_count = TASK_INFO_MAX;
    kr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)tinfo, &task_info_count);
    if (kr != KERN_SUCCESS) {
        return -1;
    }
    
    task_basic_info_t      basic_info;
    thread_array_t         thread_list;
    mach_msg_type_number_t thread_count;
    
    thread_info_data_t     thinfo;
    mach_msg_type_number_t thread_info_count;
    
    thread_basic_info_t basic_info_th;
    uint32_t stat_thread = 0; // Mach threads
    
    basic_info = (task_basic_info_t)tinfo;
    
    // get threads in the task
    kr = task_threads(mach_task_self(), &thread_list, &thread_count);
    if (kr != KERN_SUCCESS) {
        return -1;
    }
    if (thread_count > 0)
    stat_thread += thread_count;
    
    long tot_sec = 0;
    long tot_usec = 0;
    float tot_cpu = 0;
    int j;
    
    for (j = 0; j < thread_count; j++)
    {
        thread_info_count = THREAD_INFO_MAX;
        kr = thread_info(thread_list[j], THREAD_BASIC_INFO,
                         (thread_info_t)thinfo, &thread_info_count);
        if (kr != KERN_SUCCESS) {
            return -1;
        }
        
        basic_info_th = (thread_basic_info_t)thinfo;
        
        if (!(basic_info_th->flags & TH_FLAGS_IDLE)) {
            tot_sec = tot_sec + basic_info_th->user_time.seconds + basic_info_th->system_time.seconds;
            tot_usec = tot_usec + basic_info_th->system_time.microseconds + basic_info_th->system_time.microseconds;
            tot_cpu = tot_cpu + basic_info_th->cpu_usage / (float)TH_USAGE_SCALE * 100.0;
        }
        
    }
    
    kr = vm_deallocate(mach_task_self(), (vm_offset_t)thread_list, thread_count * sizeof(thread_t));
    if (kr != KERN_SUCCESS) {
        return -1;
    }
    
    return tot_cpu;
}


- (NSString *)currentViewControllerName
{
    UIViewController *currentVC = [self topViewController];
    
    if (!currentVC) {
        return nil;
    }
    return NSStringFromClass([currentVC class]);
}

- (UIViewController*)topViewController {
    return [self topViewControllerWithRootViewController:[UIApplication sharedApplication].keyWindow.rootViewController];
}

- (UIViewController*)topViewControllerWithRootViewController:(UIViewController*)rootViewController {
    if ([rootViewController isKindOfClass:[UITabBarController class]]) {
        UITabBarController* tabBarController = (UITabBarController*)rootViewController;
        return [self topViewControllerWithRootViewController:tabBarController.selectedViewController];
    } else if ([rootViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController* navigationController = (UINavigationController*)rootViewController;
        return [self topViewControllerWithRootViewController:navigationController.visibleViewController];
    } else if (rootViewController.presentedViewController) {
        UIViewController* presentedViewController = rootViewController.presentedViewController;
        return [self topViewControllerWithRootViewController:presentedViewController];
    } else {
        return rootViewController;
    }
}

- (void)monitorViewControllerMemory:(NSString *)controllerName lifeCycle:(MFMemoryMonitorLifeCycle)lifeCycle
{
    if (![MFPerformanceMonitorManager sharedManager].isEnable) {
        return;
    }
    
    CGFloat totMem = [self appMemoryUsage];
    
    if (totMem < 0) {
        return;
    }
    
    if (lifeCycle == MFMemoryMonitorLifeCycleAlloc) {
        [_memoryWithAllocLifeCycleDict setObject:@(totMem) forKey:controllerName];
    } else {
        if (![_memoryWithAllocLifeCycleDict objectForKey:controllerName]) {
            return;
        }
        
        CGFloat tot_cpu = [self appCpuUsage];
        if (tot_cpu < 0) {
            return;
        }
        
        CGFloat lastTotMem = [[_memoryWithAllocLifeCycleDict objectForKey:controllerName] floatValue];
        CGFloat changedMem = totMem - lastTotMem;
        
        MFPerformanceInfo *performanceInfo = [MFPerformanceInfo new];
        performanceInfo.memoryUsage = changedMem;
        performanceInfo.cpuUsage = tot_cpu;
        performanceInfo.intervalSeconds = [NSString stringWithFormat:@"%.0f", CACurrentMediaTime() - _startMediaTime];
        
        if ([_lifecyclePerformanceDict objectForKey:controllerName]) {
            MFControllerPerformanceInfo *controllerPerformanceInfo = [_lifecyclePerformanceDict objectForKey:controllerName];
            
            if (lifeCycle == MFMemoryMonitorLifeCycleDidload) {
                [controllerPerformanceInfo.didloadPerformance addObject:performanceInfo];
                
                MFPerformanceInfo *totPerformanceInfo = [MFPerformanceInfo new];
                totPerformanceInfo.memoryUsage = totMem;
                totPerformanceInfo.cpuUsage = tot_cpu;
                totPerformanceInfo.intervalSeconds = [NSString stringWithFormat:@"%.0f", CACurrentMediaTime() - _startMediaTime];
                [controllerPerformanceInfo.totloadPerformance addObject:totPerformanceInfo];
            } else if (lifeCycle == MFMemoryMonitorLifeCycleDealloc) {
                [controllerPerformanceInfo.deallocPerformance addObject:performanceInfo];
            }
        } else {
            MFControllerPerformanceInfo *controllerPerformanceInfo = [MFControllerPerformanceInfo new];
            controllerPerformanceInfo.didloadPerformance = [NSMutableArray array];
            controllerPerformanceInfo.totloadPerformance = [NSMutableArray array];
            controllerPerformanceInfo.deallocPerformance = [NSMutableArray array];
            
            if (lifeCycle == MFMemoryMonitorLifeCycleDidload) {
                [controllerPerformanceInfo.didloadPerformance addObject:performanceInfo];
                [controllerPerformanceInfo.totloadPerformance addObject:performanceInfo];
            } else if (lifeCycle == MFMemoryMonitorLifeCycleDealloc) {
                [controllerPerformanceInfo.deallocPerformance addObject:performanceInfo];
            }
            
            [_lifecyclePerformanceDict setObject:controllerPerformanceInfo forKey:controllerName];
            [_lifecyclePerformanceControllerNameList addObject:controllerName];
        }
    }
}

#pragma mark - Local Cache

- (void)saveSamplingPerformanceDictToLocal
{
    NSString *filePath = [self tempSamplingPerformanceDictFilePath];
    [NSKeyedArchiver archiveRootObject:self.samplingPerformanceDict toFile:filePath];
    [_samplingPerformanceDict removeAllObjects];
}

- (void)saveAppPerformanceListToLocal
{
    NSString *filePath = [self tempAppPerformanceListFilePath];
    [NSKeyedArchiver archiveRootObject:self.appPerformanceList toFile:filePath];
    [_appPerformanceList removeAllObjects];
}

- (NSMutableDictionary<NSString *, NSMutableArray<MFPerformanceInfo *> *> *)samplingPerformanceDict
{
    NSString *filePath = [self tempSamplingPerformanceDictFilePath];
    NSMutableDictionary<NSString *, NSMutableArray<MFPerformanceInfo *> *> *savedDict = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
    
    NSMutableDictionary *tempDict = [NSMutableDictionary dictionaryWithDictionary:_samplingPerformanceDict];
    if (savedDict) {
        for (NSString *keyString in tempDict.allKeys) {
            NSMutableArray<MFPerformanceInfo *> *tempArray = tempDict[keyString];
            
            if (![savedDict objectForKey:keyString]) {
                [savedDict setObject:tempArray forKey:keyString];
            } else {
                NSMutableArray<MFPerformanceInfo *> *saveArray = savedDict[keyString];
                [saveArray addObjectsFromArray:tempArray];
            }
        }
        
        return savedDict;
    } else {
        return tempDict;
    }
}

- (NSMutableArray<MFPerformanceInfo *> *)appPerformanceList
{
    NSString *filePath = [self tempAppPerformanceListFilePath];
    NSMutableArray<MFPerformanceInfo *> *savedArray = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
    
    NSMutableArray *tempArray = [NSMutableArray arrayWithArray:_appPerformanceList];
    if (savedArray) {
        [savedArray addObjectsFromArray:tempArray];
        return savedArray;
    } else {
        return tempArray;
    }
}

- (NSString *)tempSamplingPerformanceDictFilePath
{
    NSString *docsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *filePath = [docsPath stringByAppendingPathComponent:kMFPerformanceMonitorTempSamplingPerformanceDictFile];
    return filePath;
}

- (NSString *)tempAppPerformanceListFilePath
{
    NSString *docsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *filePath = [docsPath stringByAppendingPathComponent:kMFPerformanceMonitorTempAppPerformanceListFile];
    return filePath;
}

@end

#endif