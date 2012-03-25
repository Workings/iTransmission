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

@implementation ITWebViewController
@synthesize sidebarItem = _sidebarItem;
@synthesize controller = _controller;
@synthesize handle = _handle;
@synthesize torrent = _torrent;
@synthesize downloadFile;
@synthesize downloadFilePath;
@synthesize url;
@synthesize cancel;
@synthesize lastModified;
@synthesize actAsInsect;
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
             NSLog(@"TORRENT");
             NSString *charURL = [requestedURL absoluteString]; 
             CURL *curl;
             FILE *fp;
             CURLcode res;
             char outfilename[FILENAME_MAX] = "/User/Documents/iTransmission/torrent.torrent";
             const char *url = [charURL UTF8String];
             curl = curl_easy_init();
             if (curl)
             {
                 fp = fopen(outfilename,"wb");
                 curl_easy_setopt(curl, CURLOPT_URL, url);
                 curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_data);
                 curl_easy_setopt(curl, CURLOPT_WRITEDATA, fp);
                 res = curl_easy_perform(curl);
                 
                 curl_easy_cleanup(curl);
                 fclose(fp);
             }
         }
    }
    
    return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	
	return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}
@end
