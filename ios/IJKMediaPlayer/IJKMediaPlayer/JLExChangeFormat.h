//
//  JLExChangeFormat.h
//  IJKMediaFramework
//
//  Created by apple on 2017/12/25.
//  Copyright © 2017年 bilibili. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JLExChangeFormat : NSObject


/**
 转换编码

 @param inputPath 原始视频文件
 @param outputPath 目标视频文件（.mov）
 已实现异步转换，通过通知返回
 @"JL_EXCHANGE_FRAME_FAILED"
 @"JL_EXCHANGE_FRAME_SUCCEED"
 
 */
-(void)JLFrameExChangeWithInput:(NSString *)inputPath ToOutPut:(NSString *)outputPath;


@end
