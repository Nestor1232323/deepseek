
#import <Foundation/Foundation.h>

@interface SettingsManager : NSObject

+ (instancetype)sharedManager;

- (NSString *)getServerIP;
- (void)saveServerIP:(NSString *)ip;
- (BOOL)hasServerIP;

@end
