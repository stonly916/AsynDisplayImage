//
//  BitmapXYController.m
//  OffScreenRender
//
//  Created by wanghuiguang on 2018/9/12.
//  Copyright © 2018年 wanghuiguang. All rights reserved.
//

#import "BitmapXYController.h"
#import <CoreText/CoreText.h>

@interface BitmapXYController ()
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) UIImageView *imgView;
@end

@implementation BitmapXYController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(20, 90, 180, 280)];
    self.imgView = imageView;
    imageView.image = [self drawImage];
    [self.view addSubview:imageView];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(15, 395, 290, 44)];
    label.adjustsFontSizeToFitWidth = YES;
    label.textColor = [UIColor redColor];
    label.layer.backgroundColor = [UIColor lightGrayColor].CGColor;
    label.numberOfLines = 2;
    [self.view addSubview:label];
    self.label = label;
    [self setLabeltext:@"UIGraphicsBeginImageContext绘图\ny下坐标系"];
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(15, 435, 290, 50);
    btn.selected = NO;
    [btn setTitle:@"点击显示另一种坐标系" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
}

- (void)btnClick:(UIButton *)btn
{
    btn.selected = !btn.selected;
    [self setLabeltext:btn.selected ? @"CGBitmapContextCreate绘图\ny上坐标系": @"UIGraphicsBeginImageContext绘图\ny下坐标系"];
    self.imgView.image = btn.selected ? [self drawImageWithBitmap] : [self drawImage];
}

- (void)setLabeltext:(NSString *)str
{
    NSMutableParagraphStyle *parag = [[NSMutableParagraphStyle alloc] init];
    parag.maximumLineHeight = 17;
    parag.minimumLineHeight = 17;
    parag.lineHeightMultiple = 1;
    parag.lineSpacing = 5;
    parag.paragraphSpacingBefore = 2;
    parag.paragraphSpacing = 3;
    NSDictionary *dict = @{NSFontAttributeName: [UIFont systemFontOfSize:17],
                           NSParagraphStyleAttributeName: parag,
                           NSForegroundColorAttributeName: [UIColor blueColor],
                           NSAttachmentAttributeName: @(NSTextAlignmentLeft),
                           };
    NSAttributedString *string = [[NSAttributedString alloc] initWithString:str attributes:dict];
    self.label.attributedText = string;
}

//从左上角绘制看看实际图形

- (UIImage *)drawImage
{
    //y下坐标系，UIKit默认坐标系
    UIGraphicsBeginImageContext(CGSizeMake(180, 280));
    
    NSString *imgPath = [[NSBundle mainBundle] pathForResource:@"IMG_09s" ofType:@"png"];
    UIImage *img = [UIImage imageWithContentsOfFile:imgPath];
    //这个方法才是UIKit下应该用的方法，如果你使用CGContextDrawImage那就没办法了，CGContextDrawImage默认使用bitmapContext的y上坐标系
    [img drawInRect:CGRectMake(0, 0, 180, 280)];
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextSetLineWidth(context, 4);
    CGContextAddRect(context, CGRectMake(0, 10, 160, 22));
    CGContextStrokePath(context);
    
    NSAttributedString *string = [[NSAttributedString alloc] initWithString:@"我爱芒果" attributes:myParagraphStyle()];;
    [string drawInRect:CGRectMake(0, 12, 160, 18)];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

NSDictionary *myParagraphStyle()
{
    NSMutableParagraphStyle *parag = [[NSMutableParagraphStyle alloc] init];
    UIFont *font = [UIFont systemFontOfSize:17];
    
    parag.maximumLineHeight = 18.0;
    parag.minimumLineHeight = 18.0;
    parag.lineSpacing = 0;
    parag.paragraphSpacingBefore = 0;
    parag.paragraphSpacing = 0;
    NSDictionary *dict = @{NSFontAttributeName: font,
                           NSParagraphStyleAttributeName: parag,
                           NSForegroundColorAttributeName: [UIColor blueColor],
                           NSAttachmentAttributeName: @(NSTextAlignmentLeft),
                           };
    return dict;
}

- (UIImage *)drawImageWithBitmap
{
    //y上坐标系
    CGContextRef context = CGBitmapContextCreate(NULL, 180, 280, 8, 0, CGColorSpaceCreateDeviceRGB(), kCGBitmapByteOrder32Host | kCGImageAlphaNoneSkipFirst);
    
    NSString *imgPath = [[NSBundle mainBundle] pathForResource:@"IMG_09s" ofType:@"png"];
    UIImage *img = [UIImage imageWithContentsOfFile:imgPath];
    CGContextDrawImage(context, CGRectMake(0, 0, 180, 280), img.CGImage);
    
    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextSetLineWidth(context, 4);
    CGContextAddRect(context, CGRectMake(0, 10, 160, 22));
    CGContextStrokePath(context);
    
//    NSAttributedString *string = [[NSAttributedString alloc] initWithString:@"我爱芒果" attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:18], NSForegroundColorAttributeName: [UIColor blueColor]}];;
//    CFStringRef keys[] = {kCTForegroundColorAttributeName, };
//    CFTypeRef values[] = {[UIColor blueColor].CGColor, };
//    CFDictionaryRef dict = CFDictionaryCreate(kCFAllocatorDefault, (const void **)&keys, (const void **)&values, sizeof(keys)/sizeof(keys[0]), &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);

    CFAttributedStringRef string = CFAttributedStringCreate(kCFAllocatorDefault, CFSTR("我爱芒果"), (__bridge CFDictionaryRef)myParagraphStyle());
    
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString(string);

    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, CGRectMake(0, 12, 160, 18) );

    CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, NULL);
    CTFrameDraw(frame, context);

//    CTLineRef line = CTLineCreateWithAttributedString(string);
//    CGContextSetTextPosition(context, 0, 10.0);
//    CTLineDraw(line, context);
    
    CGPathRelease(path);
    CFRelease(frame);
    CFRelease(framesetter);
    
    CGImageRef imageRef = CGBitmapContextCreateImage(context);
    UIImage *image = [UIImage imageWithCGImage:imageRef];
    
    CGContextRelease(context);
    CGImageRelease(imageRef);
    
    return image;
}

@end
