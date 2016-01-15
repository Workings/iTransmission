//
//  ITAppDelegate.m
//  iTransmission
//
//  Created by Mike Chen on 10/19/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ITAppDelegate.h"
#import "ITSidebarController.h"
#import "ITNavigationController.h"
#import "ITTransfersViewController.h"
#import "ITWebViewController.h"
#import "ITPreferencePanelViewController.h"
#import "ITInfoViewController.h"
#import "ITExperimentalViewController.h"
#import "ITPrefViewController.h"
#import "UIAlertView+Lazy.h"
#import "ITTorrent.h"
#import "ITThemeBrowser.h"
#import "ITTips.h"
#import "ITWebinterface.h"

@implementation ITAppDelegate

@synthesize window = _window;
@synthesize statusBarController = _statusBarController;
@synthesize sidebarController = _sidebarController;
@synthesize controller = _controller;
@synthesize persistentTimer = _persistentTimer;
@synthesize timerEventListeners = _timerEventListeners;
@synthesize networkSwitcher = _networkSwitcher;
@synthesize interactionController = _interactionController;
@synthesize navigationController = _navigationController;
@synthesize transfersController = _transfersController;
@synthesize torrent = _torrent;
@synthesize handle;

+ (id)sharedDelegate
{
    return (ITAppDelegate*)[[UIApplication sharedApplication] delegate];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSString *webInterfacePath = [[NSBundle mainBundle] pathForResource:@"web" ofType:nil];
    setenv("TRANSMISSION_WEB_HOME", [webInterfacePath UTF8String], 1);
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // overide for customization
    //self.window.backgroundColor = [UIColor blackColor];
    
    self.timerEventListeners = [[NSMutableArray alloc] init];
    
    
    NSMutableArray *viewControllers = [NSMutableArray array];
    [viewControllers addObject:[[ITNavigationController alloc] initWithRootViewController:[[ITTransfersViewController alloc] init]]];
    [viewControllers addObject:[[ITNavigationController alloc] initWithRootViewController:[[ITWebViewController alloc] init]]];
    [viewControllers addObject:[[ITNavigationController alloc] initWithRootViewController:[[ITPrefViewController alloc] init]]];
    [viewControllers addObject:[[ITNavigationController alloc] initWithRootViewController:[[ITInfoViewController alloc] initWithPageName:@"about"]]];
    // [viewControllers addObject:[[ITNavigationController alloc] initWithRootViewController:[[ITThemeBrowser alloc] init]]];
    [viewControllers addObject:[[ITNavigationController alloc] initWithRootViewController:[[ITWebinterface alloc] init]]];
    // [viewControllers addObject:[[ITNavigationController alloc] initWithRootViewController:[[ITTips alloc] init]]];
    
    self.sidebarController = [[ITSidebarController alloc] init];
    self.sidebarController.viewControllers = viewControllers;
    
    self.statusBarController = [[ITStatusBarController alloc] initWithNibName:@"ITStatusBarController" bundle:nil];
    self.statusBarController.contentViewController = self.sidebarController;
    self.window.rootViewController = self.statusBarController;
    
    self.networkSwitcher = [[ITNetworkSwitcher alloc] init];
    
    [self performSelectorInBackground:@selector(startTransmission) withObject:nil];
    // [self performSelector:@selector(_test) withObject:nil afterDelay:1.0f];
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    if ([url isFileURL]) {
        NSString *filePath = [url path];
        return [self.controller openFiles:[NSArray arrayWithObject:filePath] addType:ITAddTypeManual];
    }
    
    if ([[[url scheme] lowercaseString] isEqualToString: @"magnet"]) {
        return [self openMagnet: url];
    }
    
    return NO;
}

- (BOOL) openMagnet:(NSURL *)url
{
    NSString *magnet = [url absoluteString];
    if (nil != magnet) {
        return [self.controller openMagnet: [NSArray arrayWithObject:magnet]];
    }
    return NO;
}

- (void)_test
{
    // [(id)self.statusBarController.contentViewController slideContainerViewToRightAnimated:YES];
    // [self.controller openFiles:[NSArray arrayWithObject:[[NSBundle mainBundle] pathForResource:@"torrent" ofType:@"torrent"]] addType:ITAddTypeManual];
    // [self.controller openFiles:[NSArray arrayWithObject:[[NSBundle mainBundle] pathForResource:@"ubuntu-11.10-desktop-i386.iso" ofType:@"torrent"]] addType:ITAddTypeManual];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [self stopTimer];
    [self.controller updateTorrentHistory];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [self.controller startAllTransfers];
    [self.controller updateTorrentHistory];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [self.controller updateTorrentHistory];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [self startTimer];
    [self.controller updateTorrentHistory];
}

- (void)registerForTimerEvent:(id)obj
{
    [self.timerEventListeners addObject:obj];
}

- (void)unregisterForTimerEvent:(id)obj
{
    [self.timerEventListeners removeObject:obj];
}

- (void)stopTimer
{
    [self.persistentTimer invalidate];
    self.persistentTimer = nil;
}

- (void)startTimer
{
    self.persistentTimer = [NSTimer timerWithTimeInterval:1.0f target:self selector:@selector(timerFired:) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.persistentTimer forMode:NSRunLoopCommonModes];
}

- (void)startTransmission
{
    self.controller = [[ITController alloc] init];
}

- (void)stopTransmission
{
    [self.controller shutdown];
    self.controller = nil;
}

- (void)timerFired:(id)sender
{
    for (id<ITTimerListener> obj in self.timerEventListeners) {
        if ([obj respondsToSelector:@selector(timerFiredAfterDelay:)]) {
            [obj timerFiredAfterDelay:0.0f];
        }
        else {
            LogMessageCompat(@"Object at 0x%X registered for timer event but doens't confirm to protocol!\n", (u_int32_t)obj);
        }
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    self.networkSwitcher = nil;
    [self.controller shutdown];
}

- (void)requestToOpenURL:(NSURL*)URL
{
    if ([URL isFileURL]) {
        self.interactionController = [UIDocumentInteractionController interactionControllerWithURL:URL];
        self.interactionController.delegate = self;
        
        if ([self.interactionController presentOpenInMenuFromRect:self.window.bounds inView:self.window animated:YES] == NO) {
            [UIAlertView showMessageWithDismissButton:[NSString stringWithFormat:@"No application can open \"%@\"!\n", [URL absoluteURL]]];
            self.interactionController = nil;
        }
    }
    else {
        if ([[UIApplication sharedApplication] canOpenURL:URL]) {
            [[UIApplication sharedApplication] openURL:URL];
        }
        else {
            [UIAlertView showMessageWithDismissButton:[NSString stringWithFormat:@"No application can open \"%@\"!\n", [URL absoluteURL]]];
        }
    }
}

- (void)documentInteractionController:(UIDocumentInteractionController *)controller didEndSendingToApplication:(NSString *)application
{
    self.interactionController = nil;
}

/*
- (void)documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *)controller
{
    self.interactionController = nil;
}
 */

@end
