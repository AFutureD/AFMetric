//
//  ViewController.m
//  Benchmark
//
//  Created by 尼诺 on 2021/12/13.
//  Copyright © 2021 ninuo.dong. All rights reserved.
//

#import "ViewController.h"
#import "Benchmark.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [Benchmark benchmark];
    });
}


@end
