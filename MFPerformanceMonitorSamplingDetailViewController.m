//
//  MFPerformanceMonitorSamplingDetailViewController.m
//  MakeFriends
//
//  Created by Vic on 18/8/2016.
//
//

#import "MFPerformanceMonitorSamplingDetailViewController.h"
#import "MFPerformanceMonitorManager.h"
#import "MFPerformanceModel.h"
#import "PNChart.h"

#if _INTERNAL_MFPM_ENABLED

@interface MFPerformanceMonitorSamplingDetailViewController ()

@property (nonatomic, strong) NSMutableArray<NSDictionary *> *controllerPerformanceInfo;
@property (nonatomic, weak)   PNLineChart *lineChart;

@end

@implementation MFPerformanceMonitorSamplingDetailViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self inits];
}

- (void)inits
{
    [self initDatas];
    [self initViews];
}

- (void)initDatas
{
    _controllerPerformanceInfo = [[MFPerformanceMonitorManager sharedManager].performanceModel.samplingPerformanceDict objectForKey:_controllerName];
}

- (void)initViews
{
    [self initNavis];
    self.view.backgroundColor = [UIColor whiteColor];
    
    PNLineChart *lineChart = [[PNLineChart alloc] initWithFrame:CGRectMake(0, 64, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - 128 - 60)];
    [self.view addSubview:lineChart];
    _lineChart = lineChart;
    
    lineChart.yLabelFormat = @"%1.1f";
    lineChart.backgroundColor = [UIColor clearColor];
    lineChart.showCoordinateAxis = YES;
    
    [lineChart setXLabels:[_controllerPerformanceInfo valueForKeyPath:kMFPerformanceMonitorPerformanceInfoTimeKey]];
    
    PNLineChartData *memChartData = [PNLineChartData new];
    memChartData.dataTitle = @"APP占用内存(MB)";
    memChartData.color = PNFreshGreen;
    memChartData.itemCount = _controllerPerformanceInfo.count;
    
    __weak __typeof(self) weak_self = self;
    memChartData.getData = ^(NSUInteger index){
        CGFloat memoryUsage = [[weak_self.controllerPerformanceInfo[index] objectForKey:kMFPerformanceMonitorPerformanceInfoMemoryKey] floatValue];
        return [PNLineChartDataItem dataItemWithY:memoryUsage];
    };
    
    PNLineChartData *cpuChartData = [PNLineChartData new];
    cpuChartData.dataTitle = @"APP占用CPU(MB)";
    cpuChartData.color = PNRed;
    cpuChartData.itemCount = _controllerPerformanceInfo.count;
    cpuChartData.getData = ^(NSUInteger index){
        CGFloat cpuUsage = [[weak_self.controllerPerformanceInfo[index] objectForKey:kMFPerformanceMonitorPerformanceInfoCpuKey] floatValue];
        return [PNLineChartDataItem dataItemWithY:cpuUsage];
    };
    
    lineChart.chartData = @[memChartData,cpuChartData];
    [lineChart strokeChart];
    
    self.lineChart.legendStyle = PNLegendItemStyleStacked;
    self.lineChart.legendFont = [UIFont boldSystemFontOfSize:12.0f];
    self.lineChart.legendFontColor = [UIColor blackColor];
    UIView *legend = [self.lineChart getLegendWithMaxWidth:[UIScreen mainScreen].bounds.size.width];
    [legend setFrame:CGRectMake(30, [UIScreen mainScreen].bounds.size.height - 64 - 60, legend.frame.size.width, 60)];
    [self.view addSubview:legend];
}

- (void)initNavis
{
    self.title = _controllerName;

}

@end

#endif