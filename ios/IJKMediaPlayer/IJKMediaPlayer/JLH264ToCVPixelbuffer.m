//
//  JLH264ToCVPixelbuffer.m
//  IJKMediaFramework
//
//  Created by Ezio on 2018/1/2.
//  Copyright © 2018年 bilibili. All rights reserved.
//

#import "JLH264ToCVPixelbuffer.h"
#import <UIKit/UIKit.h>

#include "libavutil/avstring.h"
#include "libavutil/eval.h"
#include "libavutil/mathematics.h"
#include "libavutil/pixdesc.h"
#include "libavutil/imgutils.h"
#include "libavutil/dict.h"
#include "libavutil/parseutils.h"
#include "libavutil/samplefmt.h"
#include "libavutil/avassert.h"
#include "libavutil/time.h"
#include "libavformat/avformat.h"

@interface JLH264ToCVPixelbuffer(){

    NSMutableArray *PArray;
    NSData *dataIFrame;
    
}
@end

@implementation JLH264ToCVPixelbuffer

-(instancetype)init{
    self = [super init];
    if (self) {
        
        PArray = [NSMutableArray array];
        
    }
    
    return self;
}


-(CVPixelBufferRef)h264DataCovertToRefBuffer:(NSData *)h264 WithSize:(CGSize)Isize{
    
    @autoreleasepool{
//        if ([self checkWetherIsIFormat:h264] == NO) {
//
//            if ([self checkWetherIsPFrame:h264] == YES) {
//                [PArray addObject:h264];
//                NSLog(@"addHData");
//            }else{
//                return nil;
//            }
//        }else{
//
//            [PArray removeAllObjects];
//            NSLog(@"removeAll P Data");
//            dataIFrame = h264;
//        }
//        NSLog(@"开始解码");
//        NSMutableData *targetData = [NSMutableData data];
//        [targetData appendData:dataIFrame];
//
//        for (NSData *tmpdata in PArray) {
//            [targetData appendData:tmpdata];
//        }
        
        if ([self checkWetherIsIFormat:h264] == NO) {
            return nil;
        }

        AVFrame *aFrame = NULL;
        AVCodec *codec = NULL;
        AVCodecContext *ctx = NULL;
        uint8_t *byte_buffer = NULL;
        AVPacket pkt;
        CVPixelBufferRef refBuffer = NULL;
        
        int got_frame = 0;
        int byte_buffer_size;
        int result;
        
        av_register_all();
        
        codec = avcodec_find_decoder(AV_CODEC_ID_H264);
        if (!codec) {
            printf("Can't find decoder\n");
            return NULL;
        }
        
        ctx = avcodec_alloc_context3(codec);
        if (!ctx) {
            printf("Can't allocate decoder context\n");
            return NULL;
        }
        
        ctx->time_base.num = 1;
        ctx->frame_number = 1; //每包一个视频帧
        ctx->codec_type = AVMEDIA_TYPE_VIDEO;
        ctx->pix_fmt = AV_PIX_FMT_YUVJ420P;
        ctx->bit_rate = 0;
        ctx->time_base.den = 30;//帧率
        ctx->width = Isize.width;
        ctx->height = Isize.height;
        
        result = avcodec_open2(ctx, codec, NULL);
        if (result<0) {
            printf("Can't open decoder\n");
            return NULL;
        }
        
        aFrame = av_frame_alloc();
        if (!aFrame) {
            printf("Can't allocate frame\n");
            return NULL;
        }
        
        byte_buffer_size = av_image_get_buffer_size(ctx->pix_fmt, ctx->width, ctx->height, 16);
        if(byte_buffer_size<=0)
        {
            printf("Can't get buffer size\n");
            return NULL;
        }
        
        byte_buffer = av_malloc(byte_buffer_size);
        if (!byte_buffer) {
            printf("Can't allocate buffer\n");
            return NULL;
        }
        av_init_packet(&pkt);
        pkt.data = (unsigned char *)[h264 bytes];
        pkt.size = (int)h264.length;
        
        result = avcodec_decode_video2(ctx, aFrame, &got_frame, &pkt);
        if (result<0) {
            printf("Error decoding frame\n");
            return nil;
        }
        if (got_frame) {
            UIImage *image = [UIImage imageWithData:[self convert_yuv_to_jpg:aFrame withCGSize:Isize]];
            //       refBuffer = [self converCVPixelBufferRefFromAVFrame:aFrame];
            refBuffer = [self pixelBufferFromCGImage:image.CGImage];
        }
        
        av_packet_unref(&pkt);
        av_frame_free(&aFrame);
        avcodec_close(ctx);
        avcodec_free_context(&ctx);
        av_freep(&byte_buffer);
        return refBuffer;
    }
}


- (CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image{
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    
    CVPixelBufferRef pxbuffer = NULL;
    
    CGFloat frameWidth = CGImageGetWidth(image);
    CGFloat frameHeight = CGImageGetHeight(image);
    
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,
                                          frameWidth,
                                          frameHeight,
                                          kCVPixelFormatType_32ARGB,
                                          (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef context = CGBitmapContextCreate(pxdata,
                                                 frameWidth,
                                                 frameHeight,
                                                 8,
                                                 CVPixelBufferGetBytesPerRow(pxbuffer),
                                                 rgbColorSpace,
                                                 (CGBitmapInfo)kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    CGContextConcatCTM(context, CGAffineTransformIdentity);
    CGContextDrawImage(context, CGRectMake(0,
                                           0,
                                           frameWidth,
                                           frameHeight),
                       image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;

    
}

- (CVPixelBufferRef)converCVPixelBufferRefFromAVFrame:(AVFrame *)avframe
{
    if (!avframe || !avframe->data[0]) {
        return NULL;
    }
    
    CVPixelBufferRef outputPixelBuffer = NULL;
    
   
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             @(avframe->linesize[0]), kCVPixelBufferBytesPerRowAlignmentKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferOpenGLESCompatibilityKey,
                             [NSDictionary dictionary], kCVPixelBufferIOSurfacePropertiesKey,
                             nil];
    
    
    if (avframe->linesize[1] != avframe->linesize[2]) {
        return  NULL;
    }
    
    size_t srcPlaneSize = avframe->linesize[1]*avframe->height/2;
    size_t dstPlaneSize = srcPlaneSize *2;
    uint8_t *dstPlane = malloc(dstPlaneSize);
    
    // interleave Cb and Cr plane
    for(size_t i = 0; i<srcPlaneSize; i++){
        dstPlane[2*i  ]=avframe->data[1][i];
        dstPlane[2*i+1]=avframe->data[2][i];
    }
    
     printf("srcFrame  width____%d   height____%d \n",avframe->width,avframe->height);
    
    int ret = CVPixelBufferCreate(kCFAllocatorDefault,
                                  avframe->width,
                                  avframe->height,
                                  kCVPixelFormatType_420YpCbCr8Planar,
                                  (__bridge CFDictionaryRef)(options),
                                  &outputPixelBuffer);
    
    CVPixelBufferLockBaseAddress(outputPixelBuffer, 0);
    
    size_t bytePerRowY = CVPixelBufferGetBytesPerRowOfPlane(outputPixelBuffer, 0);
    size_t bytesPerRowUV = CVPixelBufferGetBytesPerRowOfPlane(outputPixelBuffer, 1);
    
    void* base =  CVPixelBufferGetBaseAddressOfPlane(outputPixelBuffer, 0);
    memcpy(base, avframe->data[0], bytePerRowY*avframe->height);
    
    base = CVPixelBufferGetBaseAddressOfPlane(outputPixelBuffer, 1);
    memcpy(base, dstPlane, bytesPerRowUV*avframe->height/2);
    
    CVPixelBufferUnlockBaseAddress(outputPixelBuffer, 0);
    
    free(dstPlane);
    
    if(ret != kCVReturnSuccess)
    {
        NSLog(@"CVPixelBufferCreate Failed");
        return NULL;
    }
    
    return outputPixelBuffer;
}

-(UIImage *)covertH264ToJpeg:(NSData*)hData withCGSize:(CGSize )Isize{
    
    @autoreleasepool{
//        if ([self checkWetherIsIFormat:hData] == NO) {
//
//            if ([self checkWetherIsPFrame:hData] == YES) {
//                [PArray addObject:hData];
//
//            }else{
//                return nil;
//            }
//        }else{
//
//            [PArray removeAllObjects];
//            dataIFrame = hData;
//        }
//
//
//
//        NSMutableData *targetData = [NSMutableData data];
//        [targetData appendData:dataIFrame];
//
//        for (NSData *tmpdata in PArray) {
//            [targetData appendData:tmpdata];
//        }
        if ([self checkWetherIsIFormat:hData] == NO) {
            return nil;
        }
        
        UIImage *outImage;
        
        AVFrame *aFrame = NULL;
        AVCodec *codec = NULL;
        AVCodecContext *ctx = NULL;
        uint8_t *byte_buffer = NULL;
        AVPacket pkt;
        
        int got_frame = 0;
        int byte_buffer_size;
        int result;
        
        av_register_all();
        
        codec = avcodec_find_decoder(AV_CODEC_ID_H264);
        if (!codec) {
            printf("Can't find decoder\n");
            return NULL;
        }
        
        ctx = avcodec_alloc_context3(codec);
        if (!ctx) {
            printf("Can't allocate decoder context\n");
            return NULL;
        }
        
        ctx->time_base.num = 1;
        ctx->frame_number = 1; //每包一个视频帧
        ctx->codec_type = AVMEDIA_TYPE_VIDEO;
        ctx->pix_fmt = AV_PIX_FMT_YUVJ420P;
        ctx->bit_rate = 0;
        ctx->time_base.den = 30;//帧率
        ctx->width = Isize.width;
        ctx->height = Isize.height;
        
        result = avcodec_open2(ctx, codec, NULL);
        if (result<0) {
            printf("Can't open decoder\n");
            
            return NULL;
        }
        
        aFrame = av_frame_alloc();
        if (!aFrame) {
            printf("Can't allocate frame\n");
            goto endDeal;
        }
        
        byte_buffer_size = av_image_get_buffer_size(ctx->pix_fmt, ctx->width, ctx->height, 16);
        if(byte_buffer_size<=0)
        {
            printf("Can't get buffer size\n");
            goto endDeal;
        }
        
        byte_buffer = av_malloc(byte_buffer_size);
        if (!byte_buffer) {
            printf("Can't allocate buffer\n");
            goto endDeal;
        }
        av_init_packet(&pkt);
        pkt.data = (unsigned char *)[hData bytes];
        pkt.size = (int)hData.length;
        result = avcodec_decode_video2(ctx, aFrame, &got_frame, &pkt);
        if (result<0) {
            printf("Error decoding frame\n");
            goto endDeal;
        }
        if (got_frame) {
            outImage = [UIImage imageWithData:[self convert_yuv_to_jpg:aFrame withCGSize:Isize]];
        }
        
        av_packet_unref(&pkt);
        av_frame_free(&aFrame);
        avcodec_close(ctx);
        avcodec_free_context(&ctx);
        av_freep(&byte_buffer);
        return outImage;
        
    endDeal:
        if (ctx)
            avcodec_close(ctx);
        av_packet_unref(&pkt);
        if(aFrame)
            av_frame_free(&aFrame);
        if (byte_buffer)
            av_freep(&byte_buffer);
        
        return outImage;
    }
    
}

-(BOOL)checkWetherIsIFormat:(NSData *)iData{
    
    NSData *headData = [iData subdataWithRange:NSMakeRange(4, 1)];
    NSInteger headInteger = [self dataToInt:headData];
    
    if(headInteger==103){
        return YES;
    }else{
        return NO;
    }
    
}

-(BOOL)checkWetherIsPFrame:(NSData *)data{
    
    NSData *headData = [data subdataWithRange:NSMakeRange(4, 1)];
    NSInteger headInteger = [self dataToInt:headData];
    
    if(headInteger==65){
        return YES;
    }else{
        return NO;
    }
}

-(NSInteger)dataToInt:(NSData *)data{
    
    
    
    NSInteger temp;
    double sum = 0.0;
    NSString * string = [self dataChangeToString:data];
    NSInteger length = string.length;
    
    
    for (int i = 0 ; i < length; i++) {
        NSString * tempStr = [string substringWithRange:NSMakeRange(i, 1)];
        int tempInt = [self StringToInt:tempStr];
        double tempDouble = tempInt * pow(16.0, (double)(length-1-i));
        sum = sum + tempDouble;
    }
    
    temp = (NSInteger)sum;
    return temp;
    
    
}

-(NSString*)dataChangeToString:(NSData*)data{
    
    NSString * string = [NSString stringWithFormat:@"%@",data];
    string = [string stringByReplacingOccurrencesOfString:@"<" withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@">" withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@" " withString:@""];
    return string;
}

-(int)StringToInt:(NSString*)string{
    
    int temp;
    
    temp = [string intValue];
    
    if ([string isEqual:@"a"]||[string isEqual:@"A"]) {
        temp = 10;
    }else if ([string isEqual:@"b"]||[string isEqual:@"B"])
    {
        temp = 11;
    }else if ([string isEqual:@"c"]||[string isEqual:@"C"])
    {
        temp = 12;
    }else if ([string isEqual:@"d"]||[string isEqual:@"D"])
    {
        temp = 13;
    }else if ([string isEqual:@"e"]||[string isEqual:@"E"])
    {
        temp = 14;
    }else if ([string isEqual:@"f"]||[string isEqual:@"F"])
    {
        temp = 15;
    }
    return temp;
}


-(NSData *)convert_yuv_to_jpg:(AVFrame* )pFrame withCGSize:(CGSize )Isize{
    
    AVFormatContext* pFormatCtx;
    AVOutputFormat* fmt;
    AVStream* video_st;
    AVCodecContext* pCodecCtx;
    AVCodec* pCodec;
    AVPacket pkt;
    NSData *targetData = nil;
    int y_size;
    int got_picture=0;
    int ret=0;
    int width = Isize.width;
    int height = Isize.height;
//    printf("width=%d, h=%d\n", width, height);
#ifdef DB_SAVE_JPG
    const char *out_file = "/mnt/sdcard/iframe.jpg";
#endif
    
    pFormatCtx = avformat_alloc_context();
    if(!pFormatCtx){
        printf("pFormatCtx is null\n");
        return nil;
    }
    //Guess format
    fmt = av_guess_format("mjpeg", NULL, NULL);
    if(!fmt){
        printf("fmt is null\n");
        return nil;
    }
    pFormatCtx->oformat = fmt;
    
#ifdef DB_SAVE_JPG
    //logw("111");
    //Output URL
    if (avio_open(&pFormatCtx->pb, out_file, AVIO_FLAG_READ_WRITE) < 0){
        printf("Couldn't open output file.\n");
        return nil;
    }
#endif
    //logw("222");
    video_st = avformat_new_stream(pFormatCtx, 0);
    if (video_st==NULL){
        printf("avformat_new_stream fail\n");
        return nil;
    }
    //logw("333");
    
    pCodecCtx = video_st->codec;
    pCodecCtx->codec_id = fmt->video_codec;
    pCodecCtx->codec_type = AVMEDIA_TYPE_VIDEO;
    pCodecCtx->pix_fmt = AV_PIX_FMT_YUVJ420P;
    pCodecCtx->width = width;
    pCodecCtx->height = height;
    
    pCodecCtx->time_base.num = 1;
    pCodecCtx->time_base.den = 30;
    //logw("444");
    pCodec = avcodec_find_encoder(pCodecCtx->codec_id);
    
    if (!pCodec){
        printf("Codec not found.\n");
        return nil;
    }
    //    logw("555");
    if (avcodec_open2(pCodecCtx, pCodec,NULL) < 0){
        printf("Could not open codec.\n");
        return nil;
    }
#ifdef DB_SAVE_JPG
    //Write Header
    avformat_write_header(pFormatCtx, NULL);
#endif
    //logw("666");
    y_size = pCodecCtx->width * pCodecCtx->height;
    
    av_new_packet(&pkt, y_size * 3);
    //logw("777 pkt =%p, pFrame=%p", pkt, pFrame);
    //Encode
    ret = avcodec_encode_video2(pCodecCtx, &pkt, pFrame, &got_picture);
    //    logw("8888");
    if(ret < 0){
        printf("Encode Error.\n");
        return nil;
    }
    //    logw("9999");
    if (got_picture){
        //logi("pkt data size=%d", pkt.size);
        pkt.stream_index = video_st->index;
        //logi("00 pkt data size=%d", pkt.size);
#ifdef DB_SAVE_JPG
        ret = av_write_frame(pFormatCtx, &pkt);
#endif
        //logi("11 pkt data size=%d", pkt.size);
        targetData = [NSData dataWithBytes:pkt.data length:pkt.size];
        
    }
    av_free_packet(&pkt);
#ifdef DB_SAVE_JPG
    //Write Trailer
    av_write_trailer(pFormatCtx);
    avio_close(pFormatCtx->pb);
#endif
    
    if (video_st){
        avcodec_close(video_st->codec);
    }
    avformat_free_context(pFormatCtx);
    
    return targetData;
}


@end
