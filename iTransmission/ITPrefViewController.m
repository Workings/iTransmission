//
//  ITPrefViewController.m
//  iTransmission
//
//  Created by Mike Chen on 12/6/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ITPrefViewController.h"
#import "ITController.h"
#import "ITPrefsController.h"
#import "ITNetworkSwitcher.h"
#import "ITAppDelegate.h"
#import "ITLogger.h"

#define IN_RANGE(i, min, max) (i < min) || (i > max) ? NO : YES

@implementation ITPrefViewController

@synthesize tableView = _tableView;
@synthesize enableRPCCell;
@synthesize enableRPCAuthenticationCell;
@synthesize useWiFiCell;
@synthesize useMobileCell;
@synthesize enablePortMapCell;
@synthesize RPCPortCell;
@synthesize RPCUsernameCell;
@synthesize RPCPasswordCell;
@synthesize bindPortCell;
@synthesize openWebInterfaceCell;
@synthesize enableRPCSwitch;
@synthesize enableRPCAuthenticationSwitch;
@synthesize useWiFiSwitch;
@synthesize useMobileSwitch;
@synthesize enablePortMapSwitch;
@synthesize RPCPortTextField;
@synthesize bindPortTextField;
@synthesize webInterfaceURLTextView;
@synthesize keyboardController;
@synthesize enableAutoStart;
@synthesize MaxPeersPerTorrent;
@synthesize enablePeerLimitCell;
@synthesize fEnableLoggingCell;
@synthesize RPCUsernameTextField;
@synthesize RPCPasswordTextField;
@synthesize enablePeerGlobalCell;
@synthesize MaxPeersGlobal;
@synthesize DownloadLimit;
@synthesize UploadLimit;
@synthesize enableUploadLimitCell;
@synthesize enableDownloadLimitCell;
@synthesize enableLimits;
@synthesize enableLimitCell;
@synthesize userDefaults;
@synthesize enableAutoStartCell;
@synthesize enableBlocklist;
@synthesize enableBlocklistCell;
@synthesize enableDHTCell;
@synthesize enableUTPCell;
@synthesize enablePEXCell;
@synthesize enableUTP;
@synthesize enableDHT;
@synthesize enablePEX;
@synthesize downloadDir;
@synthesize downloadDirTextField;
@synthesize handle;
@synthesize sidebarItem;
@synthesize reseteverything;
@synthesize resetitransmission;

- (id)init
{
    if ((self = [super initWithNibName:@"ITPrefViewController" bundle:[NSBundle mainBundle]])) {
        [self registerNotifications];
        self.title = @"Preferences";
        self.sidebarItem = [[ITSidebarItem alloc] init];
        self.sidebarItem.title = @"Preferences";
        self.sidebarItem.icon = [UIImage imageNamed:@"settings-icon.png"];
    }
    return self;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 7;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return 1;
        case 1:
            return 2;
        case 2:
            return 2;
        case 3:
            return 1;
        case 4:
            return 5;
        case 5:
            return 6;
        case 6:
            return 1;
    }
    return 0;
}

- (void)viewDidLoad
{
    // self.enableRPCAuthenticationSwitch.on = [[[ITController sharedController] prefsController] isRPCAuthorizationEnabled];
    self.enablePortMapSwitch.on = [[[ITController sharedController] prefsController] isNatTransversalEnabled];
    // self.enableRPCSwitch.on = [[[ITController sharedController] prefsController] isRPCEnabled];
    self.useWiFiSwitch.on = [[ITNetworkSwitcher sharedNetworkSwitcher] canUseWiFiNetwork];
    self.useMobileSwitch.on = [[ITNetworkSwitcher sharedNetworkSwitcher] canUseMobileNetwork];
    self.enableLimits.on = [[[ITController sharedController] prefsController] isLimitsEnabled];
    self.enableAutoStart.on = [[[ITController sharedController] prefsController] isAutoStartEnabled];
    // self.enableBlocklist.on = [[[ITController sharedController] prefsController] isBlocklistEnabled];
    self.enableUTP.on = [[[ITController sharedController] prefsController] isUTPEnabled];
    self.enablePEX.on = [[[ITController sharedController] prefsController] isPexEnabled];
    self.enableDHT.on = [[[ITController sharedController] prefsController] isDHTEnabled];
    self.keyboardController = [[ITKeyboardController alloc] initWithDelegate:self];
    // self.RPCPortTextField.delegate = self.keyboardController;
    self.bindPortTextField.delegate = self.keyboardController;
    self.MaxPeersPerTorrent.delegate = self.keyboardController;
    self.MaxPeersGlobal.delegate = self.keyboardController;
    self.DownloadLimit.delegate = self.keyboardController;
    self.UploadLimit.delegate = self.keyboardController;
    // self.RPCUsernameTextField.delegate = self.keyboardController;
    // self.RPCPasswordTextField.delegate = self.keyboardController;
    // self.RPCPortTextField.text = [NSString stringWithFormat:@"%d", [[[ITController sharedController] prefsController] RPCPort]];
    self.downloadDirTextField.delegate = self.keyboardController;
    self.bindPortTextField.text = [NSString stringWithFormat:@"%d", [[[ITController sharedController] prefsController] bindPort]];
    self.webInterfaceURLTextView.text = [NSString stringWithFormat:@"http://127.0.0.1:%d/transmission/web/", [[[ITController sharedController] prefsController] RPCPort]];
    self.MaxPeersPerTorrent.text = [NSString stringWithFormat:@"%d", [[[ITController sharedController] prefsController] PeersPerTorrent]];
    self.MaxPeersGlobal.text = [NSString stringWithFormat:@"%d", [[[ITController sharedController] prefsController] PeersGlobal]];
    self.DownloadLimit.text = [NSString stringWithFormat:@"%d", [[[ITController sharedController] prefsController] DownloadLimit]];
    self.UploadLimit.text = [NSString stringWithFormat:@"%d", [[[ITController sharedController] prefsController] UploadLimit]];
    // self.RPCUsernameTextField.text = [NSString stringWithFormat:[[[ITController sharedController] prefsController] RPCUsername]];
    // self.RPCPasswordTextField.text = [NSString stringWithFormat:[[[ITController sharedController] prefsController] RPCPassword]];
    self.downloadDirTextField.text = [[[ITController sharedController] prefsController] downloadDir];
}

- (void)registerNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preferencesUpdateNotificationReceived:) name:kITPrefsBindPortUpdatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preferencesUpdateNotificationReceived:) name:kITPrefsNatTraversalFlagUpdatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preferencesUpdateNotificationReceived:) name:kITPrefsRPCAuthorizationFlagUpdatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preferencesUpdateNotificationReceived:) name:kITPrefsRPCPasswordUpdatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preferencesUpdateNotificationReceived:) name:kITPrefsRPCUsernameUpdatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preferencesUpdateNotificationReceived:) name:kITPrefsRPCFlagUpdatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preferencesUpdateNotificationReceived:) name:kITPrefsRPCPortUpdatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preferencesUpdateNotificationReceived:) name:kITNetworkPrefUseWiFiChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preferencesUpdateNotificationReceived:) name:kITNetworkPrefUseMobileChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preferencesUpdateNotificationReceived:) name:kITPrefsPeersPerTorrentUpdatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preferencesUpdateNotificationReceived:) name:kITPrefsPeersGlobalLimitUpdatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preferencesUpdateNotificationReceived:) name:kITPrefsDownloadLimitUpdatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preferencesUpdateNotificationReceived:) name:kITPrefsUploadLimitUpdatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preferencesUpdateNotificationReceived:) name:kITPrefsLimitUpdatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preferencesUpdateNotificationReceived:) name:kITPrefsAutoStartDownloadFlagUpdatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preferencesUpdateNotificationReceived:) name:kITPrefsUTPFlagUpdateNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preferencesUpdateNotificationReceived:) name:kITPrefsDHTFlagUpdatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preferencesUpdateNotificationReceived:) name:kITPrefsPEXFlagUpdatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preferencesUpdateNotificationReceived:) name:kITPrefsBlocklistEnabled object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preferencesUpdateNotificationReceived:) name:kITPrefsDownloadFoulderUpdated object:nil];
}

- (void)preferencesUpdateNotificationReceived:(NSNotification *)notification
{
    if ([[notification name] isEqualToString:kITPrefsBindPortUpdatedNotification]) {
        self.bindPortTextField.text = [NSString stringWithFormat:@"%d", [[[ITController sharedController] prefsController] bindPort]];
    }
    else if ([[notification name] isEqualToString:kITPrefsNatTraversalFlagUpdatedNotification]) {
        self.enablePortMapSwitch.on = [[[ITController sharedController] prefsController] isNatTransversalEnabled];
    }
    else if ([[notification name] isEqualToString:kITPrefsRPCAuthorizationFlagUpdatedNotification]) {
        self.enableRPCAuthenticationSwitch.on = [[[ITController sharedController] prefsController] isRPCAuthorizationEnabled];
    }
    else if ([[notification name] isEqualToString:kITPrefsRPCPasswordUpdatedNotification]) {
        self.RPCPasswordTextField.text = [NSString stringWithFormat:[[[ITController sharedController] prefsController] RPCPassword]];
    }
    else if ([[notification name] isEqualToString:kITPrefsRPCUsernameUpdatedNotification]) {
        self.RPCUsernameTextField.text = [NSString stringWithFormat:[[[ITController sharedController] prefsController] RPCUsername]];
    }
    else if ([[notification name] isEqualToString:kITPrefsRPCFlagUpdatedNotification]) {
        self.enableRPCSwitch.on = [[[ITController sharedController] prefsController] isRPCEnabled];
    }
    else if ([[notification name] isEqualToString:kITPrefsRPCPortUpdatedNotification]) {
        self.RPCPortTextField.text = [NSString stringWithFormat:@"%d", [[[ITController sharedController] prefsController] RPCPort]];
        self.webInterfaceURLTextView.text = [NSString stringWithFormat:@"http://127.0.0.1:%d/transmission/web/", [[[ITController sharedController] prefsController] RPCPort]];
    }
    
    else if ([[notification name] isEqualToString:kITNetworkPrefUseWiFiChangedNotification]) {
        self.useWiFiSwitch.on = [[ITNetworkSwitcher sharedNetworkSwitcher] canUseWiFiNetwork];
    }   
    else if ([[notification name] isEqualToString:kITNetworkPrefUseMobileChangedNotification]) {
        self.useMobileSwitch.on = [[ITNetworkSwitcher sharedNetworkSwitcher] canUseMobileNetwork];
    }   
    else if ([[notification name] isEqualToString:kITPrefsBindPortUpdatedNotification]) {
        
    }
    else if ([[notification name] isEqualToString:kITPrefsPeersPerTorrentUpdatedNotification])
    {
        self.MaxPeersPerTorrent.text = [NSString stringWithFormat:@"%d", [[[ITController sharedController] prefsController] PeersPerTorrent]];
    }
    else if ([[notification name] isEqualToString:kITPrefsPeersGlobalLimitUpdatedNotification])
    {
        self.MaxPeersGlobal.text = [NSString stringWithFormat:@"%d", [[[ITController sharedController] prefsController] PeersGlobal]];
    }
    else if ([[notification name] isEqualToString:kITPrefsDownloadLimitUpdatedNotification])
    {
        self.DownloadLimit.text = [NSString stringWithFormat:@"%d", [[[ITController sharedController] prefsController] DownloadLimit]];
    }
    else if ([[notification name] isEqualToString:kITPrefsUploadLimitUpdatedNotification])
    {
        self.UploadLimit.text = [NSString stringWithFormat:@"%d", [[[ITController sharedController] prefsController] UploadLimit]];
    }
    else if ([[notification name] isEqualToString:kITPrefsAutoStartDownloadFlagUpdatedNotification]) {
        self.enableAutoStart.on = [[[ITController sharedController] prefsController]isAutoStartEnabled];
    }
    else if ([[notification name] isEqualToString:kITPrefsUTPFlagUpdateNotification])
    {
        self.enableUTP.on = [[[ITController sharedController] prefsController] isUTPEnabled];
    }
    else if ([[notification name] isEqualToString:kITPrefsPEXFlagUpdatedNotification])
    {
        self.enablePEX.on = [[[ITController sharedController] prefsController] isPexEnabled];
    }
    else if ([[notification name] isEqualToString:kITPrefsDHTFlagUpdatedNotification])
    {
        self.enableDHT.on = [[[ITController sharedController] prefsController] isDHTEnabled];
    }
    else if ([[notification name] isEqualToString:kITPrefsBlocklistEnabled])
    {
        self.enableBlocklist.on = [[[ITController sharedController] prefsController] isBlocklistEnabled];
    }
    else if ([[notification name] isEqualToString:kITPrefsDownloadFoulderUpdated])
    {
        self.downloadDirTextField.text = [[[ITController sharedController] prefsController] downloadDir];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 && indexPath.row == 2) {
        return self.openWebInterfaceCell.frame.size.height;
    }
    return 44.0f;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0: return @"Web Interface";
        case 1: return @"Network Interface";
        case 2: return @"Port Listening";
        case 3: return @"Logging";
        case 4: return @"Limits";
        case 5: return @"Other options";
        case 6: return @"Reset";
    }
    return nil;
}

- (NSString*)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    switch (section) {
        case 0: 
            return nil;
        case 1: return @"Enabling cellular network may generate significant data charges. ";
        case 2: return nil;
        case 3: return @"Only use logging for debugging. Extensive loggings will shorten both battery and Nand life. Saved logs will be available in iTunes. (switch does nothing as of now)";
        case 4: return @"If you type 0 into any of the boxes, iTransmission will download anything";
        case 5: return nil;
        case 6: return nil;
    }
    return nil;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0: {
            switch (indexPath.row) {
                // case 0: return self.enableRPCCell;
                // case 1: return self.RPCPortCell;
                case 0: return self.openWebInterfaceCell;
                // case 3: return self.enableRPCAuthenticationCell;
                // case 4: return self.RPCUsernameCell;
                // case 5: return self.RPCPasswordCell;
            }
        }
        case 1: {
            switch (indexPath.row) {
                case 0: return self.useWiFiCell;
                case 1: return self.useMobileCell;
            }
        }
        case 2: {
            switch (indexPath.row) {
                case 0: return self.bindPortCell;
                case 1: return self.enablePortMapCell;
            }
        }
        case 3: {
            switch (indexPath.row) {
                case 0: return self.fEnableLoggingCell;
            }
        }
        case 4:
        {
            switch (indexPath.row) {
                case 0: return self.enableLimitCell;    
                case 1: return self.enablePeerLimitCell;
                case 2: return self.enablePeerGlobalCell;
                case 3: return self.enableDownloadLimitCell;
                case 4: return self.enableUploadLimitCell;
            }
        }
        case 5:
        {
            switch (indexPath.row) {
                case 0: return self.enableAutoStartCell;
                case 1: return self.enableBlocklistCell;
                case 2: return self.enablePEXCell;
                case 3: return self.enableDHTCell;
                case 4: return self.enableUTPCell;
                case 5: return self.downloadDir;
            }
        }
        case 6:
        {
            switch (indexPath.row) {
                case 0: return self.reseteverything;
            }
        }
    }
    return nil;
}

- (void)enableRPCValueChanged:(id)sender
{
    [[[ITController sharedController] prefsController] setRPCEnabled:[sender isOn]];
}

- (IBAction)useWiFiValueChanged:(id)sender
{
    [[ITNetworkSwitcher sharedNetworkSwitcher] setUseWiFiNetwork:[sender isOn]];
}

- (IBAction)resetitransmission:(id)sender
{
    UIAlertView *alert;
    alert = [[UIAlertView alloc] initWithTitle:@"Reset iTransmission?" message:@"" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    // the user clicked one of the OK/Cancel buttons
    if (buttonIndex == 0)
    {
    }
    else
    {
        system("rm -rf /User/Documents/iTransmission");
        UIAlertView *alert;
        alert = [[UIAlertView alloc] initWithTitle:@"iTransmission been reset" message:@"iTransmission has been sucsess" delegate:nil cancelButtonTitle:@"Ok!" otherButtonTitles:nil, nil];
        [alert show];
    }
}

- (IBAction)useMobileValueChanged:(id)sender
{
    [[ITNetworkSwitcher sharedNetworkSwitcher] setUseMobileNetwork:[sender isOn]];
}

- (IBAction)enableRPCAuthenticationValueChanged:(id)sender
{
    [[[ITController sharedController] prefsController] setRPCAuthorizionEnabled:[sender isOn]];
}

- (IBAction)enablePortMapValueChanged:(id)sender
{
    [[[ITController sharedController] prefsController] setNatTraverselEnabled:[sender isOn]];
}

- (IBAction)enableLimits:(id)sender
{
    [[[ITController sharedController] prefsController] setLimits:[sender isOn]];
}

- (IBAction)enableAutoStart:(id)sender
{
    [[[ITController sharedController] prefsController] setAutoStartDownloads:[sender isOn]];
}

- (IBAction)enableuTP:(id)sender
{
    [[[ITController sharedController] prefsController] setUTPEnabled:[sender isOn]];
}

- (IBAction)enableBlocklist:(id)sender
{
    [[[ITController sharedController] prefsController] setBlocklistEnabled:[sender isOn]];
}

- (IBAction)enableDHT:(id)sender
{
    [[[ITController sharedController] prefsController] setDHTEnabled:[sender isOn]];
}

- (IBAction)enablePEX:(id)sender
{
    [[[ITController sharedController] prefsController] setPEXEnabled:[sender isOn]];
}

- (IBAction)RPCUsernamechanged:(id)sender
{
    [[[ITController sharedController] prefsController] setRPCUsername:[sender string]];
}

- (IBAction)RPCPasswordchanged:(id)sender
{
    [[[ITController sharedController] prefsController] setRPCPassword:[sender string]];
}

- (IBAction)downloadDirChanged:(id)sender
{
    [[[ITController sharedController] prefsController] setDownloadDir:[sender string]];
}

- (ITKeyboardToolbarOptions)keyboardOptionsForTextField:(UITextField*)textField
{
    return ITKeyboardOptionDone | ITKeyboardOptionCancel | ITKeyboardOptionResetToDefault;
}

- (BOOL)textFieldCanFinishEditing:(UITextField*)textField withText:(NSString *)string
{
    if (textField == self.RPCPortTextField) {
        NSInteger port = [string integerValue];
        if (IN_RANGE(port, 1025, 65535)) {
            return YES;
        }
        return NO;
    }
    return YES;
}

- (void)textFieldFinishedEditing:(UITextField *)textField
{
    if (textField == self.RPCPortTextField || textField == self.bindPortTextField || textField == self.MaxPeersPerTorrent || self.MaxPeersGlobal || self.DownloadLimit || self.UploadLimit) {
        NSInteger port = [textField.text integerValue];
        NSInteger limit = [textField.text integerValue];
        if (textField == self.RPCPortTextField)
            [[[ITController sharedController] prefsController] setRPCPort:port];
        if (textField == self.bindPortTextField)
            [[[ITController sharedController] prefsController] setPort:port];
        if (textField == self.MaxPeersPerTorrent)
            [[[ITController sharedController] prefsController] setPeersPerTorrent:limit];
        if (textField == self.MaxPeersGlobal)
            [[[ITController sharedController] prefsController] setPeersGlobalLimit:limit];
        if (textField == self.DownloadLimit)
            [[[ITController sharedController] prefsController] setDownloadLimit:limit];
        if (textField == self.UploadLimit)
            [[[ITController sharedController] prefsController] setUploadLimit:limit];
    }
}

- (NSString *)defaultTextForTextField:(UITextField *)textField
{
    if (textField == self.RPCPortTextField)
        return @"9091";
    if (textField == self.bindPortTextField)
        return @"51413";
    if (textField == self.MaxPeersPerTorrent)
        return @"60";
    if (textField == self.MaxPeersGlobal)
        return @"200";
    return nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait || interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

- (NSIndexPath*)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 && indexPath.row == 2) 
        return indexPath;
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0 && indexPath.row == 2) {
        NSURL *URL = [NSURL URLWithString:[self.webInterfaceURLTextView text]];
        [[ITAppDelegate sharedDelegate] requestToOpenURL:URL];
    }
}

@end
