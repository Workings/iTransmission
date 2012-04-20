//
//  ITAppDelegate.h
//  iTransmission
//
//  Created by Mike Chen on 10/19/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ITStatusBarController.h"
#import "ITSidebarController.h"
#import "ITController.h"
#import "ITTimerListener.h"
#import "ITNetworkSwitcher.h"
#import "ITNavigationController.h"
#import "ITTransfersViewController.h"

@interface ITAppDelegate : UIResponder <UIApplicationDelegate, UIDocumentInteractionControllerDelegate>

@property (strong, nonatomic) ITController *controller;
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) ITStatusBarController *statusBarController;
@property (strong, nonatomic) ITNavigationController *navigationController;
@property (strong, nonatomic) ITSidebarController *sidebarController;
@property (strong, nonatomic) ITTransfersViewController *transfersController;
@property (nonatomic, strong) NSMutableArray *timerEventListeners;
@property (nonatomic, strong) NSTimer *persistentTimer;
@property (strong, nonatomic) ITNetworkSwitcher *networkSwitcher;
@property (strong, nonatomic) UIDocumentInteractionController *interactionController;
@property (strong, nonatomic) ITTorrent *torrent;
@property (nonatomic, assign) tr_session *handle;

+ (id)sharedDelegate;
- (void)startTransmission;
- (void)stopTransmission;
- (void)_test;

- (void)startTimer;
- (void)stopTimer;
- (void)timerFired:(id)sender;
- (void)registerForTimerEvent:(id<ITTimerListener>)obj;
- (void)unregisterForTimerEvent:(id<ITTimerListener>)obj;

- (void)requestToOpenURL:(NSURL*)URL;
@end
