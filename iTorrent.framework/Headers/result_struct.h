//
//  result_struct.h
//  iTorrent
//
//  Created by  XITRIX on 14.05.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

#ifndef result_struct_h
#define result_struct_h

typedef struct Torrent {
    char * _Nonnull name;
    char * _Nonnull state;
    char * _Nonnull hash;
    char * _Nonnull creator;
    char * _Nonnull comment;
    float progress;
    long long total_wanted;
    long long total_wanted_done;
    int download_rate;
    int upload_rate;
    long long total_download;
    long long total_upload;
    int num_seeds;
    int num_peers;
    long long total_size;
    long long total_done;
    time_t creation_date;
    int is_paused;
    int is_finished;
    int is_seed;
    int has_metadata;
    int sequential_download;
    int num_pieces;
    int * _Nonnull pieces;
} Torrent;

typedef struct Result {
    int count;
    char * _Nullable * _Nonnull name;
    char * _Nullable * _Nonnull state;
    char * _Nullable * _Nonnull hash;
    char * _Nullable * _Nonnull creator;
    char * _Nullable * _Nonnull comment;
    float * _Nonnull progress;
    long long * _Nonnull total_wanted;
    long long * _Nonnull total_wanted_done;
    int * _Nonnull download_rate;
    int * _Nonnull upload_rate;
    long long * _Nonnull total_download;
    long long * _Nonnull total_upload;
    int * _Nonnull num_seeds;
    int * _Nonnull num_peers;
    long long * _Nonnull total_size;
    long long * _Nonnull total_done;
    time_t * _Nonnull creation_date;
    int * _Nonnull is_paused;
    int * _Nonnull is_finished;
    int * _Nonnull is_seed;
	int * _Nonnull has_metadata;
    int * _Nonnull num_pieces;
    int * _Nonnull * _Nonnull pieces;
    int * _Nonnull sequential_download;
} Result;

#endif /* result_struct_h */
