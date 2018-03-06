/**
 * Description:
 * Author:created by bob on 17-5-30.
 */
//

#ifndef IJKPLAYER_JLCONVERTER_H
#define IJKPLAYER_JLCONVERTER_H
#include <stdint.h>
#include "media_meta.h"
//int decode_h264_frame(unsigned char *buf, int len);
//int decode_h264_frame(unsigned char *data, int len, int w, int h);
//int convert_to_jpg(uint8_t* data, int len, int width, int height);
//int decode_h264_frame_to_yuv(uint8_t* data, int len, int width, int height);

typedef void (*on_codec_cb)(void *);
typedef void (*on_error_cb)(const char *);

typedef struct {
    int width;
    int height;
    int size;
    on_codec_cb codec_cb;
    on_error_cb error_cb;
    av_meta_t *meta;
    uint8_t* buf;
    char *name;
}context_t;

int decode_h264_frame_to_yuv(context_t *);
int decode_video(context_t *app_ctx, const char *input_filename);


#endif //IJKPLAYER_JLCONVERTER_H
