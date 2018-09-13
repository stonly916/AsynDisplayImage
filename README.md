# AsynDisplayImage
Asyn display image/render image/draw image with Bitmap Context
 
 简书文章地址：https://www.jianshu.com/p/9b30109b302e
 
 测试异步绘制图片方法，也有单纯的解压图片方法等。
 
 
主要代码，异步绘制图片：
UIImageView(AsynDealImage)

<pre><code>
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
</code></pre>
    
  
