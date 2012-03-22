//
//  ITNavigationController.h
//  iTransmission
//
//  Created by Mike Chen on 10/22/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ITStatusBarController.h"
#import "ITSidebarController.h"
#import "ITController.h"
#import "ITTimerListener.h"
#import "ITNetworkSwitcher.h"
#import "ITSidebarItemDatasource.h"

@class ITNavigationController;

@interface ITNavigationController : UINavigationController <ITSidebarItemDatasource, UINavigationControllerDelegate>

@property (assign, nonatomic) UIViewController *rootViewController;
@property (strong, nonatomic) ITSidebarItem *sidebarItem;
@property (strong, nonatomic) ITSidebarController *sidebarController;
@property (strong, nonatomic) UISwipeGestureRecognizer *swiperight;
@property (nonatomic, assign) BOOL useDefaultTheme;

@end
