//
//  ITTips.h
//  iTransmission
//
//  Created by user on 4/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ITSidebarItem.h"

@interface ITTips : UIViewController

@property (nonatomic, retain) ITSidebarItem *sidebarItem;
@property (nonatomic, retain) IBOutlet UIWebView *webView;

@end
