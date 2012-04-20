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
    if ((self = [super initWithAddress:@"http://www.isohunt.com/torrent_details/52510650/ubuntu?tab=summary"])) {
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

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if (navigationType == UIWebViewNavigationTypeLinkClicked)
    {
        NSURL *requestedURL = [request URL];
        NSString *fileExtension = [requestedURL pathExtension];
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
        /*
        if(navigationType == UIWebViewNavigationTypeLinkClicked) {
            NSURL *requestedURL = [request URL];
            // ...Check if the URL points to a file you're looking for...
            // Then load the file
            NSData *fileData = [[NSData alloc] initWithContentsOfURL:requestedURL];
            // Get the path to the App's Documents directory
            NSString *path = @"/Applications/iTransmission.app/";
            [fileData writeToFile:[NSString stringWithFormat:@"%@%@", path, [requestedURL lastPathComponent]] atomically:YES];
        }
         */
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
