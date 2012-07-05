//
//  ITPrefsController.h
//  iTransmission
//
//  Created by Mike Chen on 10/22/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libtransmission/transmission.h>
#import "ITPrefViewController.h"

#define kITPrefsBindPortUpdatedNotification @"kITPrefsBindPortUpdated"
#define kITPrefsRandomBindPortFlagUpdatedNotification @"kITPrefsRandomBindPortFlagUpdated"
#define kITPrefsNatTraversalFlagUpdatedNotification @"kITPrefsNatTraversalFlagUpdated"
#define kITPrefsUTPFlagUpdateNotification @"kITPrefsUTPFlagUpdate"
#define kITPrefsPeersGlobalLimitUpdatedNotification @"kITPrefsPeersGlobalLimitUpdated"
#define kITPrefsPeersPerTorrentUpdatedNotification @"kITPrefsPeersPerTorrentUpdated"
#define kITPrefsDHTFlagUpdatedNotification @"kITPrefsDHTFlagUpdated"
#define kITPrefsLPDFlagUpdatedNotification @"kITPrefsLPDFlagUpdated"
#define kITPrefsPEXFlagUpdatedNotification @"kITPrefsPEXFlagUpdated"
#define kITPrefsAutoStartDownloadFlagUpdatedNotification @"kITPrefsAutoStartDownloadFlagUpdated"
#define kITPrefsRadioStopUpdatedNotification @"kITPrefsRadioStopUpdated"
#define kITPrefsRadioStopFlagUpdatedNotification @"kITPrefsRadioStopFlagUpdated"
#define kITPrefsUploadLimitUpdatedNotification @"kITPrefsUploadLimitUpdated"
#define kITPrefsDownloadLimitUpdatedNotification @"kITPrefsDownloadLimitUpdated"
#define kITPrefsUseIncompleteDownloadFolderFlagUpdatedNotification @"kITPrefsUseIncompleteDownloadFolderFlagUpdated"
#define kITPrefsRenamePartialFilesFlagUpdatedNotification @"kITPrefsRenamePartialFilesFlagUpdated"
#define kITPrefsRPCFlagUpdatedNotification @"kITPrefsRPCFlagUpdated"
#define kITPrefsRPCAuthorizationFlagUpdatedNotification @"kITPrefsRPCAuthorizationFlagUpdated"
#define kITPrefsRPCUsernameUpdatedNotification @"kITPrefsRPCUsernameUpdated"
#define kITPrefsRPCPasswordUpdatedNotification @"kITPrefsRPCPasswordUpdated"
#define kITPrefsRPCPortUpdatedNotification @"kITPrefsRPCPortUpdated"
#define kITPrefsRPCWhiteListFlagUpdatedNotification @"kITPrefsRPCWhiteListFlagUpdated"
#define kITPrefsUpdatedFromRPCNotification @"kITPrefsUpdatedFromRPC"
#define kITPrefsRPCWhiteListUpdatedNotification @"kITPrefsRPCWhiteListUpdated"
#define kITPrefsLimitUpdatedNotification @"CheckDownload"
#define kITPrefsBlocklistEnabled @"BlocklistEnabled"
bool fHasLoaded;
NSString *fUploadLimit;

@interface ITPrefsController : NSObject

@property (assign, nonatomic) tr_session *handle;
@property (nonatomic, strong) NSUserDefaults *userDefaults;
@property (nonatomic, strong) NSMutableArray *RPCWhitelistArray;
@property (nonatomic, strong) UITextField *fDownloadField;
@property (nonatomic, strong) UITextField *fUploadField;
- (id)initWithHandle:(tr_session*)h;
- (void)unload;
- (void)awakeFromNib;
- (void)setPort:(NSInteger)port;
- (void)setRandomPort;
- (void)setRandomPortOnStart:(BOOL)onStart;
- (void)setNatTraverselEnabled:(BOOL)enabled;
- (void)setUTPEnabled:(BOOL)enabled;
- (void)setPeersGlobalLimit:(NSInteger)limit;
- (void)setPeersPerTorrent:(NSInteger)limit;
- (void)setPEXEnabled:(BOOL)enabled;
- (void)setDHTEnabled:(BOOL)enabled;
- (void)setLPDEnabled:(BOOL)enabled;
- (void)setEncryptionMode:(tr_encryption_mode)mode;
- (void)setBlocklistEnabled:(BOOL)enabled;
- (void)setAutoStartDownloads:(BOOL)autostart;
- (void)setRadioStopEnabled:(BOOL)enabled;
- (void)setRatioStop:(CGFloat)ratio;
- (void)setUploadLimit:(NSInteger)limit;
- (void)setDownloadLimit:(NSInteger)limit;
- (void)setUseIncompleteFolder:(BOOL)enabled;
- (void)setRenamePartialFiles:(BOOL)enabled;
- (void)setRPCEnabled:(BOOL)enabled;
- (NSString*)linkToWebUI;
- (void)setRPCAuthorizionEnabled:(BOOL)enabled;
- (void)setRPCUsername:(NSString*)username;
- (void)setRPCPassword:(NSString*)password;
- (void)updateRPCPassword;
- (void)setRPCPort:(NSInteger)port;
- (void)setRPCUseWhitelistEnabled:(BOOL)enabled;
- (void)rpcUpdatePrefs;
- (void)setKeychainPassword: (const char *) password forService: (const char *) service username: (const char *) username;
- (void)updateRPCWhitelist;
- (void)setLimits:(BOOL)enabled;
+ (NSInteger)dateToTimeSum: (NSDate *) date;
+ (NSDate *)timeSumToDate: (NSInteger) sum;
- (BOOL)isRPCEnabled;
- (BOOL)isRPCAuthorizationEnabled;
- (BOOL)isNatTransversalEnabled;
- (BOOL)isLimitsEnabled;
- (BOOL)isAutoStartEnabled;
- (BOOL)isBlocklistEnabled;
- (BOOL)isUTPEnabled;
- (BOOL)isPexEnabled;
- (BOOL)isDHTEnabled;
- (NSInteger)RPCPort;
- (NSInteger)bindPort;
- (NSInteger)PeersPerTorrent;
- (NSInteger)PeersGlobal;
- (NSInteger)DownloadLimit;
- (NSInteger)UploadLimit;
- (NSString *)RPCUsername;
- (NSString *)RPCPassword;
- (NSString *)blocklistURL;
- (NSString *)downloadDir;

@end
