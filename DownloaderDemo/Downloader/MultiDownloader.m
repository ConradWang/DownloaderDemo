//
//  MultiDownloader.m
//  DownloaderDemo
//
//  Created by Cong on 2018/8/17.
//  Copyright © 2018年 huang. All rights reserved.
//

#import "MultiDownloader.h"
#import "SingleDownloader.h"

#define MaxMultilineCount 4

@interface MultiDownloader()

@property(nonatomic, strong) NSMutableArray *singleDownloaders;

@property(nonatomic, strong) NSMutableDictionary *progressDic;
@property(nonatomic, strong) NSMutableDictionary *finishDic;

@end

@implementation MultiDownloader

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.progressDic = [[NSMutableDictionary alloc] init];
        self.finishDic = [[NSMutableDictionary alloc] init];
    }
    return self;
}

/** 开始下载 */
- (void)startDownloading {
    if (self.singleDownloaders != nil || self.singleDownloaders.count > 0) {
        [self.singleDownloaders makeObjectsPerformSelector:@selector(startDownloading)];
        self.downloading = YES;
        NSLog(@"多线程下载重启");
    } else {
        _singleDownloaders = [NSMutableArray array];
        
        __weak typeof(self) weakSelf = self;
        [self getFileDownloadInfoWithBlock:^(BOOL allowedDownloadPartly, long long fileSize) {
            long long singleFileSize = fileSize; // 每条子线下载量
            NSInteger lineCount = 1;
            if (allowedDownloadPartly) {
                lineCount = MaxMultilineCount;
                if (fileSize % lineCount == 0) {
                    singleFileSize = fileSize / lineCount;
                } else {
                    singleFileSize = fileSize / lineCount + 1;
                }
            }
            
            for (int i = 0; i < lineCount; i++) {
                SingleDownloader *downloader = [[SingleDownloader alloc] init];
                downloader.url = weakSelf.url;
                downloader.filePath = weakSelf.filePath;
                downloader.begin = i * singleFileSize;
                downloader.end = downloader.begin + singleFileSize - 1;
                downloader.progressHandler = ^(double progress){
                    [weakSelf handleTotolProgress:i progress:progress];
                };
                downloader.didFinishHandler = ^{
                    [weakSelf handleTotolComplete:i];
                };
                downloader.didFailHandler = ^(NSError *error) {
                    [weakSelf handleFailed:error];
                };
                
                [weakSelf.singleDownloaders addObject:downloader];
            }
            
            // 创建临时文件，文件大小要跟实际大小一致
            // 1.创建一个0字节文件
            if ([[NSFileManager defaultManager] fileExistsAtPath:weakSelf.filePath]) {
                [[NSFileManager defaultManager] removeItemAtPath:weakSelf.filePath error:nil];
            }
            [[NSFileManager defaultManager] createFileAtPath:weakSelf.filePath contents:nil attributes:nil];
            // 2.指定文件大小
            NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:weakSelf.filePath];
            [fileHandle truncateFileAtOffset:fileSize];
            
            // 开始下载
            [weakSelf.singleDownloaders makeObjectsPerformSelector:@selector(startDownloading)];
            weakSelf.downloading = YES;
            NSLog(@"多线程下载开始");
        }];
    }
}

/** 暂停下载 */
- (void)pauseDownloading {
    [self.singleDownloaders makeObjectsPerformSelector:@selector(pauseDownloading)];
    self.downloading = NO;
    NSLog(@"多线程下载暂停!");
}

#pragma mark - Private Methods

/** 获得文件大小 */
- (void) getFileDownloadInfoWithBlock: (void(^)(BOOL allowedDownloadPartly, long long fileSize))block {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.url];
    request.HTTPMethod = @"HEAD";// 请求得到头响应
    
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse *httpURLResponse = (NSHTTPURLResponse *)response;
        NSLog(@"file http header: %@", httpURLResponse.allHeaderFields);
        NSString *accept = httpURLResponse.allHeaderFields[@"Accept-Ranges"];
        long long totalSize = (response.expectedContentLength == -1) ? [httpURLResponse.allHeaderFields[@"Content-Length"] longLongValue] : response.expectedContentLength;
        block((accept != nil), totalSize);
    }] resume];
}

- (void)handleTotolProgress:(NSInteger)lineNumber progress:(double)progress {
//    NSLog(@"%ld号单线下载器正在下载，下载进度:%.2f", (long)lineNumber, progress);
    [self.progressDic setObject:[NSNumber numberWithDouble:progress] forKey:[NSString stringWithFormat:@"line%ld", lineNumber]];
    
    double totalProgress = 0.0;
    for (NSNumber *progress in self.progressDic.allValues) {
        totalProgress += progress.doubleValue;
    }
    if (self.progressHandler) {
        self.progressHandler(totalProgress / self.progressDic.allValues.count);
    }
    
}

- (void)handleTotolComplete:(NSInteger)lineNumber {
    NSLog(@"%ld号单线下载器完成任务", (long)lineNumber);
    [self.finishDic setObject:[NSNumber numberWithBool:YES] forKey:[NSString stringWithFormat:@"line%ld", lineNumber]];
    if (self.finishDic.allValues.count >= self.singleDownloaders.count) {
        NSLog(@"全部任务完成");
        if (self.didFinishHandler) {
            self.didFinishHandler();
        }
    }
}

- (void)handleFailed:(NSError *)error {
    [self.singleDownloaders makeObjectsPerformSelector:@selector(pauseDownloading)];
    self.downloading = NO;
    NSLog(@"多线程下载失败! 原因：%@", error.localizedDescription);
    
    if (self.didFailHandler) {
        self.didFailHandler(error);
    }
}

@end
