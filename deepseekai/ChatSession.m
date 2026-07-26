
#import "ChatSession.h"

@implementation ChatSession

- (instancetype)init {
    self = [super init];
    if (self) {
        _sessionId = @"";
        _title = @"Новый чат";
        _titleType = @"SYSTEM";
        _modelType = @"default";
        _agent = @"chat";
        _currentMessageId = @"";
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _sessionId = dict[@"id"] ?: @"";
        _seqId = [dict[@"seq_id"] integerValue];
        _title = dict[@"title"] ?: @"Новый чат";
        _titleType = dict[@"title_type"] ?: @"SYSTEM";
        _updatedAt = [dict[@"updated_at"] doubleValue];
        _pinned = [dict[@"pinned"] boolValue];
        _modelType = dict[@"model_type"] ?: @"default";
        _agent = dict[@"agent"] ?: @"chat";
        _version = [dict[@"version"] integerValue];
        _currentMessageId = dict[@"current_message_id"] ?: @"";
        _insertedAt = [dict[@"inserted_at"] doubleValue];
    }
    return self;
}
+ (instancetype)newChat {
    ChatSession *session = [[ChatSession alloc] init];
    session.sessionId = nil;
    session.title = @"Новый чат";
    session.updatedAt = [[NSDate date] timeIntervalSince1970];
    session.insertedAt = [[NSDate date] timeIntervalSince1970];
    return session;
}
+ (instancetype)sessionWithDictionary:(NSDictionary *)dict {
    return [[self alloc] initWithDictionary:dict];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"ChatSession: %@ - %@", self.sessionId, self.title];
}

@end
