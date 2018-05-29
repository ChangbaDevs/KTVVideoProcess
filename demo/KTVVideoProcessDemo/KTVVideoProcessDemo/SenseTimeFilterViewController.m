//
//  SenseTimeFilterViewController.m
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/4/28.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "SenseTimeFilterViewController.h"
#import "KTVVPVideoCamera.h"
#import "KTVVPSerialPipeline.h"
#import "KTVVPConcurrentPipeline.h"
#import "KTVVPFrameView.h"
#import "KTVVPSenseTimeFilter.h"
#import "KTVVPEffectFilter.h"
#import "KTVVPTransformFilter.h"

@interface SenseTimeFilterViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) KTVVPContext * context;
@property (nonatomic, strong) KTVVPVideoCamera * videoCamera;
@property (nonatomic, strong) KTVVPSerialPipeline * pipeline;
@property (nonatomic, strong) KTVVPFrameView * frameView;

@property (nonatomic, strong) KTVVPSenseTimeFilter * senseTimeFilter;
@property (nonatomic, strong) KTVVPEffectFilter * effectFilter;
@property (nonatomic, strong) UITableView * chooseFilterTableView;
@property (nonatomic, strong) KTVVPFilter * currentFilter;

@end

@implementation SenseTimeFilterViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.context = [[KTVVPContext alloc] init];
    
    self.frameView = [[KTVVPFrameView alloc] initWithContext:self.context];
    self.frameView.frame = self.view.bounds;
    [self.view insertSubview:self.frameView atIndex:0];
    
    self.pipeline = [[KTVVPSerialPipeline alloc] initWithContext:self.context
                                                   filterClasses:@[[KTVVPSenseTimeFilter class],
                                                                   [KTVVPEffectFilter class],
                                                                   [KTVVPTransformFilter class]]];
    __weak typeof(self) weakSelf = self;
    [self.pipeline setFilterConfigurationCallback:^(__kindof KTVVPFilter * filter, NSInteger filterIndexInPipiline, NSInteger pipelineIndex)
     {
        if ([filter isKindOfClass:[KTVVPSenseTimeFilter class]])
        {
            weakSelf.senseTimeFilter = filter;
        }
        else if ([filter isKindOfClass:[KTVVPEffectFilter class]])
        {
            weakSelf.effectFilter = filter;
        }
    }];
    [self.pipeline addOutput:self.frameView];
    [self.pipeline setupIfNeeded];
    
    self.videoCamera = [[KTVVPVideoCamera alloc] init];
    self.videoCamera.pipeline = self.pipeline;
    
    [self.videoCamera start];
}

- (IBAction)senseTimeFilterAction:(UIButton *)sender
{
    self.currentFilter = self.senseTimeFilter;
    [self reloadTableView];
}

- (IBAction)ktvFilterAction:(UIButton *)sender
{
    self.currentFilter = self.effectFilter;
    [self reloadTableView];
}

- (void)reloadTableView
{
    if (!self.chooseFilterTableView)
    {
        self.chooseFilterTableView = [[UITableView alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 100,
                                                                                   0,
                                                                                   100,
                                                                                   [UIScreen mainScreen].bounds.size.height)];
        self.chooseFilterTableView.delegate = self;
        self.chooseFilterTableView.dataSource = self;
        self.chooseFilterTableView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        [self.chooseFilterTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
        self.chooseFilterTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        [self.view addSubview:self.chooseFilterTableView];
    }
    self.chooseFilterTableView.hidden = NO;
    [self.chooseFilterTableView reloadData];
}

static NSArray * senseTimeFilterNames = nil;
static NSArray * ktvFilterNames = nil;

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ktvFilterNames = @[@"无", @"穿越", @"黑白", @"清新", @"复古", @"清凉", @"优雅", @"日系"];
        NSBundle * bundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"filters" ofType:@"bundle"]];
        NSMutableArray * array = [NSMutableArray arrayWithArray:@[@"无"]];
        [array addObjectsFromArray:[bundle pathsForResourcesOfType:@"model" inDirectory:nil]];
        senseTimeFilterNames = array;
    });
    
    if (self.currentFilter == self.senseTimeFilter)
    {
        return senseTimeFilterNames.count;
    }
    else if (self.currentFilter == self.effectFilter)
    {
        return ktvFilterNames.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    cell.backgroundColor = [UIColor clearColor];
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    NSString * name = nil;
    if (self.currentFilter == self.senseTimeFilter)
    {
        NSString * path = [senseTimeFilterNames objectAtIndex:indexPath.row];
        name = [[path.lastPathComponent stringByReplacingOccurrencesOfString:@"filter_style_" withString:@""] stringByReplacingOccurrencesOfString:@".model" withString:@""];
    }
    else if (self.currentFilter == self.effectFilter)
    {
        name = [ktvFilterNames objectAtIndex:indexPath.row];
    }
    cell.textLabel.text = name;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.currentFilter == self.senseTimeFilter)
    {
        if (indexPath.row == 0)
        {
            self.senseTimeFilter.filterPath = nil;
        }
        else
        {
            NSString * path = [senseTimeFilterNames objectAtIndex:indexPath.row];
            self.senseTimeFilter.filterPath = path;
            self.effectFilter.type = 0;
        }
    }
    else if (self.currentFilter == self.effectFilter)
    {
        self.effectFilter.type = indexPath.row;
        self.senseTimeFilter.filterPath = nil;
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    self.chooseFilterTableView.hidden = YES;
}

@end
