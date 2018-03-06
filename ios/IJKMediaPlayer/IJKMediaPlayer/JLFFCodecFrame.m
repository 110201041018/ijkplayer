//
//  JLFFCodecFrame.m
//  IJKMediaPlayer
//
//  Created by apple on 2017/12/26.
//  Copyright © 2017年 bilibili. All rights reserved.
//

#import "JLFFCodecFrame.h"
#include "frame_codec.h"
#include "media_meta.h"
#import <AVFoundation/AVFoundation.h>



@implementation JLFFCodecFrame
{
    
    context_t *app_ctx;
    
}

-(instancetype)init{
    
    self = [super init];
    
    if (self) {
    
        app_ctx = malloc(sizeof(context_t));
        
    }
    
    return self;
    
}

-(void)dealloc{
    
    if (app_ctx) {
        free(app_ctx);
    }
    
    
}

/**
 解析缩略图
 
 @param frameData 缩略图数据
 @param dict
 主要包括以下数据：
 dict[@"height"] //视频高
 dict[@"width"]  //视频宽度
 dict[@"name"]   //视频名称
 */
-(void)jlFFonFrameCodeWith:(NSData *)frameData withDict:(NSDictionary *) dict{
    
    int size = (int)frameData.length;
    app_ctx->buf = (unsigned char*)[frameData bytes];
    app_ctx->codec_cb = (on_codec_cb)did_frame_codec;
    app_ctx->error_cb = (on_error_cb)failed_frame_codec;
    app_ctx->width = [dict[@"width"] intValue];
    app_ctx->height = [dict[@"height"] intValue];
    app_ctx->size = size;
    app_ctx->name =(char *)[dict[@"name"] UTF8String];
     int  ret =  decode_h264_frame_to_yuv(app_ctx);
    if (ret!=0) {
        NSDictionary *errdict = @{@"err_msg":@(ret),@"filename":dict[@"name"]};
        [[NSNotificationCenter defaultCenter] postNotificationName:JLFFDECODEFA object:errdict];
        
    }
}

/**
 解析VIDEO获取第一帧图片
 
 @param path 所传入路径
 */
-(void)jlFFonFrameCodeWithVideo:(NSString *)path{

    app_ctx->meta = media_meta_create((const uint8_t*)[path UTF8String]);
    app_ctx->codec_cb = (on_codec_cb)did_video_frame_decode;
    app_ctx->error_cb = (on_error_cb)failed_frame_codec;
    app_ctx->name = (char*)[path UTF8String];
    if (!app_ctx->meta) {
        NSLog(@"malloc meta failed");
        free(app_ctx);
    }
    int ret = decode_video(app_ctx, (char*)[path UTF8String]);
    
    if (ret!=0) {
        NSLog(@"decode error with:%d",ret);
        if (ret!=0) {
            NSDictionary *errdict = @{@"err_msg":@(ret),@"filename":path};
            [[NSNotificationCenter defaultCenter] postNotificationName:JLFFDECODEFA object:errdict];
            
        }
    }
    
}

/**
 获取视频长度
 
 @param filePath 视频路径
 @return duration
 */
-(int)jlFFGetVideoDuration:(NSString *)filePath{
    
    AVURLAsset * asset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:filePath]];
    CMTime   time = [asset duration];
    int seconds = ceil(time.value/time.timescale);
    return seconds;
    
}

static void did_video_frame_decode(context_t *decode_ctx){
    
    
    
    NSData *imgData = [NSData dataWithBytes:decode_ctx->buf length:decode_ctx->size];
    NSString *fileName = [[NSString alloc] initWithUTF8String:decode_ctx->name
                              ];
    
    NSDictionary *dict = @{@"image":imgData,@"filename":[fileName lastPathComponent]};
    [[NSNotificationCenter defaultCenter] postNotificationName:JLFFDECODESU_VIDEO object:dict];
        


    
}



static void did_frame_codec(context_t *decode_ctx){
    

    NSData *imgData = [NSData dataWithBytes:decode_ctx->buf length:decode_ctx->size];
    NSString *fileName = [[NSString alloc] initWithUTF8String:decode_ctx->name
                          ];
    NSDictionary *dict = @{@"image":imgData,@"filename":fileName};
    
    [[NSNotificationCenter defaultCenter] postNotificationName:JLFFDECODESU object:dict];


}

static void failed_frame_codec(const char * err_msg){
    
    NSDictionary *errdict = @{@"err_msg":[NSString stringWithUTF8String:err_msg],@"filename":@"nil"};
    [[NSNotificationCenter defaultCenter] postNotificationName:JLFFDECODEFA object:errdict];
    
}


@end
