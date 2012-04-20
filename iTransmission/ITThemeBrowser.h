//
//  ITThemeBrowser.h
//  iTransmission
//
//  Created by user on 4/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ITSidebarItem.h"
#import "ITController.h"

@interface ITThemeBrowser : UIViewController

@property (strong, nonatomic) ITSidebarItem *sidebarItem;
@property (strong, nonatomic) ITController *controller;

@end
