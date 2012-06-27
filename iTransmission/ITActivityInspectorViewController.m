//
//  ITActivityInspectorViewController.m
//  iTransmission
//
//  Created by Mike Chen on 11/9/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ITActivityInspectorViewController.h"
#import "ITTorrent.h"

@implementation ITActivityInspectorViewController
@synthesize peersCell;
@synthesize sizeCell;
@synthesize trackersCell;
@synthesize info;

- (id)initWithTorrent:(ITTorrent*)torrent
{
    self = [super initWithNibName:nil bundle:nil torrent:torrent];
    if (self) {
        self.title = @"Activity";
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

- (void)loadView
{
    self.view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
}

- (UITableViewCell *)peersCell
{
    NSString *inStr = [NSString stringWithFormat:@"%d", [[self.torrent peers] count]];
    if (peersCell) return peersCell;
    else {
        peersCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
        peersCell.textLabel.text = @"Peers Connected: ";
        peersCell.detailTextLabel.text = inStr;
    }
    return peersCell;
}

- (UITableViewCell *)sizeCell
{
    if (sizeCell) return sizeCell;
    else {
        sizeCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
        sizeCell.textLabel.text = @"Size: ";
        NSString *intString = [NSString stringWithFormat:@"%d", [self.torrent size]];
        sizeCell.detailTextLabel.text = intString;
    }
    return sizeCell;
}

- (UITableViewCell *)trackersCell
{
    NSString *inStr = [NSString stringWithFormat:@"%d", [self.torrent trackerCount]];
    if (trackersCell) return trackersCell;
    else {
        trackersCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
        trackersCell.textLabel.text = @"Number of trackers: ";
        trackersCell.detailTextLabel.text = inStr;
    }
    return trackersCell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return 3;
            break;
        default:
            break;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 0: return self.peersCell;
                case 1: return self.sizeCell;
                case 2: return self.trackersCell;
            }
    }
    return nil;
}


/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}
*/

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
