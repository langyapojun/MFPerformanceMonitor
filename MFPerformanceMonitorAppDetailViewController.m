//
//  MFPerformanceMonitorAppDetailViewController.m
//  MakeFriends
//
//  Created by Vic on 18/8/2016.
//
//

#import "MFPerformanceMonitorAppDetailViewController.h"
#import "MFPerformanceMonitorManager.h"
#import "MFPerformanceModel.h"
#import "PNChart.h"
#include "LibXL/libxl.h"

#if _INTERNAL_MFPM_ENABLED

@interface MFPerformanceMonitorAppDetailViewController ()

@property (nonatomic, strong) NSMutableArray<MFPerformanceInfo *> *appPerformanceInfo;
@property (nonatomic, weak)   PNLineChart *lineChart;

@end

@implementation MFPerformanceMonitorAppDetailViewController

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
    _appPerformanceInfo = [MFPerformanceMonitorManager sharedManager].performanceModel.appPerformanceList;
}

- (void)initViews
{
    [self initNavis];
    self.view.backgroundColor = [UIColor whiteColor];
    
    PNLineChart *lineChart = [[PNLineChart alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - 64 - 60)];
    [self.view addSubview:lineChart];
    _lineChart = lineChart;
    
    lineChart.yLabelFormat = @"%1.1f";
    lineChart.backgroundColor = [UIColor clearColor];
    lineChart.showCoordinateAxis = YES;
    
    [lineChart setXLabels:[_appPerformanceInfo valueForKeyPath:@"intervalSeconds"]];
    
    PNLineChartData *memChartData = [PNLineChartData new];
    memChartData.dataTitle = @"APP占用内存(MB)";
    memChartData.color = PNFreshGreen;
    memChartData.itemCount = _appPerformanceInfo.count;
    
    __weak __typeof(self) weak_self = self;
    memChartData.getData = ^(NSUInteger index){
        CGFloat memoryUsage = weak_self.appPerformanceInfo[index].memoryUsage;
        return [PNLineChartDataItem dataItemWithY:memoryUsage];
    };
    
    PNLineChartData *cpuChartData = [PNLineChartData new];
    cpuChartData.dataTitle = @"APP占用CPU(MB)";
    cpuChartData.color = PNRed;
    cpuChartData.itemCount = _appPerformanceInfo.count;
    cpuChartData.getData = ^(NSUInteger index){
        CGFloat cpuUsage = weak_self.appPerformanceInfo[index].cpuUsage;
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
    self.title = @"App Performance";
    
    UIBarButtonItem *rightButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(saveToFile:)];
    self.navigationItem.rightBarButtonItem = rightButtonItem;
}

- (void)saveToFile:(id)sender
{
    BookHandle book = xlCreateBook();
    
    SheetHandle sheet = xlBookAddSheet(book, "Sheet1", NULL);
    
    NSString *picFilePath = [self screenShot];
    int pictureId = xlBookAddPicture(book,[picFilePath UTF8String]);
    NSAssert(pictureId != -1, @"add picture error!");
    
    xlSheetSetPictureA(sheet, 1, 1, pictureId, 1, 0, 0, 0);
    
    NSString *documentPath =
    [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES) objectAtIndex:0];
    NSString *filename = [documentPath stringByAppendingPathComponent:@"out.xls"];
    
    xlBookSave(book, [filename UTF8String]);
    
    xlBookRelease(book);
}

-(NSString *)screenShot
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake([UIScreen mainScreen].bounds.size.width, ([UIScreen mainScreen].bounds.size.height - 64)), NO, 1);
    
    //设置截屏大小
    
    [[self.view layer] renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    CGImageRef imageRef = viewImage.CGImage;
    CGRect rect = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - 64);//这里可以设置想要截图的区域
    
    CGImageRef imageRefRect =CGImageCreateWithImageInRect(imageRef, rect);
    UIImage *sendImage = [[UIImage alloc] initWithCGImage:imageRefRect];
    
    
    NSData *imageViewData = UIImagePNGRepresentation(sendImage);
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *pictureName= @"appPerformance.png";
    NSString *savedImagePath = [documentsDirectory stringByAppendingPathComponent:pictureName];
    [imageViewData writeToFile:savedImagePath atomically:YES];//保存照片到沙盒目录
    
    CGImageRelease(imageRefRect);
    
    return savedImagePath;
}

@end

#endif