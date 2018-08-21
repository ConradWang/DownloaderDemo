//
//  FileDownloader.m
//  DownloaderDemo
//
//  Created by Cong on 2018/8/17.
//  Copyright © 2018年 huang. All rights reserved.
//

#import "FileDownloader.h"
#import "FileDownloader+URLSession.h"
#import <UIKit/UIKit.h>

@implementation FileDownloader

/** 开始下载 */
- (void) startDownloading {
    _downloading = YES;

    if (self.resumeData) {
        self.downloadTask = [self.session downloadTaskWithResumeData:self.resumeData];
    } else {
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.url];
        self.downloadTask = [self.session downloadTaskWithRequest:request];
    }
    
    [self.downloadTask resume];
}

/** 暂停下载 */
- (void) pauseDownloading {
    _downloading = NO;

    __weak typeof(self) weakSelf = self;
    [self.downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
        weakSelf.resumeData = resumeData;
    }];
    self.downloadTask = nil;
}

/** 取消下载 */
- (void) cancelDownloading {
    _downloading = NO;
    
    __weak typeof(self) weakSelf = self;
    [self.downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
        //
    }];
    self.resumeData = nil;
    self.downloadTask = nil;
}

- (NSURLSession *)session {
    if (_session == nil) {
        NSURLSessionConfiguration *config =  [NSURLSessionConfiguration defaultSessionConfiguration];
        _session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    }
    return  _session;
}


#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {

    // 刷新进度条
    CGFloat completedProgress = totalBytesWritten * 1.0 / totalBytesExpectedToWrite;
    if (self.progressHandler) {
        self.progressHandler(completedProgress);
    }
}


- (void)URLSession:(nonnull NSURLSession *)session downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(nonnull NSURL *)location {

    // 创建一个空的文件，用来存放接收的数据
    NSFileManager *manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:self.filePath]) {
        [manager removeItemAtPath:self.filePath error:nil];
    }
    [manager createFileAtPath:self.filePath contents:nil attributes:nil];

    //保存
    [[NSFileManager defaultManager] moveItemAtURL:location toURL:[NSURL fileURLWithPath:self.filePath] error:nil];
    
    //
    self.resumeData = nil;
    self.downloadTask = nil;
    
    if (self.didFinishHandler) {
        self.didFinishHandler();
    }
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error && ![error.localizedDescription isEqualToString:@"cancelled"]) {
        if (self.didFailHandler) {
            self.didFailHandler(error);
        }
    }
}

@end


