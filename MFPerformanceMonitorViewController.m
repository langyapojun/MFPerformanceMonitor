//
//  MFPerformanceMonitorViewController.m
//  MakeFriends
//
//  Created by Vic on 18/8/2016.
//
//

#import "MFPerformanceMonitorViewController.h"
#import "MFPerformanceMonitorListViewController.h"
#import "MFPerformanceMonitorAppDetailViewController.h"
#import "MFPerformanceMonitorManager.h"
#import "MFPerformanceModel.h"
#import "PNChart.h"
#include "LibXL/libxl.h"

#if _INTERNAL_MFPM_ENABLED

@interface MFPerformanceMonitorViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, strong) NSArray<NSString *> *dataList;

@end

@implementation MFPerformanceMonitorViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self inits];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    _tableView.frame = self.view.bounds;
}

#pragma mark - inits

- (void)inits
{
    [self initData];
    [self initViews];
}

- (void)initData
{
    _dataList = @[@"Controller内存变化",@"Controller定时采样",@"App定时采样"];
}

- (void)initViews
{
    [self initNavis];
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    [self.view addSubview:tableView];
    _tableView = tableView;
    tableView.backgroundColor = [UIColor whiteColor];
    tableView.rowHeight = 44;
    tableView.delegate = self;
    tableView.dataSource = self;
}

- (void)initNavis
{
    self.title = @"性能监控";
    
    UIBarButtonItem *leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:self action:@selector(back:)];
    self.navigationItem.leftBarButtonItem = leftBarButtonItem;
    
//    UIBarButtonItem *rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"保存到本地" style:UIBarButtonItemStylePlain target:self action:@selector(saveToLoaclFile:)];
//    self.navigationItem.rightBarButtonItem = rightBarButtonItem;
}

#pragma mark - tableviewDelegates

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _dataList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * const mfPerformanceMonitorTableViewCellIdentifier = @"mfPerformanceMonitorTableViewCellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:mfPerformanceMonitorTableViewCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:mfPerformanceMonitorTableViewCellIdentifier];
    }
    cell.textLabel.text = _dataList[indexPath.row];
    return cell;
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSInteger row = indexPath.row;
    if (row == 0 || row == 1) {
        MFPerformanceMonitorListViewController *monitorVC = [MFPerformanceMonitorListViewController new];
        MFPerformanceMonitorType type = row == 0 ? MFPerformanceMonitorTypeLifeCycle : MFPerformanceMonitorTypeSampling;
        monitorVC.performanceMonitorType = type;
        [self.navigationController pushViewController:monitorVC animated:YES];
    } else if (row == 2) {
        MFPerformanceMonitorAppDetailViewController *appDetailVC = [MFPerformanceMonitorAppDetailViewController new];
        [self.navigationController pushViewController:appDetailVC animated:YES];
    }
}

#pragma mark - uiaction

- (void)back:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)saveToLoaclFile:(id)sender
{
    // lifecycle
    NSMutableArray<NSString *> *lifecyclePerformanceControllerNameList = [MFPerformanceMonitorManager sharedManager].performanceModel.lifecyclePerformanceControllerNameList;
    NSMutableDictionary<NSString *, MFControllerPerformanceInfo *> *lifecyclePerformanceDict = [MFPerformanceMonitorManager sharedManager].performanceModel.lifecyclePerformanceDict;
    
    BookHandle lifecycleBook = xlCreateBook();
    for (NSString *controllerName in lifecyclePerformanceControllerNameList) {
        
        SheetHandle sheet = xlBookAddSheet(lifecycleBook, [controllerName UTF8String], NULL);
        int row,col;
        xlSheetGetTopLeftView(sheet,&row,&col);
        row += 1;
        xlSheetSetMergeA(sheet,row,row,col,col+2);
        xlSheetSetMergeA(sheet,row,row,col+3,col+5);
        xlSheetSetMergeA(sheet,row,row,col+6,col+8);
        xlSheetWriteStrA(sheet,row,col,"didload",NULL);
        xlSheetWriteStrA(sheet,row,col+3,"dealloc",NULL);
        xlSheetWriteStrA(sheet,row,col+6,"totload",NULL);
        
        NSArray *array = @[@"Second",@"Mem",@"CPU"];
        for (int i = 0; i < 9; i++) {
            int tempCol = col + i;
            xlSheetWriteStrA(sheet, row+1, tempCol, [array[tempCol % 3] UTF8String], NULL);
        }
        
        int tempRow = row + 2;
        MFControllerPerformanceInfo *controllerPerformanceInfo = lifecyclePerformanceDict[controllerName];
        
        for (int i = 0; i < controllerPerformanceInfo.didloadPerformance.count; i++) {
            xlSheetWriteStrA(sheet, tempRow + i, col, [controllerPerformanceInfo.didloadPerformance[i].intervalSeconds UTF8String], NULL);
            xlSheetWriteStrA(sheet, tempRow + i, col + 1, [[NSString stringWithFormat:@"%.4f",controllerPerformanceInfo.didloadPerformance[i].memoryUsage] UTF8String],NULL);
            xlSheetWriteStrA(sheet, tempRow + i, col + 2, [[NSString stringWithFormat:@"%.4f",controllerPerformanceInfo.didloadPerformance[i].cpuUsage] UTF8String],NULL);
        }
        
        for (int i = 0; i < controllerPerformanceInfo.deallocPerformance.count; i++) {
            xlSheetWriteStrA(sheet, tempRow + i, col + 3, [controllerPerformanceInfo.deallocPerformance[i].intervalSeconds UTF8String], NULL);
            xlSheetWriteStrA(sheet, tempRow + i, col + 4, [[NSString stringWithFormat:@"%.4f",controllerPerformanceInfo.deallocPerformance[i].memoryUsage] UTF8String], NULL);
            xlSheetWriteStrA(sheet, tempRow + i, col + 5, [[NSString stringWithFormat:@"%.4f",controllerPerformanceInfo.deallocPerformance[i].cpuUsage] UTF8String], NULL);
        }
        
        for (int i = 0; i < controllerPerformanceInfo.totloadPerformance.count; i++) {
            xlSheetWriteStrA(sheet, tempRow + i, col + 6, [controllerPerformanceInfo.totloadPerformance[i].intervalSeconds UTF8String], NULL);
            xlSheetWriteStrA(sheet, tempRow + i, col + 7, [[NSString stringWithFormat:@"%.4f",controllerPerformanceInfo.totloadPerformance[i].memoryUsage] UTF8String], NULL);
            xlSheetWriteStrA(sheet, tempRow + i, col + 8, [[NSString stringWithFormat:@"%.4f",controllerPerformanceInfo.totloadPerformance[i].cpuUsage] UTF8String],NULL);
        }
        
//        [self savePic:controllerPerformanceInfo withControllerName:controllerName sheet:sheet book:lifecycleBook row:row col:col+9];
    }
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyyMMdd_HH_mm_ss"];
    NSString *stringFromDate = [formatter stringFromDate:[NSDate date]];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *documentPath =
    [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES) objectAtIndex:0];
    NSString *directryPath = [documentPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/%@",@"PerformanceMonitor",stringFromDate]];
    if (![fileManager fileExistsAtPath:directryPath]) {
        [fileManager createDirectoryAtPath:directryPath withIntermediateDirectories:YES attributes:nil error:nil];
    }

    
    NSString *lifecyclePerformanceFilename = [directryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"lifecycle_%@.xls",stringFromDate]];
    xlBookSave(lifecycleBook, [lifecyclePerformanceFilename UTF8String]);
    xlBookRelease(lifecycleBook);

    
    // sampling
    NSMutableArray<NSString *> *samplingPerformanceControllerNameList = [MFPerformanceMonitorManager sharedManager].performanceModel.samplingPerformanceControllerNameList;
    NSMutableDictionary<NSString *, NSMutableArray<MFPerformanceInfo *> *> *samplingPerformanceDict = [MFPerformanceMonitorManager sharedManager].performanceModel.samplingPerformanceDict;
    
    BookHandle samplingBook = xlCreateBook();
    for (NSString *controllerName in samplingPerformanceControllerNameList) {
        SheetHandle sheet = xlBookAddSheet(samplingBook, [controllerName UTF8String], NULL);
        int row,col;
        xlSheetGetTopLeftView(sheet,&row,&col);
        row += 1;
        
        NSArray *array = @[@"Second",@"Mem",@"CPU"];
        for (int i = 0; i < 3; i++) {
            int tempCol = col + i;
            xlSheetWriteStrA(sheet, row, tempCol, [array[tempCol % 3] UTF8String], NULL);
        }
        
        int tempRow = row + 1;
        NSMutableArray<MFPerformanceInfo *> *samplingPerformanceInfoArray = samplingPerformanceDict[controllerName];
        
        for (int i = 0; i < samplingPerformanceInfoArray.count; i++) {
            xlSheetWriteStrA(sheet, tempRow + i, col, [samplingPerformanceInfoArray[i].intervalSeconds UTF8String], NULL);
            xlSheetWriteStrA(sheet, tempRow + i, col + 1, [[NSString stringWithFormat:@"%.4f",samplingPerformanceInfoArray[i].memoryUsage] UTF8String],NULL);
            xlSheetWriteStrA(sheet, tempRow + i, col + 2, [[NSString stringWithFormat:@"%.4f",samplingPerformanceInfoArray[i].cpuUsage] UTF8String],NULL);
        }
        
    }
    

    NSString *samplingPerformanceFilename = [directryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"sampling_%@.xls",stringFromDate]];
    xlBookSave(samplingBook, [samplingPerformanceFilename UTF8String]);
    xlBookRelease(samplingBook);
    
    // app
    
    BookHandle appBook = xlCreateBook();
    
    SheetHandle sheet = xlBookAddSheet(appBook, "App", NULL);
    int row,col;
    xlSheetGetTopLeftView(sheet,&row,&col);
    row += 1;
    
    NSArray *array = @[@"Second",@"Mem",@"CPU"];
    for (int i = 0; i < 3; i++) {
        int tempCol = col + i;
        xlSheetWriteStrA(sheet, row, tempCol, [array[tempCol % 3] UTF8String], NULL);
    }
    
    int tempRow = row + 1;
    NSMutableArray<MFPerformanceInfo *> *appPerformanceList = [MFPerformanceMonitorManager sharedManager].performanceModel.appPerformanceList;
    
    for (int i = 0; i < appPerformanceList.count; i++) {
        xlSheetWriteStrA(sheet, tempRow + i, col, [appPerformanceList[i].intervalSeconds UTF8String], NULL);
        xlSheetWriteStrA(sheet, tempRow + i, col + 1, [[NSString stringWithFormat:@"%.4f",appPerformanceList[i].memoryUsage] UTF8String],NULL);
        xlSheetWriteStrA(sheet, tempRow + i, col + 2, [[NSString stringWithFormat:@"%.4f",appPerformanceList[i].cpuUsage] UTF8String],NULL);
    }
    
    
    NSString *appPerformanceFilename = [directryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"app_%@.xls",stringFromDate]];
    xlBookSave(appBook, [appPerformanceFilename UTF8String]);
    xlBookRelease(appBook);
}

@end

#endif
