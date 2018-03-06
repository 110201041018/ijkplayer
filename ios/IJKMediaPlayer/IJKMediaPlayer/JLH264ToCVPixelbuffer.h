//
//  JLH264ToCVPixelbuffer.h
//  IJKMediaFramework
//
//  Created by Ezio on 2018/1/2.
//  Copyright © 2018年 bilibili. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreVideo/CoreVideo.h>

@interface JLH264ToCVPixelbuffer : NSObject


/**
 把H264的I帧转换成CVPixelBufferRef

 @param h264 h264数据
 @param Isize 图片尺码
 @return CVPixelBufferRef
 */
-(CVPixelBufferRef )h264DataCovertToRefBuffer:(NSData *)h264 WithSize:(CGSize)Isize;

/**
 把h264数据的I帧转换成UIimage

 @param hData h264数据
 @param Isize 图片尺码
 @return CVPixelBufferRef
 */
-(UIImage *)covertH264ToJpeg:(NSData*)hData withCGSize:(CGSize )Isize;

@end
