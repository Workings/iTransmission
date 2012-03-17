//
//  ITApplication.h
//  iTransmission
//
//  Created by Mike Chen on 10/22/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

NSString *fFolderPopUp;
@interface ITApplication : NSObject

+ (void)setExecutionPath:(const char *)path;
+ (NSString*)defaultDocumentsPath;
+ (NSString*)homeDocumentsPath;
+ (NSString*)applicationPath;
@end
