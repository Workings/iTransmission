//
//  ITPeersInspectorViewController.m
//  iTransmission
//
//  Created by Mike Chen on 11/9/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ITPeersInspectorViewController.h"
#import "ITPeersInspectorCell.h"
#import "ITTorrent.h"
#import "libtransmission/transmission.h"

@implementation ITPeersInspectorViewController

- (id)initWithTorrent:(ITTorrent*)torrent
{
    self = [super initWithNibName:nil bundle:nil torrent:torrent];
    if (self) {
        self.title = @"Peers";
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    self.view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    
    [self.view addSubview:self.tableView];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    if ([self.tableView respondsToSelector:@selector(registerNib:forCellReuseIdentifier:)]) {
        [self.tableView registerNib:[UINib nibWithNibName:@"ITPeersInspectorCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"ITPeersInspectorCell"];
    }
}

- (void)registerNotifications
{
    [super registerNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(torrentUpdated:) name:kITTorrentUpdatedNotification object:nil];
}

- (void)torrentUpdated:(NSNotification *)notification
{
    ITTorrent *updatedTorrent = [[notification userInfo] objectForKey:@"torrent"];
    if ([updatedTorrent isEqual:self.torrent]) {
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
    }
}

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}
*/

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self.torrent flatFileList] count];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath

{
    if ([self.torrent canChangeDownloadCheckForFiles:[[self.torrent peers] objectAtIndex:indexPath.row]]) {
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.torrent fileProgress:[[self.torrent flatFileList] objectAtIndex:indexPath.row]] == 1.00f) {
        return indexPath;
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ITPeersInspectorCell *cell = (ITPeersInspectorCell*)[tableView dequeueReusableCellWithIdentifier:@"ITPeersInspectorCell"];
    if (! [self.tableView respondsToSelector:@selector(registerNib:forCellReuseIdentifier:)]) {
        cell = (ITPeersInspectorCell*)[[[NSBundle mainBundle] loadNibNamed:@"ITPeersInspectorCell" owner:nil options:nil] objectAtIndex:0];
    }
    assert(cell);
    
    cell.nameLabel.text = [[[self.torrent peers] objectAtIndex:indexPath.row] name];

    cell.accessoryType = UITableViewCellAccessoryNone;
    
    return cell;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
