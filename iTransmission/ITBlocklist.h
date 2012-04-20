//
//  ITBlocklist.h
//  iTransmission
//
//  Created by user on 4/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ITBlocklist : NSObject

- (void)downloadBlocklist:(NSString *)URL;
size_t write_data2(void *ptr, size_t size, size_t nmemb, FILE *stream);

@end
