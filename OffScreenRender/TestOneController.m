//
//  TestOneController.m
//  OffScreenRender
//
//  Created by wanghuiguang on 2018/9/5.
//  Copyright © 2018年 wanghuiguang. All rights reserved.
//

#import "TestOneController.h"
#import "AsynDealImage.h"
#import "OffScreenRender-Swift.h"

@interface TestOneController ()<UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *cellDataArray;
@property (nonatomic, strong) UIImage *catchImage;
@end

@implementation TestOneController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self.view addSubview:self.tableView];
    [self.view addFPSWithShowFrame:CGRectMake(260, 88, 50, 45)];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 80;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell"];
    if (nil == cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"UITableViewCell"];
        UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(15, 15, 100, 150)];
        imgView.tag = 998;
        [cell.contentView addSubview:imgView];
    }
    UIImageView *imgView = (id)[cell viewWithTag:998];
    //这里是用imageWithContentsOfFile读取图片，所以每次图片都相当于新图，没有解压和渲染缓存
    NSString *imgPath = self.cellDataArray[indexPath.row%self.cellDataArray.count];
    UIImage *image = [UIImage imageWithContentsOfFile:imgPath];
    
    //这里设置图片
//    @[@"测试普通加载", @"单像素同步绘制", @"单像素异步绘制", @"异步解压图片", @"异步UIGraphic绘制", @"bitmapz绘制"]
    switch (self.choosed) {
        case 0:
            imgView.image = image;
            break;
        case 1:{
            [imgView SynDealImage:image];
            imgView.image = image;
        }
            break;
        case 2:
            [imgView asynDealImage:image type:SYDealImageTypeAsynDrawOnePixel];
            break;
        case 3:
            [imgView asynDealImage:image type:SYDealImageTypeAsynDecompression];
            break;
        case 4:
            //这个方法大量调用会导致内存过大，因为是系统控制上下文的释放，所以有延迟释放。
            [imgView asynDealImage:image type:SYDealImageTypeAsynDraw];
            break;
        case 5:
            [imgView asynDealImage:image type:SYDealImageTypeAsynBitmapDraw];
            break;
        default:
            break;
    }
    
    
    
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 180;
}

- (NSArray *)cellDataArray
{
    if (_cellDataArray) {
        return _cellDataArray;
    }
    
    NSString *imgPath = [[NSBundle mainBundle] pathForResource:@"check_green_2" ofType:@"jpg"];
    NSString *imgPath1 = [[NSBundle mainBundle] pathForResource:@"IMG_0943" ofType:@"JPG"];
    NSString *imgPath2 = [[NSBundle mainBundle] pathForResource:@"IMG_09s" ofType:@"png"];
    NSString *imgPath3 = [[NSBundle mainBundle] pathForResource:@"IMG_999" ofType:@"png"];
    NSString *imgPath4 = [[NSBundle mainBundle] pathForResource:@"IMG_999" ofType:@"png"];
    //这张图非常大
    NSString *imgPath5 = [[NSBundle mainBundle] pathForResource:@"henbang" ofType:@"png"];

    _cellDataArray = @[imgPath, imgPath1, imgPath2, imgPath3, imgPath4, imgPath5];
    return _cellDataArray;
}

- (UITableView *)tableView
{
    if (_tableView) {
        return _tableView;
    }
    
    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    return _tableView;
}

@end
