
#import <Foundation/Foundation.h>

@class ChatSession;

@interface DataManager : NSObject

@property (nonatomic, strong, readonly) NSArray *chatSessions;

+ (instancetype)sharedManager;

- (void)setChatSessions:(NSArray *)sessions;
- (void)addChatSession:(ChatSession *)session;
- (void)removeChatSessionAtIndex:(NSInteger)index;
- (void)clearAll;

- (void)addNewObject:(id)object __attribute__((deprecated("Use addChatSession: instead")));

@end
