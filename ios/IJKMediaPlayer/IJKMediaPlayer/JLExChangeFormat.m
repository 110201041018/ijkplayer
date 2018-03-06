//
//  JLExChangeFormat.m
//  IJKMediaFramework
//
//  Created by apple on 2017/12/25.
//  Copyright © 2017年 bilibili. All rights reserved.
//

#import "JLExChangeFormat.h"
#include "libavformat/avformat.h"
#include "libavutil/mathematics.h"

#include "libavcodec/avcodec.h"
#include "libavformat/avformat.h"
#include "libavfilter/avfiltergraph.h"
#include "libavfilter/avfilter.h"
#include "libavfilter/buffersink.h"
#include "libavfilter/buffersrc.h"
#include "libavutil/avutil.h"
#include "libavutil/opt.h"
#include "libavutil/pixdesc.h"

#import "ECGodExChangeFrame.h"

@implementation JLExChangeFormat
{
    AVOutputFormat *ofmat;
    AVFormatContext *ifmt_ctx;
    AVFormatContext *ofmt_ctx;
    AVPacket pkt;
}

-(instancetype)init{
    self = [super init];
    if (self) {
        ofmat = NULL;
        ifmt_ctx = NULL;
        ofmt_ctx = NULL;
        
        
    }
    return self;
}



-(void)exChangeWithInput:(NSString *)inputPath ToOutput:(NSString *)outputPath{
    
    const char *in_filename, *out_filename;
    int ret,i;
    
    in_filename = (char *)[inputPath UTF8String];
    out_filename = (char *)[outputPath UTF8String];
    
    //注册解码器
    av_register_all();
    //input File
    if ((ret = avformat_open_input(&ifmt_ctx, in_filename, 0, 0)) < 0) {
        printf( "Could not open input file.\n");
        goto end;
    }
    if ((ret = avformat_find_stream_info(ifmt_ctx, 0)) < 0) {
        printf("Failed to retrieve input stream information.\n");
        goto end;
    }
    
    av_dump_format(ifmt_ctx, 0, in_filename, 0);
    avformat_alloc_output_context2(&ofmt_ctx, NULL, NULL, out_filename);
    if (!ofmt_ctx) {
        printf("Could not create output context \n");
        ret = AVERROR_UNKNOWN;
        goto end;
    }
    ofmat = ofmt_ctx->oformat;
    for (i = 0; i<ifmt_ctx->nb_streams; i++) {
        AVStream *in_stream = ifmt_ctx->streams[i];
        AVStream *out_stream = avformat_new_stream(ofmt_ctx, in_stream->codec->codec);
        if (!out_stream) {
            printf("Failed alloc output stream \n");
            ret = AVERROR_UNKNOWN;
            goto end;
        }
        //复制AVcodecontext 的设置
        ret = avcodec_copy_context(out_stream->codec, in_stream->codec);
        if (ret<0) {
            printf("Failed to copy context from input to output stream codec context \n");
            goto end;
        }
        out_stream->codec->codec_tag = 0;
        if (ofmt_ctx->oformat->flags & AVFMT_GLOBALHEADER) {
            out_stream->codec->flags |= CODEC_FLAG_GLOBAL_HEADER;
        }
    }
    
    //输出一下格式------------------
    av_dump_format(ofmt_ctx, 0, out_filename, 1);
    //打开输入文件
    if (!(ofmat->flags & AVFMT_NOFILE)) {
        ret = avio_open(&ofmt_ctx->pb, out_filename, AVIO_FLAG_WRITE);
        if (ret < 0) {
            printf("Could not open output file '%s' \n",out_filename);
            goto end;
        }
    }
    
    //写文件头
    ret =  avformat_write_header(ofmt_ctx, NULL);
    if (ret < 0) {
        printf("Error occurred when opening output file\n");
        goto end;
    }
    int frame_index = 0;
    while (1) {
        AVStream *in_stream, *out_stream;
        ret = av_read_frame(ifmt_ctx, &pkt);
        if (ret < 0) {
            break;
        }
        in_stream = ifmt_ctx->streams[pkt.stream_index];
        out_stream = ofmt_ctx->streams[pkt.stream_index];
        //转换PTS/DTS（Convert PTS/DTS）
        pkt.pts = av_rescale_q_rnd(pkt.pts, in_stream->time_base, out_stream->time_base, (AV_ROUND_NEAR_INF|AV_ROUND_PASS_MINMAX));
        pkt.dts = av_rescale_q_rnd(pkt.dts, in_stream->time_base, out_stream->time_base, (AV_ROUND_NEAR_INF|AV_ROUND_PASS_MINMAX));
        pkt.duration = av_rescale_q(pkt.duration, in_stream->time_base, out_stream->time_base);
        pkt.pos = -1;
        
        //写入（Write）
        ret = av_interleaved_write_frame(ofmt_ctx, &pkt);
        if (ret < 0) {
            printf( "Error muxing packet\n");
            break;
        }
        printf("Write %8d frames to output file\n",frame_index);
        
        av_packet_unref(&pkt);
        frame_index++;
    }
    
    //Write file trailer
    av_write_trailer(ofmt_ctx);
    NSLog(@"TransOver");
    
end:
    avformat_close_input(&ifmt_ctx);
    if (ofmt_ctx && !(ofmat->flags & AVFMT_NOFILE)) {
        avio_close(ofmt_ctx->pb);
    }
    avformat_free_context(ofmt_ctx);
    if (ret < 0 && ret != AVERROR_EOF) {
        printf("ERROR OCCURRED.\n");
    }
    
}






-(void)JLFrameExChangeWithInput:(NSString *)inputPath ToOutPut:(NSString *)outputPath{
    
    ECGodExChangeFrame *god = [[ECGodExChangeFrame alloc] init];
    [god ECGodExChangeWithInput:inputPath ToOutPut:outputPath];
    
}





@end
