//
//  file_struct.h
//  iTorrent
//
//  Created by  XITRIX on 15.05.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

#ifndef file_struct_h
#define file_struct_h

typedef struct File {
    char* file_name;
    char* file_path;
    long long file_size;
    long long file_downloaded;
    int file_priority;
    long long begin_idx;
    long long end_idx;
} File;

typedef struct Files {
    int error;
    int size;
    char* title;
    File* files;
} Files;

typedef struct Trackers {
	int size;
	char** tracker_url;
	char** messages;
	int* seeders;
	int* peers;
	int* working;
	int* verified;
} Trackers;
#endif /* file_struct_h */
