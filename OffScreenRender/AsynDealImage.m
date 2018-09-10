//
//  AsynDealImage.m
//  OffScreenRender
//
//  Created by wanghuiguang on 2018/9/5.
//  Copyright © 2018年 wanghuiguang. All rights reserved.
//

#import "AsynDealImage.h"
#import <objc/runtime.h>

@implementation UIImageView(AsynDealImage)

- (void)setCurrentImage:(UIImage *)image
{
    objc_setAssociatedObject(self, @selector(currentImage), image, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIImage *)currentImage
{
    return objc_getAssociatedObject(self, @selector(currentImage));
}

-(void)asynDealImage:(UIImage *)image type:(SYDealImageType)type
{
    self.image = nil;
    self.currentImage = image;
    

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *newImage = image;
        if (type == SYDealImageTypeAsynDrawOnePixel) {
            //异步绘制可能会失效，因为在调用dispatch_async后系统可能会删除解压数据和渲染数据。
            //绘制单个像素，来实现解压，系统缓存，并提前渲染
            [UIImageView displayOnePixelImage:image];
        }else if (type == SYDealImageTypeAsynDraw) {
            newImage = [UIImageView displayImageCoreGrahpic:image];
        } else if (type == SYDealImageTypeAsynBitmapDraw) {
            //bitmap绘制整个图片，直接获取解压、提前渲染并优化后的图片
            newImage = [UIImageView imageDecodeByBitmap:image];
        } else if (type == SYDealImageTypeAsynDecompression) {
            //CGImageCreate解压图片
            newImage = [UIImageView dataProviderDecodeImage:image];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.currentImage == image) {
                self.image = newImage;
            }
        });
    });
    
}

+ (UIImage *)imageDecodeByBitmap:(UIImage *)image
{
    //创建一个bitmap的context,并把它设置成为当前正在使用的context
    
    CGImageRef imgRef = image.CGImage;
    size_t width = CGImageGetWidth(imgRef);
    size_t height = CGImageGetHeight(imgRef);
    
    CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(imgRef);

    BOOL hasAlpha = NO;
    if (alphaInfo == kCGImageAlphaPremultipliedLast ||
        alphaInfo == kCGImageAlphaPremultipliedFirst ||
        alphaInfo == kCGImageAlphaLast ||
        alphaInfo == kCGImageAlphaFirst) {
        hasAlpha = YES;
    }
    CGBitmapInfo info = kCGBitmapByteOrder32Host | (hasAlpha ? kCGImageAlphaPremultipliedFirst: kCGImageAlphaNoneSkipFirst);
    //创建一个bitmap的context
    CGContextRef ctx = CGBitmapContextCreate(NULL, width, height, 8, 0, SharedCGColorSpaceGetDeviceRGB(), info);

    CGContextDrawImage(ctx, CGRectMake(0, 0, width, height), imgRef);
    
    CGImageRef cgImage = CGBitmapContextCreateImage(ctx);
    CGContextRelease(ctx);
    
    image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    
    return image;
}

+ (UIImage *)dataProviderDecodeImage:(UIImage *)image
{
    CGImageRef imageRef = image.CGImage;
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    CGColorSpaceRef space = CGImageGetColorSpace(imageRef);
    size_t bitsPerComponent = CGImageGetBitsPerComponent(imageRef);
    size_t bitsPerPixel = CGImageGetBitsPerPixel(imageRef);
    size_t bytesPerRow = CGImageGetBytesPerRow(imageRef);
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
    
    CGDataProviderRef source_provider = CGImageGetDataProvider(imageRef);
    CFDataRef rawData = CGDataProviderCopyData(source_provider); //decode
    CGDataProviderRef provider = CGDataProviderCreateWithCFData(rawData);
    CFRelease(rawData);
    
    imageRef = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow, space, bitmapInfo, provider, NULL, false, kCGRenderingIntentDefault);

    CGDataProviderRelease(provider);
    
    UIImage *newImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    return  newImage;
}

+ (UIImage *)displayImageCoreGrahpic:(UIImage *)image
{
    CGImageRef imageRef = image.CGImage;
    CGFloat width = CGImageGetWidth(imageRef);
    CGFloat height = CGImageGetHeight(imageRef);
    CGFloat scale = [UIScreen mainScreen].scale;
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), NO, scale);
    
//    CGContextRef ctx = UIGraphicsGetCurrentContext();
    //CGContextDrawImage默认使用的是y上坐标，需要变换y下坐标
//    CGContextTranslateCTM(ctx, 0, height);
//    CGContextScaleCTM(ctx, 1.0, -1.0);
//    CGContextDrawImage(ctx, CGRectMake(0, 0, width, height), imageRef);
    
    [image drawInRect:CGRectMake(0, 0, width, height)];
    
    image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}

CGColorSpaceRef SharedCGColorSpaceGetDeviceRGB() {
    static CGColorSpaceRef space;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        space = CGColorSpaceCreateDeviceRGB();
    });
    return space;
}

@end

@implementation UIImageView(SynDealImage)

+ (void)displayOnePixelImage:(UIImage *)image
{
//    UIGraphicsBeginImageContext(CGSizeMake(1, 1));
//    [image drawAtPoint:CGPointZero];
//    UIGraphicsEndImageContext();
//    return;
    CGImageRef cgImage = image.CGImage;
    size_t width = CGImageGetWidth(cgImage);
    size_t height = CGImageGetHeight(cgImage);
    if (width == 0 || height == 0) return;
    
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
    
    CGContextRef context = CGBitmapContextCreate(NULL, 1, 1, bitsPerComponent, 0, SharedCGColorSpaceGetDeviceRGB(), info);
    //解压渲染，但是没有优化
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), cgImage);
    CGContextRelease(context);
}

- (void)SynDealImage:(UIImage *)image
{
    self.image = nil;
    
    //同步绘制, 如果改成异步绘制会失效，因为在调用dispatch_async后系统删除解压数据和渲染数据。
    //绘制单个像素，来实现解压，系统缓存，并提前渲染
    [UIImageView displayOnePixelImage:image];
    self.image = image;
}

@end
