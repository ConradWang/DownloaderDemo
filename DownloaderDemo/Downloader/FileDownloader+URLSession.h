//
//  FileDownloader+URLSession.h
//  DownloaderDemo
//
//  Created by Cong on 2018/8/17.
//  Copyright © 2018年 huang. All rights reserved.
//

#import "FileDownloader.h"

@interface FileDownloader() <NSURLSessionDataDelegate, NSURLSessionDownloadDelegate>

/** 当前HTTP(s)会话 */
@property(nonatomic, strong) NSURLSession *session;
@property(nonatomic, strong) NSURLSessionDownloadTask *downloadTask;
@property(nonatomic, strong) NSData *resumeData;


@end
