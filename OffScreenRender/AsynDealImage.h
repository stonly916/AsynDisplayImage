//
//  AsynDealImage.h
//  OffScreenRender
//
//  Created by wanghuiguang on 2018/9/5.
//  Copyright © 2018年 wanghuiguang. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, SYDealImageType) {
    SYDealImageTypeAsynDraw,        //异步使用UICoreGraphic绘制图片
    SYDealImageTypeAsynDrawOnePixel,    //同步绘制单个像素
    SYDealImageTypeAsynBitmapDraw,  //异步使用Bitmap绘制图片
    SYDealImageTypeAsynDecompression,//异步解压图片
};

@interface UIImageView(AsynDealImage)
- (void)asynDealImage:(UIImage *)image type:(SYDealImageType)type;
@end


@interface UIImageView(SynDealImage)

+ (void)displayOnePixelImage:(UIImage *)image;
- (void)SynDealImage:(UIImage *)image;

@end
