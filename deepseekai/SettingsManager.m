
#import "SettingsManager.h"

static NSString * const kServerIPKey = @"ServerIP";

@implementation SettingsManager

+ (instancetype)sharedManager {
    static SettingsManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (NSString *)getServerIP {
    return [[NSUserDefaults standardUserDefaults] stringForKey:kServerIPKey];
}

- (void)saveServerIP:(NSString *)ip {
    [[NSUserDefaults standardUserDefaults] setObject:ip forKey:kServerIPKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)hasServerIP {
    return [self getServerIP] != nil && [[self getServerIP] length] > 0;
}

@end
