
#import <Foundation/Foundation.h>

typedef void (^APISuccessBlock)(id response);
typedef void (^APIFailureBlock)(NSError *error);

@interface APIService : NSObject

+ (instancetype)sharedService;

- (void)initializeWithIP:(NSString *)ip;
- (NSString *)getBaseURL;

- (void)checkServerStatus:(APISuccessBlock)success failure:(APIFailureBlock)failure;

- (void)fetchChatSessions:(APISuccessBlock)success failure:(APIFailureBlock)failure;

- (void)fetchChatHistory:(NSString *)chatId
                 success:(APISuccessBlock)success
                 failure:(APIFailureBlock)failure;
- (void)deleteChat:(NSString *)chatId
           success:(APISuccessBlock)success
           failure:(APIFailureBlock)failure;
- (void)continueChat:(NSString *)chatId
     parentMessageId:(NSInteger)parentMessageId
             message:(NSString *)message
            thinking:(BOOL)thinking
              search:(BOOL)search
             success:(APISuccessBlock)success
             failure:(APIFailureBlock)failure;
- (void)fetchMe:(APISuccessBlock)success
        failure:(APIFailureBlock)failure;
- (void)createNewChatWithMessage:(NSString *)message
                       modelType:(NSString *)modelType
                        thinking:(BOOL)thinking
                          search:(BOOL)search
                         success:(APISuccessBlock)success
                         failure:(APIFailureBlock)failure;
@end
