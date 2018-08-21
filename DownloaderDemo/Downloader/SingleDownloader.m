//
//  SingleDownloader.m
//  DownloaderDemo
//
//  Created by Cong on 2018/8/17.
//  Copyright © 2018年 huang. All rights reserved.
//

#import "SingleDownloader.h"
#import "FileDownloader+URLSession.h"

@interface SingleDownloader()

/** 文件句柄 */
@property(nonatomic, strong) NSFileHandle *handle;
@property(nonatomic, strong) dispatch_queue_t fileQueue;

@end

@implementation SingleDownloader

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.fileQueue = dispatch_queue_create("FileWRQueue", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

/** 开始下载 */
- (void) startDownloading {
    self.downloading = YES;
    
    if (self.resumeData) {
        self.downloadTask = [self.session downloadTaskWithResumeData:self.resumeData];
    } else {
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.url];
        // 设置request头信息，指明要从文件哪里开始下载
        NSString *value = [NSString stringWithFormat:@"bytes=%lld-%lld", self.begin, self.end];
        [request setValue:value forHTTPHeaderField:@"Range"];
        
        self.downloadTask = [self.session downloadTaskWithRequest:request];
    }
    
    [self.downloadTask resume];
}


#pragma mark - NSURLConnectionDataDelegate

- (void)URLSession:(nonnull NSURLSession *)session downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(nonnull NSURL *)location {
    NSLog(@"接收完毕 range:%lld ~ %lld, expectedSize:%lld, actualSize:%lld", self.begin, self.end, self.end - self.begin + 1,  downloadTask.response.expectedContentLength);
    
    long long perDataSize = 5 * 1024 * 1024;
    long long restSize = downloadTask.response.expectedContentLength;
   
    NSFileHandle *sourceFileHandle = [NSFileHandle fileHandleForReadingAtPath:[location.absoluteString stringByReplacingOccurrencesOfString:@"file://" withString:@""]];
    NSFileHandle *destinationFileHandle = [NSFileHandle fileHandleForUpdatingAtPath:self.filePath];
    long long transmitSize = 0;
    
    while (restSize > 0) {
        [sourceFileHandle seekToFileOffset:transmitSize];
        [destinationFileHandle seekToFileOffset:self.begin + transmitSize];
        NSData *transmitData = [sourceFileHandle readDataOfLength:MIN(perDataSize, restSize)];
        [destinationFileHandle writeData:transmitData];
        transmitSize += transmitData.length;
        restSize -= transmitData.length;
    }
    NSLog(@"拷贝文件大小%lld", transmitSize);
    
    [sourceFileHandle closeFile];
    [destinationFileHandle closeFile];

    //
    self.resumeData = nil;
    self.downloadTask = nil;
    
    if (self.didFinishHandler) {
        self.didFinishHandler();
    }
}


@end
