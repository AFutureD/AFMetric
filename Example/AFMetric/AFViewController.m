#import "AFViewController.h"
#import "AFBizObject.h"
#import "AFBizTracker.h"
#import <Masonry/Masonry.h>
#import <AFMetric/AFMetric.h>
#import <YYModel/YYModel.h>
#import "AFFoundationKit.h"

@interface AFViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) NSMutableArray<AFBizObject * >*objs;
@property (nonatomic, strong) UITableView * table;
@property (nonatomic, strong) UIButton * randomDelBtn;
@property (nonatomic, strong) UIButton * genBtn;

@end

@implementation AFViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // [AFLogUtil sharedInstance].debugMode = YES;
    
    [self.view addSubview: self.table];
    [self.view addSubview:self.randomDelBtn];
    [self.view addSubview:self.genBtn];
    
    if (@available(iOS 11, *)) {
        [self.randomDelBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
            make.left.equalTo(self.view);
            make.right.equalTo(self.view.mas_centerX);
            make.height.mas_equalTo(40);
        }];
        [self.genBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
            make.left.equalTo(self.view.mas_centerX);
            make.right.equalTo(self.view);
            make.height.mas_equalTo(40);
        }];
        
        
    }
    else {
        [self.randomDelBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.view);
            make.left.equalTo(self.view);
            make.right.equalTo(self.view);
            make.height.mas_equalTo(30);
        }];
    }
    
    [self.table mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view);
        make.left.equalTo(self.view);
        make.right.equalTo(self.view);
        make.bottom.equalTo(self.randomDelBtn.mas_top);
    }];
    
    [AFMetricManager sharedInstance].autoTrimInterval = 5;
    [[AFMetricManager sharedInstance] hookTarget:self withTrackerName:@"AFBizTracker" broadcastEvent:S4S(removeAction)];
}


#pragma mark - tableview delegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"kTableViewCellReuse"];
    cell.textLabel.text = [self.objs objectAtIndex:indexPath.item].name;
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.objs.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"table didSelectRowAtIndexPath: %ld",(long)indexPath.item);
    AFBizObject * tmp = [self.objs objectAtIndex:indexPath.item];
    [tmp bizMethod];
    [tmp bizMethodWithParam:[NSString stringWithFormat:@"%ld",(long)indexPath.item]];
    [tmp bizMethodWithParam:[NSString stringWithFormat:@"%ld",(long)indexPath.item] anotherParam:nil];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark - action

- (void)removeAction {
    if (!self.objs.count) {
        return;
    }
    NSInteger r = arc4random() % self.objs.count;
    AFBizObject * tmp = [self.objs objectAtIndex:r];
    [self.objs removeObject:tmp];
    [self.table reloadData];
    NSLog(@"Random remove: %@", tmp.name);
}

- (void)genAction {
    self.objs = [self prepareData:17];
    // TODO: single bind
    [self.table reloadData];
}

#pragma mark - getter

- (UIButton *)randomDelBtn {
    if (!_randomDelBtn) {
        _randomDelBtn = [UIButton new];
        [_randomDelBtn setTitle:@"tap" forState:UIControlStateNormal];
        [_randomDelBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_randomDelBtn addTarget:self action:@selector(btnAction) forControlEvents:UIControlEventTouchUpInside];
        _randomDelBtn.backgroundColor = [UIColor colorWithRed: 84/255.0 green: 108/255.0 blue: 158/255.0 alpha:1.000];
    }
    return _randomDelBtn;
}

- (UIButton *)genBtn {
    if (!_genBtn) {
        _genBtn = [UIButton new];
        [_genBtn setTitle:@"generate" forState:UIControlStateNormal];
        [_genBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_genBtn addTarget:self action:@selector(genAction) forControlEvents:UIControlEventTouchUpInside];
        _genBtn.backgroundColor = [UIColor colorWithRed: 84/255.0 green: 108/255.0 blue: 158/255.0 alpha:1.000];
    }
    return _genBtn;
}

- (UITableView *)table {
    if (!_table) {
        _table = [[UITableView alloc]init];
        _table.delegate = self;
        _table.dataSource = self;
        [_table registerClass:[UITableViewCell class] forCellReuseIdentifier:@"kTableViewCellReuse"];
    }
    return _table;
}

- (NSMutableArray<AFBizObject *> *)objs {
    if (!_objs) {
        _objs = [self prepareData: 17];
    }
    return _objs;
}

- (NSMutableArray<AFBizObject *> *)prepareData:(NSInteger) size {
    NSMutableArray * res = [NSMutableArray new];
    
    for (NSInteger idx = 0; idx < size; idx++) {
        NSArray * emojis = @[
            @"😀", @"😅", @"🤣", @"😇", @"😘",@"🤪", @"🧐", @"🥳", @"😭", @"😡",
            @"🤯", @"😱", @"🤥", @"😴", @"😷",@"😈", @"🤖"
        ];

        AFBizObject * tmp = [[AFBizObject alloc] initWithName:[emojis objectAtIndex:idx % 17]];
        [res addObject:tmp];
    }
    
    return [res mutableCopy];
}

@end
