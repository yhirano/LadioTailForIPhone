/*
 * Copyright (c) 2013-2014 Yuichi Hirano
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import "RadioLib/RadioLib.h"
#import "AppDelegate.h"
#import "ChannelArchiveManager.h"

@interface ChannelArchiveManager () <NSURLSessionDataDelegate>

@end

@implementation ChannelArchiveManager
{
    NSMutableDictionary<NSURLSessionTask*, Channel*> *tasks_;
}

+ (ChannelArchiveManager *)sharedInstance
{
    static ChannelArchiveManager *instance = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        instance = [[ChannelArchiveManager alloc] init];
    });
    return instance;
}

- (id)init
{
    if (self = [super init]) {
        tasks_ = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSURLSessionDownloadTask *)recode:(Channel *)channel
{
    if (!channel) {
        return nil;
    }

#if defined(LADIO_TAIL)
    NSURL *url = channel.playUrl;
#elif defined(RADIO_EDGE)
    NSURL *url = channel.listenUrl;
#else
    #error "Not defined LADIO_TAIL or RADIO_EDGE"
#endif

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
    NSString *identifier = [NSString stringWithFormat:@"%@%@",
                            [dateFormatter stringFromDate:[NSDate date]],
                            [url absoluteString]];

    NSURLSessionConfiguration* sessionConfig =
        [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:identifier];
    sessionConfig.allowsCellularAccess = YES;

    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:request];
    [tasks_ setObject:channel forKey:task];
    [task resume];

    return task;
}

#pragma mark - NSURLSessionDownloadDelegate methods

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{
    Channel *channel = [tasks_ objectForKey:downloadTask];

    NSFileManager *fileManager = [NSFileManager defaultManager];

    // ドキュメントディレクトリを取得
    NSArray<NSURL*> *documentDirectoryUrls = [fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *documentsDirectory = [documentDirectoryUrls objectAtIndex:0];

    // コピー先のファイル名を設定
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    [dateFormatter setDateFormat:@"yyyyMMdd_HHmmss"];
    NSString *extention = [channel filenameExtensionFromMimeType];
    if ([extention length] == 0) {
        extention = @"dat";
    }
    NSString *fileName = [NSString stringWithFormat:@"%@.%@", [dateFormatter stringFromDate:[NSDate date]], extention];
    // コピー先のフルパスを設定
    NSURL *destinationUrl = [documentsDirectory URLByAppendingPathComponent:fileName];

    NSError *error = nil;

    // 既にファイルがある場合は削除（あり得ないはずだが一応）
    [fileManager removeItemAtURL:destinationUrl error:NULL];
    // ファイルコピー
    BOOL success = [fileManager copyItemAtURL:location toURL:destinationUrl error:&error];
    
    if (success) {
        NSLog(@"Copy download data from \"%@\" to \"%@\". Error:%@",
              [location absoluteString], [destinationUrl absoluteString], [error localizedDescription]);
    } else {
        NSLog(@"Error during the copy from \"%@\" to \"%@\". Error:%@",
              [location absoluteString], [destinationUrl absoluteString], [error localizedDescription]);
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
#if DEBUG
    NSLog(@"Downloading. URL:\"%@\" Size:%lld", [downloadTask.originalRequest.URL absoluteString], totalBytesWritten);
#endif // #if DEBUG
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes
{
#if DEBUG
    NSLog(@"Download task Resumed. URL:%@", [downloadTask.originalRequest.URL absoluteString]);
#endif // #if DEBUG
}

#pragma mark - NSURLSessionTaskDelegate methods

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (!error) {
        NSLog(@"Download task completed successfully. URL:%@", [task.originalRequest.URL absoluteString]);
    } else {
        NSLog(@"Download task completed with error. URL:%@ Error:%@",
              [task.originalRequest.URL absoluteString], [error localizedDescription]);
    }
    
    [tasks_ removeObjectForKey:task];
}

#pragma mark - NSURLSessionDelegate methods

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.backgroundSessionCompletionHandler) {
        void (^completionHandler)() = appDelegate.backgroundSessionCompletionHandler;
        appDelegate.backgroundSessionCompletionHandler = nil;
        completionHandler();
    }
}

@end
