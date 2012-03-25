//
//  ITWebViewController.h
//  iTransmission
//
//  Created by Mike Chen on 10/22/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SVWebViewController.h"
#import "ITSidebarItemDatasource.h"
#import "ITController.h"
#import <libtransmission/transmission.h>
#import "ITTorrent.h"
#import <curl/curl.h>

@interface ITWebViewController : SVWebViewController <ITSidebarItemDatasource>

@property (nonatomic, strong) ITSidebarItem *sidebarItem;
@property (nonatomic, strong) ITController *controller;
@property (assign, nonatomic) tr_session *handle;
@property (nonatomic, strong) ITTorrent *torrent;
@property (retain) NSFileHandle* downloadFile;
@property (retain) NSString* downloadFilePath;
@property (nonatomic, assign) id delegate;
@property (retain) NSURL* url;
@property (assign) BOOL cancel;
@property (retain) NSDate* lastModified;
@property (assign) BOOL actAsInsect;

size_t write_data(void *ptr, size_t size, size_t nmemb, FILE *stream);
- (id)init;
@end
