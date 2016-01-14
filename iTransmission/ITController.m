//
//  ITController.m
//  iTransmission
//
//  Created by Mike Chen on 10/22/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ITController.h"
#import "ITPrefsController.h"
#import <libtransmission/variant.h>
#import <libtransmission/utils.h>
#import "ITPrefsController.h"
#import "ITTorrent.h"
#import "ITTorrentGroup.h"
#import "ITStatistics.h"
#import "ITApplication.h"
#import "ITAppDelegate.h"
#import "ITLogger.h"
#import "ITAddTorrentOptionsViewController.h"

static void altSpeedToggledCallback(tr_session * handle UNUSED, bool active, bool byUser, void * controller)
{
    NSDictionary * dict = [[NSDictionary alloc] initWithObjectsAndKeys: [[NSNumber alloc] initWithBool: active], @"Active",
                           [[NSNumber alloc] initWithBool: byUser], @"ByUser", nil];
    [(__bridge ITController *)controller performSelectorOnMainThread: @selector(altSpeedToggledCallbackIsLimited:)
                                                 withObject: dict waitUntilDone: NO];
}

static tr_rpc_callback_status rpcCallback(tr_session * handle UNUSED, tr_rpc_callback_type type, struct tr_torrent * torrentStruct,
                                          void * controller)
{
    [(__bridge ITController *)controller rpcCallback: type forTorrentStruct: torrentStruct];
    return TR_RPC_NOREMOVE; //we'll do the remove manually
}

// Can we do the same on ios? e.g. callback on lock? */
/*
static void sleepCallback(void * controller, io_service_t y, natural_t messageType, void * messageArgument)
{
    [(__bridge ITController *)controller sleepCallback: messageType argument: messageArgument];
}
 */

@implementation ITController

@synthesize prefsController = _prefsController;
@synthesize torrents = _torrents;
@synthesize handle = _handle;
@synthesize pauseOnLaunch = _pauseOnLaunch;
@synthesize unconfirmedTorrents = _unconfirmedTorrents;
@synthesize loggingEnabled = _loggingEnabled;

NSUserDefaults* userDefaults;

+ (id)sharedController
{
    return [(ITAppDelegate*)[[UIApplication sharedApplication] delegate] controller];
}

- (NSString*)transfersPlistPath
{
    return [[ITApplication defaultDocumentsPath] stringByAppendingPathComponent:@"transfers.plist"];
}

- (NSString*)configPath
{
    return [[ITApplication defaultDocumentsPath] stringByAppendingPathComponent:@"config"];

}
- (NSString*)downloadPath
{
    return [[ITApplication defaultDocumentsPath] stringByAppendingPathComponent:@"download"];
}

- (NSString*)incompletePath
{
    return [[ITApplication defaultDocumentsPath] stringByAppendingPathComponent:@"incomplete"];
}

- (void)createPathsIfNeeded
{
    BOOL *fileExists;
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    LogMessageCompat(@"Using document directory: %@\n", [ITApplication defaultDocumentsPath]);
    [fileManager createDirectoryAtPath:[ITApplication defaultDocumentsPath] withIntermediateDirectories:YES attributes:nil error:nil];
    [fileManager createDirectoryAtPath:[self configPath] withIntermediateDirectories:YES attributes:nil error:nil];
    [fileManager createDirectoryAtPath:[self downloadPath] withIntermediateDirectories:YES attributes:nil error:nil];
    [fileManager createDirectoryAtPath:[self incompletePath] withIntermediateDirectories:YES attributes:nil error:nil];
    fileExists = [[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Documents/iTransmission/transfers.plist"];
    if(fileExists == FALSE)
    {
        [fileManager createFileAtPath:@"/var/mobile/Documents/iTransmission/transfers.plist" contents:nil attributes:nil];
    }
}

- (void)logUsedPaths
{
    LogMessageCompat(@"Documents: %@\n", [ITApplication defaultDocumentsPath]);
    LogMessageCompat(@"Download: %@\n", [self downloadPath]);
    LogMessageCompat(@"Incomplete: %@\n", [self incompletePath]);
    LogMessageCompat(@"Config: %@\n", [self configPath]);
    LogMessageCompat(@"Transfer.plist: %@\n", [self transfersPlistPath]);
}

- (id)init
{
    if (self = [super init]) {
        [self setLoggingEnabled:NO];
        [[ITAppDelegate sharedDelegate] registerForTimerEvent:self];
        
        [self createPathsIfNeeded];
        [self logUsedPaths];
        
        userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults registerDefaults: [NSDictionary dictionaryWithContentsOfFile:
                                         [[NSBundle mainBundle] pathForResource: @"Defaults" ofType: @"plist"]]];
        
        tr_variant settings;
        tr_variantInitDict(&settings, 41);
        tr_sessionGetDefaultSettings(&settings);
        
        /* We don't care alternative speed limits but we leave them there if users prefer to use*/
        const BOOL usesSpeedLimitSched = [userDefaults boolForKey: @"SpeedLimitAuto"];
        if (!usesSpeedLimitSched)
            tr_variantDictAddBool(&settings, TR_KEY_alt_speed_enabled, [userDefaults boolForKey: @"SpeedLimit"]);
        
        tr_variantDictAddInt(&settings, TR_KEY_alt_speed_up, [userDefaults integerForKey: @"SpeedLimitUploadLimit"]);
        tr_variantDictAddInt(&settings, TR_KEY_alt_speed_down, [userDefaults integerForKey: @"SpeedLimitDownloadLimit"]);
        
        tr_variantDictAddBool(&settings, TR_KEY_alt_speed_time_enabled, [userDefaults boolForKey: @"SpeedLimitAuto"]);
        tr_variantDictAddInt(&settings, TR_KEY_alt_speed_time_begin, [ITPrefsController dateToTimeSum:
                                                                         [userDefaults objectForKey: @"SpeedLimitAutoOnDate"]]);
        tr_variantDictAddInt(&settings, TR_KEY_alt_speed_time_end, [ITPrefsController dateToTimeSum:
                                                                       [userDefaults objectForKey: @"SpeedLimitAutoOffDate"]]);
        tr_variantDictAddInt(&settings, TR_KEY_alt_speed_time_day, [userDefaults integerForKey: @"SpeedLimitAutoDay"]);
        
        tr_variantDictAddInt(&settings, TR_KEY_speed_limit_down, [userDefaults integerForKey: @"DownloadLimit"]);
        tr_variantDictAddBool(&settings, TR_KEY_speed_limit_down_enabled, [userDefaults boolForKey: @"CheckDownload"]);
        tr_variantDictAddInt(&settings, TR_KEY_speed_limit_up, [userDefaults integerForKey: @"UploadLimit"]);
        tr_variantDictAddBool(&settings, TR_KEY_speed_limit_up_enabled, [userDefaults boolForKey: @"CheckUpload"]);
        
        //hidden prefs
        if ([userDefaults objectForKey: @"BindAddressIPv4"])
            tr_variantDictAddStr(&settings, TR_KEY_bind_address_ipv4, [[userDefaults stringForKey: @"BindAddressIPv4"] UTF8String]);
        if ([userDefaults objectForKey: @"BindAddressIPv6"])
            tr_variantDictAddStr(&settings, TR_KEY_bind_address_ipv6, [[userDefaults stringForKey: @"BindAddressIPv6"] UTF8String]);
        
        tr_variantDictAddBool(&settings, TR_KEY_blocklist_enabled, [userDefaults boolForKey: @"BlocklistEnabled"]);
        if ([userDefaults objectForKey: @"BlocklistURL"])
            tr_variantDictAddStr(&settings, TR_KEY_blocklist_url, [[userDefaults stringForKey: @"BlocklistURL"] UTF8String]);
        tr_variantDictAddBool(&settings, TR_KEY_dht_enabled, [userDefaults boolForKey: @"DHTGlobal"]);

        if ([[userDefaults stringForKey:@"DownloadFolder"] isAbsolutePath])
            tr_variantDictAddStr(&settings, TR_KEY_download_dir, [[[userDefaults stringForKey: @"DownloadFolder"] stringByExpandingTildeInPath] UTF8String]);
        else 
            tr_variantDictAddStr(&settings, TR_KEY_download_dir, [[self downloadPath] UTF8String]);
        
        tr_variantDictAddBool(&settings, TR_KEY_download_queue_enabled, [userDefaults boolForKey: @"Queue"]);
        tr_variantDictAddInt(&settings, TR_KEY_download_queue_size, [userDefaults integerForKey: @"QueueDownloadNumber"]);
        tr_variantDictAddInt(&settings, TR_KEY_idle_limit, [userDefaults integerForKey: @"IdleLimitMinutes"]);
        tr_variantDictAddBool(&settings, TR_KEY_idle_seeding_limit_enabled, [userDefaults boolForKey: @"IdleLimitCheck"]);
        if ([[userDefaults stringForKey:@"IncompleteDownloadFolder"] isAbsolutePath]) 
            tr_variantDictAddStr(&settings, TR_KEY_incomplete_dir, [[[userDefaults stringForKey: @"IncompleteDownloadFolder"]
                                                                    stringByExpandingTildeInPath] UTF8String]);
        else
            tr_variantDictAddStr(&settings, TR_KEY_incomplete_dir, [[self downloadPath] UTF8String]);

        tr_variantDictAddBool(&settings, TR_KEY_incomplete_dir_enabled, [userDefaults boolForKey: @"UseIncompleteDownloadFolder"]);
        tr_variantDictAddBool(&settings, TR_KEY_lpd_enabled, [userDefaults boolForKey: @"LocalPeerDiscoveryGlobal"]);
        tr_variantDictAddInt(&settings, TR_KEY_message_level, TR_LOG_DEBUG);
        tr_variantDictAddInt(&settings, TR_KEY_peer_limit_global, [userDefaults integerForKey: @"PeersTotal"]);
        tr_variantDictAddInt(&settings, TR_KEY_peer_limit_per_torrent, [userDefaults integerForKey: @"PeersTorrent"]);
        
        const BOOL randomPort = [userDefaults boolForKey: @"RandomPort"];
        tr_variantDictAddBool(&settings, TR_KEY_peer_port_random_on_start, randomPort);
        if (!randomPort)
            tr_variantDictAddInt(&settings, TR_KEY_peer_port, [userDefaults integerForKey: @"BindPort"]);
        
        //hidden pref
        if ([userDefaults objectForKey: @"PeerSocketTOS"])
            tr_variantDictAddStr(&settings, TR_KEY_peer_socket_tos, [[userDefaults stringForKey: @"PeerSocketTOS"] UTF8String]);
        
        tr_variantDictAddBool(&settings, TR_KEY_pex_enabled, [userDefaults boolForKey: @"PEXGlobal"]);
        tr_variantDictAddBool(&settings, TR_KEY_port_forwarding_enabled, [userDefaults boolForKey: @"NatTraversal"]);
        tr_variantDictAddBool(&settings, TR_KEY_queue_stalled_enabled, [userDefaults boolForKey: @"CheckStalled"]);
        tr_variantDictAddInt(&settings, TR_KEY_queue_stalled_minutes, [userDefaults integerForKey: @"StalledMinutes"]);
        tr_variantDictAddReal(&settings, TR_KEY_ratio_limit, [userDefaults floatForKey: @"RatioLimit"]);
        tr_variantDictAddBool(&settings, TR_KEY_ratio_limit_enabled, [userDefaults boolForKey: @"RatioCheck"]);
        tr_variantDictAddBool(&settings, TR_KEY_rename_partial_files, [userDefaults boolForKey: @"RenamePartialFiles"]);
        tr_variantDictAddBool(&settings, TR_KEY_rpc_authentication_required,  [userDefaults boolForKey: @"RPCAuthorize"]);
        tr_variantDictAddBool(&settings, TR_KEY_rpc_enabled,  [userDefaults boolForKey: @"RPC"]);
        tr_variantDictAddInt(&settings, TR_KEY_rpc_port, [userDefaults integerForKey: @"RPCPort"]);
        tr_variantDictAddStr(&settings, TR_KEY_rpc_username,  [[userDefaults stringForKey: @"RPCUsername"] UTF8String]);
        tr_variantDictAddBool(&settings, TR_KEY_rpc_whitelist_enabled,  [userDefaults boolForKey: @"RPCUseWhitelist"]);
        tr_variantDictAddBool(&settings, TR_KEY_seed_queue_enabled, [userDefaults boolForKey: @"QueueSeed"]);
        tr_variantDictAddInt(&settings, TR_KEY_seed_queue_size, [userDefaults integerForKey: @"QueueSeedNumber"]);
        tr_variantDictAddBool(&settings, TR_KEY_start_added_torrents, [userDefaults boolForKey: @"AutoStartDownload"]);
        tr_variantDictAddBool(&settings, TR_KEY_torrent_complete_notification_enabled, [userDefaults boolForKey: @"DoneScriptEnabled"]);
        tr_variantDictAddStr(&settings, TR_KEY_torrent_complete_notification_command, [[userDefaults stringForKey: @"DoneScriptPath"] UTF8String]);
        tr_variantDictAddBool(&settings, TR_KEY_utp_enabled, [userDefaults boolForKey: @"UTPGlobal"]);
        
        tr_formatter_size_init(1000,
                               [NSLocalizedString(@"KB", "File size - kilobytes") UTF8String],
                               [NSLocalizedString(@"MB", "File size - megabytes") UTF8String],
                               [NSLocalizedString(@"GB", "File size - gigabytes") UTF8String],
                               [NSLocalizedString(@"TB", "File size - terabytes") UTF8String]);
        
        tr_formatter_speed_init(1000,
                                [NSLocalizedString(@"KB/s", "Transfer speed (kilobytes per second)") UTF8String],
                                [NSLocalizedString(@"MB/s", "Transfer speed (megabytes per second)") UTF8String],
                                [NSLocalizedString(@"GB/s", "Transfer speed (gigabytes per second)") UTF8String],
                                [NSLocalizedString(@"TB/s", "Transfer speed (terabytes per second)") UTF8String]); //why not?
        
        tr_formatter_mem_init(1024, [NSLocalizedString(@"KB", "Memory size - kilobytes") UTF8String],
                              [NSLocalizedString(@"MB", "Memory size - megabytes") UTF8String],
                              [NSLocalizedString(@"GB", "Memory size - gigabytes") UTF8String],
                              [NSLocalizedString(@"TB", "Memory size - terabytes") UTF8String]);
        
        self.pauseOnLaunch = [userDefaults boolForKey:@"PauseOnLaunch"];
        
        const char * configDir = [[self configPath] UTF8String];
        self.handle = tr_sessionInit("ios", configDir, YES, &settings);
        tr_variantFree(&settings);
        
        self.torrents = [[NSMutableArray alloc] init];
        self.unconfirmedTorrents = [[NSMutableArray alloc] init];
        self.prefsController = [[ITPrefsController alloc] initWithHandle:self.handle];
        
        tr_sessionSetAltSpeedFunc(self.handle, altSpeedToggledCallback, (__bridge void*)self);
        if (usesSpeedLimitSched)
            [userDefaults setBool:tr_sessionUsesAltSpeed(self.handle) forKey: @"SpeedLimit"];
        
        tr_sessionSetRPCCallback(self.handle, rpcCallback, (__bridge void*)self);
        
        [self loadTorrentHistory];
    }
    return self;
}

- (void)shutdown
{
    [[ITAppDelegate sharedDelegate] unregisterForTimerEvent:self];
    tr_sessionClose(self.handle);
}

- (void)timerFiredAfterDelay:(NSTimeInterval)timeInternalSinceLastCall
{
    [self updateStatistics];
        
    if ([self isLoggingEnabled]) {
        [self pumpLogMessages];
    }
}

- (void)pumpLogMessages
{
    static NSString *libtransmissionDomain = @"libtransmission";
    
    const tr_log_message * l;
    
    /*
     TR_MSG_ERR = 1,
     TR_MSG_INF = 2,
     TR_MSG_DBG = 3
     */
    
    tr_log_message * list = tr_logGetQueue( );

    for( l=list; l!=NULL; l=l->next ) {
        LogMessage(libtransmissionDomain, l->level, @"%s %s (%s:%d)", l->name, l->message, l->file, l->line );
    }
    
    tr_logFreeQueue( list );
}

- (void)updateStatistics
{
    ITStatistics *s = [[ITStatistics alloc] init];
    CGFloat dlRate = 0.0, ulRate = 0.0;
    BOOL completed = NO;
    for (ITTorrent * torrent in self.torrents)
    {
        [torrent update];
        
        //pull the upload and download speeds - most consistent by using current stats
        dlRate += [torrent downloadRate];
        ulRate += [torrent uploadRate];
        
        completed |= [torrent isFinishedSeeding];
    }
    s.downloadRate = dlRate;
    s.uploadRate = ulRate;
    s.completed = completed;
    
    tr_session_stats stats;
    tr_sessionGetCumulativeStats(self.handle, &stats);
    s.cumulativeDownload = stats.downloadedBytes;
    s.cumulativeUpload = stats.uploadedBytes;
    s.cumulativeRatio = stats.ratio;
    
    tr_sessionGetStats(self.handle, &stats);
    s.sessionRatio = stats.ratio;
    s.sessionDownload = stats.downloadedBytes;
    s.sessionUpload = stats.uploadedBytes;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kITNewStatisticsAvailableNotification object:nil userInfo:[NSDictionary dictionaryWithObject:s forKey:@"statistics"]];
}

- (void)loadTorrentHistory
{
    NSArray * history = [NSArray arrayWithContentsOfFile:[self transfersPlistPath]];
    NSMutableArray *loadedTorrents = [NSMutableArray arrayWithCapacity:[history count]];
    
    if (history)
    {
        NSMutableArray * waitToStartTorrents = [NSMutableArray arrayWithCapacity: (([history count] > 0 && !self.pauseOnLaunch) ? [history count]-1 : 0)]; //theoretical max without doing a lot of work
        
        for (NSDictionary * historyItem in history)
        {
            ITTorrent* torrent;
            if ((torrent = [[ITTorrent alloc] initWithHistory: historyItem lib: self.handle forcePause: self.pauseOnLaunch]))
            {
                [self.torrents addObject: torrent];
                [loadedTorrents addObject: torrent];
                
                NSNumber * waitToStart;
                if (!self.pauseOnLaunch && (waitToStart = [historyItem objectForKey: @"WaitToStart"]) && [waitToStart boolValue])
                    [waitToStartTorrents addObject: torrent];
                }
        }
        
        //now that all are loaded, let's set those in the queue to waiting
        for (ITTorrent * torrent in waitToStartTorrents)
            [torrent startTransfer];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kITTorrentHistoryLoadedNotification object:nil userInfo:[NSDictionary dictionaryWithObject:loadedTorrents forKey:@"torrents"]];
}

- (void)updateTorrentHistory
{
    NSMutableArray * history = [NSMutableArray arrayWithCapacity:[self.torrents count]];
    
    for (ITTorrent * torrent in self.torrents)
        [history addObject: [torrent history]];
    
    [history writeToFile:[self transfersPlistPath] atomically: YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:kITTorrentHistorySavedNotification object:nil userInfo:[NSDictionary dictionaryWithObject:self.torrents forKey:@"torrents"]];
}

- (void)sleepAllTransfers
{
    [self.torrents makeObjectsPerformSelector:@selector(sleep)];
}

- (void)wakeupAllTransfers
{
    [self.torrents makeObjectsPerformSelector:@selector(wakeUp)];
}

- (void)startAllTransfers
{
    [self.torrents makeObjectsPerformSelector:@selector(startTransfer)];
}

- (void)stopAllTransfers
{
    [self.torrents makeObjectsPerformSelector:@selector(stopTransfer)];
}

- (void)confirmRemoveTorrents: (NSArray *) torrents deleteData: (BOOL) deleteData
{
    /*
    NSMutableArray * selectedValues = [NSMutableArray arrayWithArray: [fTableView selectedValues]];
    [selectedValues removeObjectsInArray: torrents];
    */
     
    //don't want any of these starting then stopping
    for (ITTorrent *torrent in torrents)
        if ([torrent waitingToStart])
            [torrent stopTransfer];
    
    [self.torrents removeObjectsInArray: torrents];
    
    for (ITTorrent *torrent in torrents) {
        [torrent closeRemoveTorrent: deleteData];
        [[NSNotificationCenter defaultCenter] postNotificationName:kITTorrentAboutToBeRemovedNotification object:nil userInfo:[NSDictionary dictionaryWithObject:torrent forKey:@"torrent"]];
    }
    
    [self performSelector:@selector(_delayedRemovalOfTorrents:) withObject:torrents afterDelay:0.2f];
}

- (void)_delayedRemovalOfTorrents:(NSArray*)torrents
{
    [self.torrents removeObjectsInArray:torrents];
}

- (void) rpcCallback: (tr_rpc_callback_type) type forTorrentStruct: (struct tr_torrent *) torrentStruct
{    
    //get the torrent
    ITTorrent * torrent = nil;
    if (torrentStruct != NULL && (type != TR_RPC_TORRENT_ADDED && type != TR_RPC_SESSION_CHANGED && type != TR_RPC_SESSION_CLOSE))
    {
        for (torrent in self.torrents)
            if (torrentStruct == [torrent torrentStruct])
            {
                break;
            }
        
        if (!torrent)
        {            
            LogMessageCompat(@"No torrent found matching the given torrent struct from the RPC callback!");
            return;
        }
    }
    
    switch (type)
    {
        case TR_RPC_TORRENT_ADDED:
            [self performSelectorOnMainThread: @selector(rpcAddTorrentStruct:) withObject:
             [NSValue valueWithPointer: torrentStruct] waitUntilDone: NO];
            break;
            
        case TR_RPC_TORRENT_STARTED:
        case TR_RPC_TORRENT_STOPPED:
            [self performSelectorOnMainThread: @selector(rpcStartedStoppedTorrent:) withObject: torrent waitUntilDone: NO];
            break;
            
        case TR_RPC_TORRENT_REMOVING:
            [self performSelectorOnMainThread: @selector(rpcRemoveTorrent:) withObject: torrent waitUntilDone: NO];
            break;
            
        case TR_RPC_TORRENT_TRASHING:
            [self performSelectorOnMainThread: @selector(rpcRemoveTorrentDeleteData:) withObject: torrent waitUntilDone: NO];
            break;
            
        case TR_RPC_TORRENT_CHANGED:
            [self performSelectorOnMainThread: @selector(rpcChangedTorrent:) withObject: torrent waitUntilDone: NO];
            break;
            
        case TR_RPC_TORRENT_MOVED:
            [self performSelectorOnMainThread: @selector(rpcMovedTorrent:) withObject: torrent waitUntilDone: NO];
            break;
            
        case TR_RPC_SESSION_QUEUE_POSITIONS_CHANGED:
            [self performSelectorOnMainThread: @selector(rpcUpdateQueue) withObject: nil waitUntilDone: NO];
            break;
            
        case TR_RPC_SESSION_CHANGED:
            [self.prefsController performSelectorOnMainThread: @selector(rpcUpdatePrefs) withObject: nil waitUntilDone: NO];
            break;
            
        case TR_RPC_SESSION_CLOSE:
            LogMessageCompat(@"TR_RPC_SESSION_CLOSE ignored!!!\n");
            break;
        default:
            NSAssert1(NO, @"Unknown RPC command received: %d", type);
    }
}

- (void) rpcAddTorrentStruct: (NSValue *) torrentStructPtr
{
    tr_torrent * torrentStruct = (tr_torrent *)[torrentStructPtr pointerValue];
    
    NSString * location = nil;
    if (tr_torrentGetDownloadDir(torrentStruct) != NULL)
        location = [NSString stringWithUTF8String: tr_torrentGetDownloadDir(torrentStruct)];
    
    ITTorrent * torrent = [[ITTorrent alloc] initWithTorrentStruct: torrentStruct location: location lib: self.handle];
    
    //change the location if the group calls for it (this has to wait until after the torrent is created)
    /*
    if ([[GroupsController groups] usesCustomDownloadLocationForIndex: [torrent groupValue]])
    {
        location = [[GroupsController groups] customDownloadLocationForIndex: [torrent groupValue]];
        [torrent changeDownloadFolderBeforeUsing: location];
    }
     */
    
    [self.torrents addObject: torrent];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kITNewTorrentAddedNotification object:nil userInfo:[NSDictionary dictionaryWithObject:torrent forKey:@"torrent"]];
}

- (void) rpcRemoveTorrent: (ITTorrent *) torrent
{
    [self confirmRemoveTorrents: [NSArray arrayWithObject: torrent] deleteData: NO];
}

- (void) rpcRemoveTorrentDeleteData: (ITTorrent *) torrent
{
    [self confirmRemoveTorrents: [NSArray arrayWithObject: torrent] deleteData: YES];
}

- (void) rpcStartedStoppedTorrent: (ITTorrent *) torrent
{
    [torrent update];
    
    [self updateTorrentHistory];
    [[NSNotificationCenter defaultCenter] postNotificationName:kITTorrentStateChangedNotification object:nil userInfo:[NSDictionary dictionaryWithObject:torrent forKey:@"torrent"]];
}

- (void) rpcChangedTorrent: (ITTorrent *) torrent
{
    [torrent update];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kITTorrentChangedNotification object:nil userInfo:[NSDictionary dictionaryWithObject:torrent forKey:@"torrent"]];
}

- (void) rpcMovedTorrent: (ITTorrent *) torrent
{
    [torrent update];
}

- (void) rpcUpdateQueue
{
    /*
    for (ITTorrent * torrent in self.torrents)
        [torrent update];
    
    NSArray * selectedValues = [fTableView selectedValues];
    
    NSSortDescriptor * descriptor = [[NSSortDescriptor alloc] initWithKey: @"queuePosition" ascending: YES];
    NSArray * descriptors = [NSArray arrayWithObject: descriptor];
    [descriptor release];
    
    [fTorrents sortUsingDescriptors: descriptors];
    
    [self fullUpdateUI];
    
    [fTableView selectValues: selectedValues];
     */
}

- (void)openFilesWithDict:(NSDictionary *)dictionary
{
    [self openFiles: [dictionary objectForKey: @"Filenames"] addType: [[dictionary objectForKey: @"AddType"] intValue]];
}

- (BOOL)openFiles:(NSArray *)filenames addType:(ITAddType)type
{
    BOOL deleteTorrentFile, canToggleDelete = YES;
    BOOL retval = YES;
    switch (type)
    {
        case ITAddTypeCreated:
            deleteTorrentFile = NO;
            canToggleDelete = NO;
            break;
        case ITAddTypeURL:
            deleteTorrentFile = YES;
            break;
        default:
            deleteTorrentFile = NO;
    }
    
    for (NSString * torrentPath in filenames)
    {
        //ensure torrent doesn't already exist
        tr_ctor * ctor = tr_ctorNew(self.handle);
        tr_ctorSetMetainfoFromFile(ctor, [torrentPath UTF8String]);
        
        tr_info info;
        const tr_parse_result result = tr_torrentParse(ctor, &info);
        tr_ctorFree(ctor);
        
        if (result != TR_PARSE_OK)
        {
            if (result == TR_PARSE_DUPLICATE)
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:kITAttemptToAddDuplicateTorrentNotification object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithUTF8String:info.name], @"ExistingTorrentName", torrentPath, @"TorrentPath", [NSNumber numberWithInteger:type], @"AddType", nil]];
                UIAlertView *alert;
                alert = [[UIAlertView alloc] initWithTitle:@"Duplicate Torrent" message:@"You are trying to add a torrent that has already been added" delegate:nil cancelButtonTitle:@"Ok!" otherButtonTitles:nil, nil];
                [alert show];
            }
            else if (result == TR_PARSE_ERR)
            {
                if (type != ITAddTypeAuto) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:kITAttemptToAddInvalidTorrentNotification object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:torrentPath, @"TorrentPath", [NSNumber numberWithInteger:type], @"AddType", nil]];
                    UIAlertView *alert;
                    alert = [[UIAlertView alloc] initWithTitle:@"Torrent Error" message:@"You are trying to add an invalid torrent file" delegate:nil cancelButtonTitle:@"Ok!" otherButtonTitles:nil, nil];
                    [alert show];
                    retval = YES;
                }
            }
            else
                NSAssert2(NO, @"Unknown error code (%d) when attempting to open \"%@\"", result, torrentPath);
            UIAlertView *alert;
            alert = [[UIAlertView alloc] initWithTitle:@"Unknown error" message:@"Unknown eror" delegate:nil cancelButtonTitle:@"Ok!" otherButtonTitles:nil, nil];
            [alert show];
            
            tr_metainfoFree(&info);
            retval = NO;
            continue;
        }
        
        //determine download location
        NSString * location = [self getDownloadLocation];

        //determine to show the options window
        const BOOL showWindow = type == [[NSUserDefaults standardUserDefaults] boolForKey: @"DownloadAsk"] && ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive && false);
        tr_metainfoFree(&info);
        
        ITTorrent * torrent;
        if (!(torrent = [[ITTorrent alloc] initWithPath: torrentPath location: location
                                      deleteTorrentFile: showWindow ? YES : deleteTorrentFile lib:self.handle])) {
            retval = NO;
            continue;
        }
        
        //verify the data right away if it was newly created
        if (type == ITAddTypeCreated)
            [torrent resetCache];
        
        //show the add window or add directly
        if (showWindow || !location)
        {
            ITAddTorrentOptionsViewController * addController = [[ITAddTorrentOptionsViewController alloc] initWithPrebuiltTorrent:torrent];
             [[ITNavigationController alloc] pushViewController:addController animated:YES];
        }
        else
        {
            [torrent startTransfer];
            
            [torrent update];
            [self.torrents addObject: torrent];
            [[NSNotificationCenter defaultCenter] postNotificationName:kITNewTorrentAddedNotification object:nil userInfo:[NSDictionary dictionaryWithObject:torrent forKey:@"torrent"]];
            [self updateTorrentHistory];
        }
    }
    return retval;
}

- (BOOL)openMagnet:(NSArray *)urls
{
    BOOL retval = YES;
    
    //ensure torrent doesn't already exist
    for (NSString * magnetPath in urls)
    {
        tr_ctor * ctor = tr_ctorNew(self.handle);
        tr_ctorSetMetainfoFromMagnetLink(ctor, [magnetPath UTF8String]);
        
        tr_ctorFree(ctor);
        
        //determine download location
        NSString * location = [self getDownloadLocation];
        
        ITTorrent * torrent = [[ITTorrent alloc] initWithMagnetAddress: magnetPath location: location
                                                    lib:self.handle];
        
        [torrent resetCache];
        [torrent startTransfer];
        
        [torrent update];
        [self.torrents addObject: torrent];
        [[NSNotificationCenter defaultCenter] postNotificationName:kITNewTorrentAddedNotification object:nil userInfo:[NSDictionary dictionaryWithObject:torrent forKey:@"torrent"]];
        [self updateTorrentHistory];
    }
    return retval;
}

- (NSString *)getDownloadLocation
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return documentsDirectory;
}
@end