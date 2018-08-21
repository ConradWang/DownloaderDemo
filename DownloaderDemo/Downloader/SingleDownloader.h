//
//  SingleDownloader.h
//  DownloaderDemo
//
//  Created by Cong on 2018/8/17.
//  Copyright © 2018年 huang. All rights reserved.
//

#import "FileDownloader.h"

@interface SingleDownloader : FileDownloader

/** 开始下载的位置（字节) */
@property(nonatomic, assign) long long begin;

/** 结束下载的位置（字节) */
@property(nonatomic, assign) long long end;

@end
