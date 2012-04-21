//
//  ITWebinterface.h
//  iTransmission
//
//  Created by user on 4/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ITSidebarItem.h"

@interface ITWebinterface : UIViewController

@property (nonatomic, retain) ITSidebarItem *sidebarItem;
@property (nonatomic, retain) IBOutlet UIWebView *webView;
@property (nonatomic, retain) UIActivityIndicatorView *activityIndicator;

@end
