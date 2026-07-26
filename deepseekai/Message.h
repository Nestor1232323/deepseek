
#import <Foundation/Foundation.h>

@interface Message : NSObject

@property (nonatomic, strong) NSString *messageId;  
@property (nonatomic, strong) NSString *parentId;
@property (nonatomic, strong) NSString *role;
@property (nonatomic, strong) NSString *content;
@property (nonatomic, assign) NSTimeInterval insertedAt;

+ (instancetype)messageWithDictionary:(NSDictionary *)dict;
+ (instancetype)messageWithText:(NSString *)text isOutgoing:(BOOL)isOutgoing;

- (BOOL)isOutgoing;

@end
