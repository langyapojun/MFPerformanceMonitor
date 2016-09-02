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
#import "SSZipArchive.h"

#if _INTERNAL_MFPM_ENABLED

NSString * const kMFPerformanceMonitorPerformanceInfoMemoryKey = @"kMFPerformanceMonitorPerformanceInfoMemoryKey";
NSString * const kMFPerformanceMonitorPerformanceInfoCpuKey = @"kMFPerformanceMonitorPerformanceInfoCpuKey";
NSString * const kMFPerformanceMonitorPerformanceInfoTimeKey = @"kMFPerformanceMonitorPerformanceInfoTimeKey";
NSString * const kMFPerformanceMonitorLifecycleDidloadKey = @"kMFPerformanceMonitorLifecycleDidloadKey";
NSString * const kMFPerformanceMonitorLifecycleDeallocKey = @"kMFPerformanceMonitorLifecycleDeallocKey";
NSString * const kMFPerformanceMonitorLifecycleTotalKey = @"kMFPerformanceMonitorLifecycleTotalKey";

static NSString * kMFPerformanceMonitorTempLifecyclePerformanceDictFile = @"MFPerformanceMonitorTempLifecyclePerformanceDictFile";
static NSString * kMFPerformanceMonitorTempSamplingPerformanceDictFile = @"MFPerformanceMonitorTempSamplingPerformanceDictFile";
static NSString * kMFPerformanceMonitorTempAppPerformanceListFile = @"MFPerformanceMonitorTempAppPerformanceListFile";
static NSInteger const kMFPerformanceMonitorMaxArrayCount = 10000;         // 最大的数组个数，超过后写入本地文件，目的是减少内存

@interface MFPerformanceModel ()

@property (nonatomic, strong) dispatch_source_t timeSource;
@property (nonatomic, assign) CFTimeInterval startMediaTime;
@property (nonatomic, strong) NSMutableDictionary<NSString *,NSNumber *> *memoryWithAllocLifeCycleDict;
@property (nonatomic, strong) NSMutableArray<Class> *ignoredControllers;
@end

@implementation MFPerformanceModel

- (instancetype)init
{
    if (self = [super init]) {
        [self initData];
        [self removeLoaclTempFile];
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
    
    [self initIgnoredControllers];
}

- (void)initIgnoredControllers
{
    _ignoredControllers = [NSMutableArray array];
    [_ignoredControllers addObjectsFromArray:@[NSClassFromString(@"MFPerformanceMonitorAppDetailViewController"),
                                               NSClassFromString(@"MFPerformanceMonitorLifecycleDetailViewController"),
                                               NSClassFromString(@"MFPerformanceMonitorListViewController"),
                                               NSClassFromString(@"MFPerformanceMonitorRootViewController"),
                                               NSClassFromString(@"MFPerformanceMonitorSamplingDetailViewController"),
                                               NSClassFromString(@"MFPerformanceMonitorViewController"),
                                               NSClassFromString(@"UINavigationController")
                                               ]];
}

- (void)removeLoaclTempFile
{
    NSError *error;

    if ([[NSFileManager defaultManager] fileExistsAtPath:[self tempSamplingPerformanceDictFilePath]]) {
        [[NSFileManager defaultManager] removeItemAtPath:[self tempSamplingPerformanceDictFilePath] error:&error];
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self tempAppPerformanceListFilePath]]) {
        [[NSFileManager defaultManager] removeItemAtPath:[self tempAppPerformanceListFilePath] error:&error];
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self tempLifecyclePerformanceDictFilePath]]) {
        [[NSFileManager defaultManager] removeItemAtPath:[self tempLifecyclePerformanceDictFilePath] error:&error];
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
    
    NSDictionary *performanceInfoDict = @{kMFPerformanceMonitorPerformanceInfoMemoryKey:@(totMem),
                                          kMFPerformanceMonitorPerformanceInfoCpuKey:@(totCpu),
                                          kMFPerformanceMonitorPerformanceInfoTimeKey:[NSString stringWithFormat:@"%.0f", CACurrentMediaTime() - _startMediaTime]};
    
    [_appPerformanceList addObject:performanceInfoDict];
    
    NSString *controllerName = [self currentViewControllerName];
    if (!controllerName) {
        return;
    }
    
    if ([_samplingPerformanceDict objectForKey:controllerName]) {
        NSMutableArray *controllerPerformanceInfoList = [_samplingPerformanceDict objectForKey:controllerName];
        [controllerPerformanceInfoList addObject:performanceInfoDict];
    } else {
        if (![self.samplingPerformanceDict objectForKey:controllerName]) {
            [_samplingPerformanceControllerNameList addObject:controllerName];
        }
        
        NSMutableArray *controllerPerformanceInfoList = [NSMutableArray array];
        [controllerPerformanceInfoList addObject:performanceInfoDict];
        [_samplingPerformanceDict setObject:controllerPerformanceInfoList forKey:controllerName];
    }
    
    NSArray<NSMutableArray<NSDictionary *> *>*performanceArray = _samplingPerformanceDict.allValues;
    int count = 0;
    for (NSMutableArray<NSDictionary *>*performances in performanceArray) {
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
    
    if ([self isIgnoredController:controllerName]) {
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
        
        NSDictionary *diffPerformanceInfoDict = @{kMFPerformanceMonitorPerformanceInfoMemoryKey:@(changedMem),
                                              kMFPerformanceMonitorPerformanceInfoCpuKey:@(tot_cpu),
                                              kMFPerformanceMonitorPerformanceInfoTimeKey:[NSString stringWithFormat:@"%.0f", CACurrentMediaTime() - _startMediaTime]};
        
        NSDictionary *totalPerformanceInfoDict = @{kMFPerformanceMonitorPerformanceInfoMemoryKey:@(totMem),
                                                  kMFPerformanceMonitorPerformanceInfoCpuKey:@(tot_cpu),
                                                  kMFPerformanceMonitorPerformanceInfoTimeKey:[NSString stringWithFormat:@"%.0f", CACurrentMediaTime() - _startMediaTime]};
        
        if ([_lifecyclePerformanceDict objectForKey:controllerName]) {
            NSMutableDictionary *controllerPerformanceInfoDict = [_lifecyclePerformanceDict objectForKey:controllerName];
            
            if (lifeCycle == MFMemoryMonitorLifeCycleDidload) {
                NSMutableArray *didloadPerformanceArray = controllerPerformanceInfoDict[kMFPerformanceMonitorLifecycleDidloadKey];
                NSMutableArray *totloadPerformanceArray = controllerPerformanceInfoDict[kMFPerformanceMonitorLifecycleTotalKey];
                [didloadPerformanceArray addObject:diffPerformanceInfoDict];
                [totloadPerformanceArray addObject:totalPerformanceInfoDict];
            } else if (lifeCycle == MFMemoryMonitorLifeCycleDealloc) {
                NSMutableArray *deallocPerformanceArray = controllerPerformanceInfoDict[kMFPerformanceMonitorLifecycleDeallocKey];
                [deallocPerformanceArray addObject:diffPerformanceInfoDict];
            }
        } else {
            NSMutableDictionary *controllerPerformanceInfoDict = [NSMutableDictionary dictionary];
            [controllerPerformanceInfoDict setObject:[NSMutableArray array] forKey:kMFPerformanceMonitorLifecycleDidloadKey];
            [controllerPerformanceInfoDict setObject:[NSMutableArray array] forKey:kMFPerformanceMonitorLifecycleDeallocKey];
            [controllerPerformanceInfoDict setObject:[NSMutableArray array] forKey:kMFPerformanceMonitorLifecycleTotalKey];
            
            if (lifeCycle == MFMemoryMonitorLifeCycleDidload) {
                NSMutableArray *didloadPerformanceArray = controllerPerformanceInfoDict[kMFPerformanceMonitorLifecycleDidloadKey];
                NSMutableArray *totloadPerformanceArray = controllerPerformanceInfoDict[kMFPerformanceMonitorLifecycleTotalKey];
                [didloadPerformanceArray addObject:diffPerformanceInfoDict];
                [totloadPerformanceArray addObject:totalPerformanceInfoDict];
            } else if (lifeCycle == MFMemoryMonitorLifeCycleDealloc) {
                NSMutableArray *deallocPerformanceArray = controllerPerformanceInfoDict[kMFPerformanceMonitorLifecycleDeallocKey];
                [deallocPerformanceArray addObject:diffPerformanceInfoDict];
            }
            
            [_lifecyclePerformanceDict setObject:controllerPerformanceInfoDict forKey:controllerName];
            [_lifecyclePerformanceControllerNameList addObject:controllerName];
        }
    }
}

- (void)addIgnoreController:(NSArray<Class> *)ignoredController
{
    [_ignoredControllers addObjectsFromArray:ignoredController];
}

- (BOOL)isIgnoredController:(NSString *)controllerName
{
    BOOL isIgonred = NO;
    
    for (Class ignoredClass in _ignoredControllers) {
        if ([NSClassFromString(controllerName) isSubclassOfClass:ignoredClass]) {
            isIgonred = YES;
            break;
        }
    }
    
    return isIgonred;
}

#pragma mark - Local Cache

- (void)saveToLocal:(NSString *)fileName
{
    [self saveLifecyclePerformanceDictToLocal];
    [self saveSamplingPerformanceDictToLocal];
    [self saveAppPerformanceListToLocal];
    
    NSString *zipFilePath = [[self performanceMonitorDirectryPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.zip",fileName]];
    NSArray *toZipFilesPathArray = @[[self tempLifecyclePerformanceDictFilePath],[self tempSamplingPerformanceDictFilePath],[self tempAppPerformanceListFilePath]];
    BOOL zipSuccess = [SSZipArchive createZipFileAtPath:zipFilePath withFilesAtPaths:toZipFilesPathArray];
    NSAssert(zipSuccess, @"zip failed!");
    if (zipSuccess) {
        [self removeLoaclTempFile];
    }
    
}

- (void)saveLifecyclePerformanceDictToLocal
{
    NSString *filePath = [self tempLifecyclePerformanceDictFilePath];
    NSError *error;
    NSData *lifecyclePerformanceDictJsonData = [NSJSONSerialization dataWithJSONObject:_lifecyclePerformanceDict options:NSJSONWritingPrettyPrinted error:&error];
    NSString *lifecyclePerformanceDictJsonString = [[NSString alloc] initWithData:lifecyclePerformanceDictJsonData encoding:NSUTF8StringEncoding];
    [lifecyclePerformanceDictJsonString writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
}

- (void)saveSamplingPerformanceDictToLocal
{
    NSString *filePath = [self tempSamplingPerformanceDictFilePath];
    NSError *error;
    NSData *samplingPerformanceDictJsonData = [NSJSONSerialization dataWithJSONObject:self.samplingPerformanceDict options:NSJSONWritingPrettyPrinted error:&error];
    NSString *samplingPerformanceDictJsonString = [[NSString alloc] initWithData:samplingPerformanceDictJsonData encoding:NSUTF8StringEncoding];
    [samplingPerformanceDictJsonString writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    [_samplingPerformanceDict removeAllObjects];
}

- (void)saveAppPerformanceListToLocal
{
    NSString *filePath = [self tempAppPerformanceListFilePath];
    NSError *error;
    NSData *appPerformanceListJsonData = [NSJSONSerialization dataWithJSONObject:self.appPerformanceList options:NSJSONWritingPrettyPrinted error:&error];
    NSString *appPerformanceListJsonString = [[NSString alloc] initWithData:appPerformanceListJsonData encoding:NSUTF8StringEncoding];
    [appPerformanceListJsonString writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    [_appPerformanceList removeAllObjects];
}

- (NSMutableDictionary<NSString *, NSMutableArray<NSDictionary *> *> *)samplingPerformanceDict
{
    NSString *filePath = [self tempSamplingPerformanceDictFilePath];
    NSError *error;
    NSString *samplingPerformanceDictJsonString = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    NSData *samplingPerformanceDictJsonData = [samplingPerformanceDictJsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableDictionary<NSString *, NSMutableArray<NSDictionary *> *> *savedDict = samplingPerformanceDictJsonData ? [NSJSONSerialization JSONObjectWithData:samplingPerformanceDictJsonData options:NSJSONReadingMutableContainers error:&error] : nil;
    
    NSMutableDictionary *tempDict = [NSMutableDictionary dictionaryWithDictionary:_samplingPerformanceDict];
    if (savedDict) {
        for (NSString *keyString in tempDict.allKeys) {
            NSMutableArray<NSDictionary *> *tempArray = tempDict[keyString];
            
            if (![savedDict objectForKey:keyString]) {
                [savedDict setObject:tempArray forKey:keyString];
            } else {
                NSMutableArray<NSDictionary *> *saveArray = savedDict[keyString];
                [saveArray addObjectsFromArray:tempArray];
            }
        }
        
        return savedDict;
    } else {
        return tempDict;
    }
}

- (NSMutableArray<NSDictionary *> *)appPerformanceList
{
    NSString *filePath = [self tempAppPerformanceListFilePath];
    NSError *error;
    NSString *appPerformanceListJsonString = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    NSData *appPerformanceListJsonData = [appPerformanceListJsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableArray<NSDictionary *> *savedArray = appPerformanceListJsonData ? [NSJSONSerialization JSONObjectWithData:appPerformanceListJsonData options:NSJSONReadingMutableContainers error:&error] : nil;
    
    NSMutableArray *tempArray = [NSMutableArray arrayWithArray:_appPerformanceList];
    if (savedArray) {
        [savedArray addObjectsFromArray:tempArray];
        return savedArray;
    } else {
        return tempArray;
    }
}

- (NSString *)tempLifecyclePerformanceDictFilePath
{
    NSString *directryPath = [self performanceMonitorDirectryPath];
    NSString *filePath = [directryPath stringByAppendingPathComponent:kMFPerformanceMonitorTempLifecyclePerformanceDictFile];
    return filePath;
}

- (NSString *)tempSamplingPerformanceDictFilePath
{
    NSString *directryPath = [self performanceMonitorDirectryPath];
    NSString *filePath = [directryPath stringByAppendingPathComponent:kMFPerformanceMonitorTempSamplingPerformanceDictFile];
    return filePath;
}

- (NSString *)tempAppPerformanceListFilePath
{
    NSString *directryPath = [self performanceMonitorDirectryPath];
    NSString *filePath = [directryPath stringByAppendingPathComponent:kMFPerformanceMonitorTempAppPerformanceListFile];
    return filePath;
}

- (NSString *)performanceMonitorDirectryPath
{
    NSString *docsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *directryPath = [docsPath stringByAppendingPathComponent:@"PerformanceMonitor"];
    if (![fileManager fileExistsAtPath:directryPath]) {
        [fileManager createDirectoryAtPath:directryPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return directryPath;
}

@end

#endif