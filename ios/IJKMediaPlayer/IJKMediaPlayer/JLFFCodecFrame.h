//
//  JLFFCodecFrame.h
//  IJKMediaPlayer
//
//  Created by apple on 2017/12/26.
//  Copyright © 2017年 bilibili. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// 在解析之后，会通过两个通知回调，分别是成功时的字典对象：NSDictionary *dict = @{@"image":imgd,@"filename":fileName};
//失败时字典对象：NSDictionary *dict = @{@"err_msg":err,@"filename":fileName};
#define JLFFDECODESU          @"JLFFDECODESUCCESS"
#define JLFFDECODEFA          @"JLFFDECODEFAILED"               //缩略图获取失败统一返回
#define JLFFDECODESU_VIDEO    @"JLFFDECODE_VIDEO_OK"            //视频预览图获取成功




@interface JLFFCodecFrame : NSObject



/**
 解析缩略图
 
 @param frameData 缩略图数据
 @param dict
 主要包括以下数据：
 dict[@"height"] //视频高
 dict[@"width"]  //视频宽度
 dict[@"name"]   //视频名称
 */
-(void)jlFFonFrameCodeWith:(NSData *)frameData withDict:(NSDictionary *) dict;

/**
 解析VIDEO获取第一帧图片
 
 @param path 所传入路径
 */
-(void)jlFFonFrameCodeWithVideo:(NSString *)path;

/**
 获取视频长度
 
 @param filePath 视频路径
 @return duration
 */
-(int)jlFFGetVideoDuration:(NSString *)filePath;



@end
