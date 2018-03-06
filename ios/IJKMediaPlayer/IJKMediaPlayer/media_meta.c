/**
 * Description:
 * Author:created by bob on 17-6-7.
 */
//

#include "media_meta.h"


void set_duration(AVFormatContext *ic) {
	char value[30] = "0";
	int duration = 0;

	if (ic) {
		if (ic->duration != AV_NOPTS_VALUE) {
			duration = ((ic->duration / AV_TIME_BASE) * 1000);
		}
	}

	sprintf(value, "%d", duration);
	av_dict_set(&ic->metadata, DURATION, value, 0);
}

void set_frame_rate(AVFormatContext *ic, AVStream *video_st) {
	char value[30] = "0";

	if (video_st && video_st->avg_frame_rate.den && video_st->avg_frame_rate.num) {
		double d = av_q2d(video_st->avg_frame_rate);
		uint64_t v = lrintf(d * 100);
		if (v % 100) {
			sprintf(value, "%3.2f", d);
		} else if (v % (100 * 1000)) {
			sprintf(value,  "%1.0f", d);
		} else {
			sprintf(value, "%1.0fk", d / 1000);
		}

	    av_dict_set(&ic->metadata, FRAME_RATE, value, 0);
	}
}

const char* get_media_meta(AVFormatContext *ic, AVStream *audio_st, AVStream *video_st, const char* key) {
    char* value = NULL;

	if (!ic) {
		return value;
	}

	if (key) {
		if (av_dict_get(ic->metadata, key, NULL, AV_DICT_MATCH_CASE)) {
			value = av_dict_get(ic->metadata, key, NULL, AV_DICT_MATCH_CASE)->value;
		} else if (audio_st && av_dict_get(audio_st->metadata, key, NULL, AV_DICT_MATCH_CASE)) {
			value = av_dict_get(audio_st->metadata, key, NULL, AV_DICT_MATCH_CASE)->value;
		} else if (video_st && av_dict_get(video_st->metadata, key, NULL, AV_DICT_MATCH_CASE)) {
			value = av_dict_get(video_st->metadata, key, NULL, AV_DICT_MATCH_CASE)->value;
		}
	}

	return value;
}

av_meta_t* media_meta_create(const uint8_t *path)
{
    printf("%s\n", __func__);
    av_meta_t* meta = NULL;
    if (path && strlen(path)) {
        meta = calloc(1, sizeof(av_meta_t) + sizeof(uint8_t) * strlen(path) + 1);
        sprintf(meta->path, "%s", path);
    } else {
        meta = calloc(1, sizeof(av_meta_t));
    }
    return meta;
}

void media_meta_close(av_meta_t *meta)
{
    printf("%s\n", __func__);
    if(meta) free(meta);
    meta = NULL;
}
void media_meta_set_width(av_meta_t *meta, int w)
{
    if(meta) meta->width = w;
}
void media_meta_set_height(av_meta_t *meta, int h)
{
    if(meta) meta->height = h;
}
int media_meta_get_width(av_meta_t *meta)
{
    if(meta) return meta->width;
    else return 0;
}
int media_meta_get_height(av_meta_t *meta)
{
    if(meta) return meta->height;
    else return 0;
}
void media_meta_set_duration(av_meta_t *meta, int d)
{
    if(meta) meta->duration = d;
}
int media_meta_get_duration(av_meta_t *meta)
{
    if(meta) return meta->duration;
    else return 0;
}
