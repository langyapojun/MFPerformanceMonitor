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
@end

#endif
