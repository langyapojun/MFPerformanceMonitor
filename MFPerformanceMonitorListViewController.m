//
//  MFPerformanceMonitorListViewController.m
//  MakeFriends
//
//  Created by Vic on 15/8/16.
//
//

#import "MFPerformanceMonitorListViewController.h"
#import "MFPerformanceMonitorManager.h"
#import "MFPerformanceModel.h"
#import "MFPerformanceMonitorLifecycleDetailViewController.h"
#import "MFPerformanceMonitorSamplingDetailViewController.h"

#if _INTERNAL_MFPM_ENABLED

static NSString * const kMFPerformanceMonitorListTableViewCellIdentifier = @"kMFPerformanceMonitorListTableViewCellIdentifier";

@interface MFPerformanceMonitorListViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<NSString *> *performanceControllerNameList;

@end

@implementation MFPerformanceMonitorListViewController

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
    [self initDatas];
    [self initViews];
}

- (void)initViews
{
    self.title = _performanceMonitorType == MFPerformanceMonitorTypeLifeCycle ? @"Controller内存变化" : @"Controller定时采样";
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    [self.view addSubview:tableView];
    _tableView = tableView;
    tableView.backgroundColor = [UIColor whiteColor];
    tableView.rowHeight = 44;
    tableView.delegate = self;
    tableView.dataSource = self;
    [tableView reloadData];
}

- (void)initDatas
{
    if (_performanceMonitorType == MFPerformanceMonitorTypeSampling) {
        _performanceControllerNameList = [MFPerformanceMonitorManager sharedManager].performanceModel.samplingPerformanceControllerNameList;
        return;
    }
    
    NSMutableArray *tempList = [NSMutableArray arrayWithArray:[MFPerformanceMonitorManager sharedManager].performanceModel.lifecyclePerformanceControllerNameList];
    _performanceControllerNameList = [NSMutableArray arrayWithCapacity:tempList.count];
    
    // 过滤只有一条数据的情况，只有一条数据没法画图也没法对比
    for (NSString *controllerName in tempList) {
        NSMutableDictionary<NSString *, NSMutableDictionary *> *lifecyclePerformanceDict = [MFPerformanceMonitorManager sharedManager].performanceModel.lifecyclePerformanceDict;
        NSMutableDictionary<NSString *, NSMutableArray *> *controllerPerformanceInfo = lifecyclePerformanceDict[controllerName];
        if (!(controllerPerformanceInfo[kMFPerformanceMonitorLifecycleDidloadKey].count < 2 && controllerPerformanceInfo[kMFPerformanceMonitorLifecycleDidloadKey].count < 2 && controllerPerformanceInfo[kMFPerformanceMonitorLifecycleDidloadKey].count < 2)) {
            [_performanceControllerNameList addObject:controllerName];
        }
    }
}

#pragma mark - tableviewDelegates

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _performanceControllerNameList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kMFPerformanceMonitorListTableViewCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kMFPerformanceMonitorListTableViewCellIdentifier];
    }
    
    cell.textLabel.font = [UIFont systemFontOfSize:14];
    cell.textLabel.text = _performanceControllerNameList[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (_performanceMonitorType == MFPerformanceMonitorTypeLifeCycle) {
        MFPerformanceMonitorLifecycleDetailViewController *detailVC = [MFPerformanceMonitorLifecycleDetailViewController new];
        detailVC.controllerName = _performanceControllerNameList[indexPath.row];
        [self.navigationController pushViewController:detailVC animated:YES];
    } else {
        MFPerformanceMonitorSamplingDetailViewController *detailVC = [MFPerformanceMonitorSamplingDetailViewController new];
        detailVC.controllerName = _performanceControllerNameList[indexPath.row];
        [self.navigationController pushViewController:detailVC animated:YES];
    }

}

@end

#endif