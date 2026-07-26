
#import "DataManager.h"
#import "ChatSession.h"

@interface DataManager () {
    NSMutableArray *_chatSessions;
}
@end

@implementation DataManager

+ (instancetype)sharedManager {
    static DataManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _chatSessions = [[NSMutableArray alloc] init];
    }
    return self;
}

- (NSArray *)chatSessions {
    return [_chatSessions copy];
}

- (void)setChatSessions:(NSArray *)sessions {
    [_chatSessions removeAllObjects];
    if (sessions) {
        [_chatSessions addObjectsFromArray:sessions];
    }
}

- (void)addChatSession:(ChatSession *)session {
    if (session) {
        [_chatSessions addObject:session];
    }
}

- (void)removeChatSessionAtIndex:(NSInteger)index {
    if (index >= 0 && index < _chatSessions.count) {
        [_chatSessions removeObjectAtIndex:index];
    }
}

- (void)clearAll {
    [_chatSessions removeAllObjects];
}

- (void)addNewObject:(id)object {
    if ([object isKindOfClass:[ChatSession class]]) {
        [self addChatSession:(ChatSession *)object];
        return;
    }
    
    if ([object isKindOfClass:[NSDate class]]) {
        NSDate *date = (NSDate *)object;
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateStyle:NSDateFormatterShortStyle];
        [formatter setTimeStyle:NSDateFormatterShortStyle];
        NSString *title = [NSString stringWithFormat:@"Чат от %@", [formatter stringFromDate:date]];
        
        ChatSession *tempSession = [[ChatSession alloc] init];
        tempSession.sessionId = [[NSUUID UUID] UUIDString];
        tempSession.title = title;
        tempSession.updatedAt = [date timeIntervalSince1970];
        tempSession.insertedAt = [date timeIntervalSince1970];
        
        [self addChatSession:tempSession];
        return;
    }
    
}

@end
