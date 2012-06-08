//
//  ITActivityInspectorViewController.h
//  iTransmission
//
//  Created by Mike Chen on 11/9/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ITInspectorBaseViewController.h"
#import <libtransmission/transmission.h>

@interface ITActivityInspectorViewController : ITInspectorBaseViewController

@property (nonatomic, strong) UITableViewCell *peersCell;
@property (nonatomic, strong) UITableViewCell *sizeCell;
@property (nonatomic, strong) UITableViewCell *trackersCell;
@property (assign, nonatomic) tr_info *info;

@end
