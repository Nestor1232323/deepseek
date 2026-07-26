
#import <Foundation/Foundation.h>

@interface ChatSession : NSObject

@property (nonatomic, strong) NSString *sessionId;
@property (nonatomic, assign) NSInteger seqId;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *titleType;
@property (nonatomic, assign) NSTimeInterval updatedAt;
@property (nonatomic, assign) BOOL pinned;
@property (nonatomic, strong) NSString *modelType;
@property (nonatomic, strong) NSString *agent;
@property (nonatomic, assign) NSInteger version;
@property (nonatomic, strong) NSString *currentMessageId;
@property (nonatomic, assign) NSTimeInterval insertedAt;
@property (nonatomic, assign) BOOL isTemporary;
- (instancetype)init;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
+ (instancetype)sessionWithDictionary:(NSDictionary *)dict;

@end
