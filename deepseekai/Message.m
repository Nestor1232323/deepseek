
#import "Message.h"

@implementation Message
+ (instancetype)messageWithDictionary:(NSDictionary *)dict {
    Message *msg = [[self alloc] init];
    
    id messageId = dict[@"message_id"];
    if ([messageId isKindOfClass:[NSNumber class]]) {
        msg.messageId = [messageId stringValue];
    } else if ([messageId isKindOfClass:[NSString class]]) {
        msg.messageId = messageId;
    } else {
        msg.messageId = @"0";
    }
    
    id parentId = dict[@"parent_id"];
    if ([parentId isKindOfClass:[NSNumber class]]) {
        msg.parentId = [parentId stringValue];
    } else if ([parentId isKindOfClass:[NSString class]]) {
        msg.parentId = parentId;
    } else {
        msg.parentId = @"";
    }
    
    msg.role = dict[@"role"] ?: @"USER";
    msg.insertedAt = [dict[@"inserted_at"] doubleValue];
    
    NSArray *fragments = dict[@"fragments"];
    if ([fragments isKindOfClass:[NSArray class]] && fragments.count > 0) {
        NSDictionary *lastFragment = [fragments lastObject];
        msg.content = lastFragment[@"content"] ?: @"";
    } else {
        msg.content = @"";
    }
    
    return msg;
}
+ (instancetype)messageWithText:(NSString *)text isOutgoing:(BOOL)isOutgoing {
    Message *msg = [[self alloc] init];
    msg.content = text;
    msg.role = isOutgoing ? @"USER" : @"ASSISTANT";
    msg.messageId = @"";
    msg.parentId = @"";
    msg.insertedAt = [[NSDate date] timeIntervalSince1970];
    return msg;
}

- (BOOL)isOutgoing {
    return [self.role isEqualToString:@"USER"];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Message[%@]: %@ - %@", self.messageId, self.role,
            self.content.length > 30 ? [self.content substringToIndex:30] : self.content];
}

@end
