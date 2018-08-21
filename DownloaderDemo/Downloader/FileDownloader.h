//
//  FileDownloader.h
//  DownloaderDemo
//
//  Created by Cong on 2018/8/17.
//  Copyright © 2018年 huang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FileDownloader : NSObject

/** 请求路径 */
@property(nonatomic, strong) NSURL *url;

/** 存放路径 */
@property(nonatomic, strong) NSString *filePath;

/** 下载状态 */
@property(nonatomic, assign) BOOL downloading;

/** 更新进度block */
@property(nonatomic, copy) void(^progressHandler)(double progress);

/** 完成下载后block */
@property(nonatomic, copy) void(^didFinishHandler)(void);

/** 完成失败后block */
@property(nonatomic, copy) void(^didFailHandler)(NSError *error);

- (void) startDownloading;
- (void) pauseDownloading;

@end
