/**
 * Description:
 * Author:created by bob on 17-6-7.
 */
//

#ifndef IJKPLAYER_MEDIA_META_H
#define IJKPLAYER_MEDIA_META_H
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

typedef struct {
    int duration;
    int width;
    int height;
    uint8_t path[0];
}av_meta_t;

static const char *DURATION = "duration";
static const char *AUDIO_CODEC = "audio_codec";
static const char *VIDEO_CODEC = "video_codec";
static const char *ICY_METADATA = "icy_metadata";
static const char *ROTATE = "rotate";
static const char *FRAME_RATE = "frame_rate";
static const char *CHAPTER_START_TIME = "chapter_start_time";
static const char *CHAPTER_END_TIME = "chapter_end_time";
static const char *CHAPTER_COUNT = "chapter_count";
static const char *FILE_SIZE = "file_size";
static const char *VIDEO_WIDTH = "video_width";
static const char *VIDEO_HEIGHT = "video_height";

av_meta_t* media_meta_create(const uint8_t *path);
void media_meta_close(av_meta_t *meta);
void media_meta_set_width(av_meta_t *meta, int w);
void media_meta_set_height(av_meta_t *meta, int h);
int media_meta_get_width(av_meta_t *meta);
int media_meta_get_height(av_meta_t *meta);

void media_meta_set_duration(av_meta_t *meta, int d);
int media_meta_get_duration(av_meta_t *meta);

void set_duration(AVFormatContext *ic);
void set_frame_rate(AVFormatContext *ic, AVStream *video_st);
const char* get_media_meta(AVFormatContext *ic, AVStream *audio_st, AVStream *video_st, const char* key);
#endif //IJKPLAYER_MEDIA_META_H
