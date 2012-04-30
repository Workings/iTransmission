//
//  ITPeersInspectorCell.m
//  iTransmission
//
//  Created by user on 4/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ITPeersInspectorCell.h"

@implementation ITPeersInspectorCell
@synthesize nameLabel;
@synthesize view;

- (void)awakeFromNib
{
    [self.view removeFromSuperview];
    [self addSubview:self.view];
    /* this does the trick */
    [self.view removeFromSuperview];
    [self insertSubview:self.view atIndex:1];
    [self.view setBackgroundColor:[UIColor colorWithWhite:0.8f alpha:1.0f]];
}

@end
