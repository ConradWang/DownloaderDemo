//
//  ViewController.m
//  DownloaderDemo
//
//  Created by Cong on 2018/8/16.
//  Copyright © 2018年 huang. All rights reserved.
//

#import "ViewController.h"
#import "MultiDownloader.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UILabel *progressLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UIButton *controllButton;

@property (strong, nonatomic) MultiDownloader *downloader;

@end

@implementation ViewController

// http://dldir1.qq.com/qqfile/QQforMac/QQ_V6.5.0.dmg
// http://cdn2.ime.sogou.com/4eec465a4a728921295f23dd26777aff/5b795ae9/dl/index/1527642254/sogou_mac_47e.zip
// https://www.charlesproxy.com/assets/release/4.2.6/charles-proxy-4.2.6.dmg

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.progressView.progress = 0;
    self.progressLabel.text = @"0%";
    
    self.downloader = [[MultiDownloader alloc] init];
    self.downloader.url = [NSURL URLWithString:@"https://www.charlesproxy.com/assets/release/4.2.6/charles-proxy-4.2.6.dmg"];
    
    NSString *caches = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    self.downloader.filePath = [caches stringByAppendingPathComponent:@"charles-proxy-4.2.6.dmg"];
    
    __weak typeof(self) weakSelf = self;
    self.downloader.progressHandler = ^(double progress) {
        weakSelf.progressView.progress = progress;
        weakSelf.progressLabel.text = [NSString stringWithFormat:@"%ld%%", (NSInteger)(progress * 100)];
    };
    self.downloader.didFinishHandler = ^{
        NSLog(@"%@", caches);
        weakSelf.progressLabel.text = @"下载完成";
    };
}


- (IBAction)controlButtonClicked:(UIButton *)sender {
    if ([[sender titleForState:UIControlStateNormal] isEqualToString:@"下载"]) {
        [sender setTitle:@"暂停" forState:UIControlStateNormal];
        [self.downloader startDownloading];
    } else {
        [sender setTitle:@"下载" forState:UIControlStateNormal];
        [self.downloader pauseDownloading];
    }
}

@end
