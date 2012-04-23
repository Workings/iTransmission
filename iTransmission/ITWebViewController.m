//
//  ITWebViewController.m
//  iTransmission
//
//  Created by Mike Chen on 10/22/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ITWebViewController.h"
#import "ITSidebarItem.h"
#import "ITNavigationController.h"
#import <curl/curl.h>
#import <curl/types.h>
#import <curl/easy.h>
#import "ITApplication.h"
#import "ITTorrent.h"
#import "ITTransfersViewController.h"

@implementation ITWebViewController
@synthesize sidebarItem = _sidebarItem;
@synthesize controller = _controller;
@synthesize handle = _handle;
@synthesize torrent;
@synthesize downloadFile;
@synthesize downloadFilePath;
@synthesize transfers;
NSURL *requestedURL;

- (id)init
{
    if ((self = [super initWithAddress:@"http://www.kat.ph"])) {
        self.sidebarItem = [[ITSidebarItem alloc] init];
        self.sidebarItem.title = @"Browser";
//        self.sidebarItem.icon = [UIImage imageNamed:@"browser-icon.png"];
        self.navigationController.toolbarHidden = NO;
//        self.navigationController.toolbar.barStyle = UIBarStyleBlack;
    }
    return self;
}

size_t write_data(void *ptr, size_t size, size_t nmemb, FILE *stream)
{
    size_t written;
    written = fwrite(ptr, size, nmemb, stream);
    return written;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if ([self.navigationController respondsToSelector:@selector(setUseDefaultTheme:)])
        [(ITNavigationController*)self.navigationController setUseDefaultTheme:YES];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
}

- (void) openMagnet: (NSString *) address
{
    tr_torrent * duplicateTorrent;
    if ((duplicateTorrent = tr_torrentFindFromMagnetLink(self.handle, [address UTF8String])))
    {
        const tr_info * info = tr_torrentInfo(duplicateTorrent);
        NSString * name = (info != NULL && info->name != NULL) ? [NSString stringWithUTF8String: info->name] : nil;
        return;
    }
    
    //determine download location
    NSString * location = nil;
    
    // ITTorrent * torrent;
    if (!(torrent = [[ITTorrent alloc] initWithMagnetAddress: address location: location lib: self.handle]))
    {
        return;
    }
    
    [torrent startTransfer];
    
    [torrent update];
    [[[ITTransfersViewController alloc] displayedTorrents] addObject: torrent];
    
    [[[ITTransfersViewController alloc] displayedTorrents] addObject: torrent];
}


- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSURL *requestedURL = [request URL];
    NSString *fileExtension = [requestedURL pathExtension];
    NSString *scheme = [requestedURL scheme];
    if (navigationType == UIWebViewNavigationTypeLinkClicked)
    {
        if ([fileExtension isEqualToString:@"torrent"])
        {
            NSString *charURL = [requestedURL absoluteString]; 
            CURL *curl;
            FILE *fp;
            CURLcode res;
            char outfilename[FILENAME_MAX] = "/Applications/iTransmission.app/torrent.torrent";
            const char *url = [charURL UTF8String];
            curl = curl_easy_init();
            if (curl)
            {
                fp = fopen(outfilename,"wb");
                NSFileManager *check;
                BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:@"/Applications/iTransmission.app/torrent.torrent"];
                if(fileExists == YES)
                {
                    [check removeItemAtPath:@"/Applications/iTransmission.app/torrent.torrent" error:nil];
                }
                curl_easy_setopt(curl, CURLOPT_URL, url);
                curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_data);
                curl_easy_setopt(curl, CURLOPT_WRITEDATA, fp);
                res = curl_easy_perform(curl);
                 
                curl_easy_cleanup(curl);
                fclose(fp);
            }
            [self.controller openFiles:[NSArray arrayWithObject:[[NSBundle mainBundle] pathForResource:@"torrent" ofType:@"torrent"]] addType:ITAddTypeManual];
        }
        if(navigationType == UIWebViewNavigationTypeLinkClicked) {
            if( [scheme isEqualToString:@"magnet"] )
            {
                NSLog(@"magnet");
                // [self.openMagnet:[requestedURL absoluteString];
            }
        }
    }
    
    return YES;
}

- (void)add
{
    [self.controller openFiles:[NSArray arrayWithObject:[[NSBundle mainBundle] pathForResource:@"torrent" ofType:@"torrent"]] addType:ITAddTypeManual];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	
	return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}
@end
