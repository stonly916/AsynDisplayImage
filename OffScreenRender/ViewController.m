//
//  ViewController.m
//  OffScreenRender
//
//  Created by wanghuiguang on 2018/8/27.
//  Copyright © 2018年 wanghuiguang. All rights reserved.
//

#import "ViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "TestOneController.h"

@interface ViewController ()
@property (nonatomic, strong) UIView *myView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIImage *image = [UIImage imageNamed:@"henbang"];
    NSString *imgPath = [[NSBundle mainBundle] pathForResource:@"henbang" ofType:@"png"];
    NSString *imgPath1 = [[NSBundle mainBundle] pathForResource:@"IMG_0943" ofType:@"JPG"];
    NSString *imgPath2 = [[NSBundle mainBundle] pathForResource:@"IMG_09s" ofType:@"png"];
    NSString *imgPath3 = [[NSBundle mainBundle] pathForResource:@"IMG_999" ofType:@"png"];
    NSString *imgPath4 = [[NSBundle mainBundle] pathForResource:@"check_green_2" ofType:@"jpg"];
    NSArray *array = @[imgPath, imgPath1, imgPath2, imgPath3, imgPath4];
    
    //imageIO读取,读取同时强制解压并缓存
//    [self addImage];
    
//    测试加载渲染速度，绘制单个像素的速度最快，bitmap绘制整张图片最实用(适用异步加载)。
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        for (int i = 0; i<5; i++) {
//
//            for (NSString *imgPath in array) {
//                UIImage *imageF = [UIImage imageWithContentsOfFile:imgPath];
        //正常GPU渲染                                       //190.65, 10.23, 5.65, 0.16, 0.24
//                [self displayImage:imageF];
        //绘制单个像素，来实现解压，系统缓存，并提前渲染            //40.21, 3.21, 0.79, 0.05, 0.05
//                [self displayOnePixelImage:imageF];
        //bitmap绘制整个图片，直接获取解压、提前渲染后的图片   //50.6, 3.75, 0.94, 0.05, 0.04
//                [self displayImageWithBitmap:imageF];
        //CGImageCreate解压图片                              //48.27, 3.06, 0.85, 0.05, 0.05
//                [self displayImageWithCGImage:imageF];
//            }
//            printf("**********\n");
//        }
//    });
    
    NSArray *btnTitles = @[@"测试普通加载", @"单像素同步绘制", @"单像素异步绘制", @"异步解压图片", @"异步UIGraphic绘制", @"bitmapContext绘制"];
    for (NSInteger i = 0; i < btnTitles.count; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.tag = 900 + i;
        btn.frame = CGRectMake(40, 84 + i*65, 180, 50);
        [btn setTitle:btnTitles[i] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:btn];
    }
}

- (void)btnClick:(UIButton *)btn
{
    TestOneController *test = [TestOneController new];
    test.choosed = btn.tag - 900;
    [self.navigationController pushViewController:test animated:YES];
}

- (void)displayImage:(UIImage *)image
{
    CFAbsoluteTime before = CFAbsoluteTimeGetCurrent();
    
    [self drawImage:image];
    
    CFAbsoluteTime after = CFAbsoluteTimeGetCurrent();
    NSLog(@"displayImage: %.2f ms", (after - before) * 1000);
}

- (void)displayOnePixelImage:(UIImage *)image
{
    CFAbsoluteTime timebefore = CFAbsoluteTimeGetCurrent();
    
    CGImageRef cgImage = image.CGImage;
    size_t width = CGImageGetWidth(cgImage);
    size_t height = CGImageGetHeight(cgImage);
    size_t bitsPerComponent = 8;
    CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(cgImage);
    BOOL hasAlpha = NO;
    if (alphaInfo == kCGImageAlphaPremultipliedLast ||
        alphaInfo == kCGImageAlphaPremultipliedFirst ||
        alphaInfo == kCGImageAlphaLast ||
        alphaInfo == kCGImageAlphaFirst) {
        hasAlpha = YES;
    }
    CGBitmapInfo info = kCGBitmapByteOrder32Host | (hasAlpha ? kCGImageAlphaPremultipliedFirst: kCGImageAlphaNoneSkipFirst);
    
    CGContextRef context = CGBitmapContextCreate(NULL, 1, 1, bitsPerComponent, 0, SYCGColorSpaceGetDeviceRGB(), info);
    //解压渲染，但是没有优化
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), cgImage);
    CGContextRelease(context);
//    free(data);
    
    
    CFAbsoluteTime before = CFAbsoluteTimeGetCurrent();
    NSLog(@"displayOnePixelImage-before: %.2f ms", (before - timebefore) * 1000);
    [self drawImage:image];
    CFAbsoluteTime after = CFAbsoluteTimeGetCurrent();
    NSLog(@"displayOnePixelImage: %.2f ms", (after - before) * 1000);
}

- (void)displayImageWithBitmap:(UIImage *)image
{
    UIImage * newImage = [self imageDecodeByBitmap:image];
    CFAbsoluteTime before = CFAbsoluteTimeGetCurrent();
    [self drawImage:newImage];
    CFAbsoluteTime after = CFAbsoluteTimeGetCurrent();
    NSLog(@"displayImageWithBitmap: %.2f ms", (after - before) * 1000);
}

- (void)displayImageWithCGImage:(UIImage *)image
{
    image = [self dataProviderDecodeImage:image];
    
    CFAbsoluteTime before = CFAbsoluteTimeGetCurrent();
    [self drawImage:image];
    CFAbsoluteTime after = CFAbsoluteTimeGetCurrent();
    NSLog(@"displayImageWithCGImage: %.2f ms", (after - before) * 1000);
}

- (UIImage *)imageDecodeByBitmap:(UIImage *)image
{
    CFAbsoluteTime timebefore = CFAbsoluteTimeGetCurrent();
    //创建一个bitmap的context,并把它设置成为当前正在使用的context
//    UIGraphicsBeginImageContextWithOptions(CGSizeMake(160, 220), YES, [UIScreen mainScreen].scale);
//    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGImageRef imgRef = image.CGImage;
    size_t width = CGImageGetWidth(imgRef);
    size_t height = CGImageGetHeight(imgRef);
    
    //这里*4是表示颜色分量是4，因为使用的是CGColorSpaceCreateDeviceRGB()和kCGImageByteOrder32Little|kCGImageAlphaNoneSkipFirst，
    //如果使用CGColorSpaceCreateDeviceGray()和kCGImageAlphaNone，那么这里的分量就是*1了，bytesPerRow也要改为160*1。
//    size_t dataLength = width * height * 4;
//    void *data = calloc(dataLength, sizeof(uint32_t));
    
    CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(imgRef);
//    size_t bitsPerComponent = 8;
//    size_t bitsPerPixel = 4*8;
//    size_t bytesPerRow = width * 4;
    BOOL hasAlpha = NO;
    if (alphaInfo == kCGImageAlphaPremultipliedLast ||
        alphaInfo == kCGImageAlphaPremultipliedFirst ||
        alphaInfo == kCGImageAlphaLast ||
        alphaInfo == kCGImageAlphaFirst) {
        hasAlpha = YES;
    }
    CGBitmapInfo info = kCGBitmapByteOrder32Host | (hasAlpha ? kCGImageAlphaPremultipliedFirst: kCGImageAlphaNoneSkipFirst);
//    CGColorSpaceRef space = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    //创建一个bitmap的context
    CGContextRef ctx = CGBitmapContextCreate(NULL, width, height, 8, 0, SYCGColorSpaceGetDeviceRGB(), info);
//    CGColorSpaceRelease(space);
    
    //ImageContext是y上坐标，需要变换y下坐标
//    CGContextTranslateCTM(ctx, 0, 220);
//    CGContextScaleCTM(ctx, 1.0, -1.0);
    
    CGContextDrawImage(ctx, CGRectMake(0, 0, width, height), imgRef);
//    CGContextSetLineWidth(ctx, 15);
//    CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithRed:0.01 green:0.2 blue:1 alpha:1].CGColor);
//    CGContextAddArc(ctx, 60, 110, 40, 0, 2*M_PI, 1);
//    CGContextStrokePath(ctx);
//    CGContextDrawPath(ctx, kCGPathStroke);
    
    
//    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
    CGImageRef cgImage = CGBitmapContextCreateImage(ctx);
    CGContextRelease(ctx);
//    free(data);
    
    image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    
    CFAbsoluteTime timeafter = CFAbsoluteTimeGetCurrent();
    NSLog(@"imageDecodeByBitmap-before: %.2f ms", (timeafter - timebefore) * 1000);
    return image;
}

- (UIImage *)dataProviderDecodeImage:(UIImage *)image
{
    CGImageRef imageRef = image.CGImage;
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    CGColorSpaceRef space = CGImageGetColorSpace(imageRef);
    size_t bitsPerComponent = CGImageGetBitsPerComponent(imageRef);
    size_t bitsPerPixel = CGImageGetBitsPerPixel(imageRef);
    size_t bytesPerRow = CGImageGetBytesPerRow(imageRef);
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
    
    CGDataProviderRef provider = CGImageGetDataProvider(imageRef);
    CFDataRef rawData = CGDataProviderCopyData(provider); //decode
    provider = CGDataProviderCreateWithCFData(rawData);
    CFRelease(rawData);
    
    //绿色
//    const CGFloat decodes[3] = {0.5, 1, 0.8};
    
//    const CGFloat decodes[6] = {0.1, 0.1, 0,
//                                0.2, 0.5, 0.8};
    imageRef = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow, space, bitmapInfo, provider, NULL, false, kCGRenderingIntentDefault);
    CGDataProviderRelease(provider);
    UIImage *newImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    return  newImage;
}

- (void)displayImageCoreGrahpic:(UIImage *)image
{
    
}

- (void)addImage
{
    NSString *imgPath = [[NSBundle mainBundle] pathForResource:@"IMG_0943" ofType:@"JPG"];
    
    NSDictionary *options = @{(__bridge id)kCGImageSourceShouldCache: @YES};
    
    CGDataProviderRef provider = CGDataProviderCreateWithURL((__bridge CFURLRef)[NSURL fileURLWithPath:imgPath]);
    CGImageSourceRef source = CGImageSourceCreateWithDataProvider(provider, NULL);
    CGImageRef imageRef = CGImageSourceCreateImageAtIndex(source, 0,(__bridge CFDictionaryRef)options);
    
    CGDataProviderRelease(provider);
    CGImageRelease(imageRef);
    CFRelease(source);
}

CGColorSpaceRef SYCGColorSpaceGetDeviceRGB() {
    static CGColorSpaceRef space;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        space = CGColorSpaceCreateDeviceRGB();
    });
    return space;
}

- (void)drawImage:(UIImage *)image {
    UIGraphicsBeginImageContext(image.size);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    //保存上下文状态
    CGContextSaveGState(context);
    CGContextSetShouldAntialias(context, NO);
    CGContextSetInterpolationQuality(context, kCGInterpolationNone);
    CGContextSetBlendMode(context, kCGBlendModeCopy);
    
    [image drawAtPoint:CGPointZero];
    //回复上下文状态
    CGContextRestoreGState(context);
    UIGraphicsEndImageContext();
}

@end
