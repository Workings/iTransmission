#import "ITApplication.h"

BOOL __isInSandbox = YES;

@implementation ITApplication

+ (void)setExecutionPath:(const char *)path
{
    if (strncmp(path, "/Applications/", sizeof("/Applications/") == 0)) {
        __isInSandbox = YES;
    }
    else {
        __isInSandbox = NO;
    }
}

+ (BOOL)isRunningInSandbox
{
    return __isInSandbox;
}

+ (NSString*)defaultDocumentsPath
{
    return [ITApplication homeDocumentsPath];
}

+ (NSString*)sandboxeDocumentsPath
{
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
}

+ (NSString*)homeDocumentsPath
{
    return @"/private/var/mobile/Documents/iTransmission";
}

+ (NSString*)applicationPath
{
    return [[NSBundle mainBundle] resourcePath];
}

@end