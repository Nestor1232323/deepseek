#import "APIService.h"
#import "SettingsManager.h"
#import "ChatSession.h"
#import "Message.h"

@implementation APIService {
    NSString *_baseURL;
}

+ (instancetype)sharedService {
    static APIService *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)initializeWithIP:(NSString *)ip {
    ip = [ip stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    _baseURL = [NSString stringWithFormat:@"http://%@:45516", ip];
    NSLog(@"APIService: initializeWithIP - baseURL: %@", _baseURL);
}

- (NSString *)getBaseURL {
    NSLog(@"APIService: getBaseURL - returning: %@", _baseURL);
    return _baseURL;
}

- (void)checkServerStatus:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    NSLog(@"APIService: checkServerStatus - start");
    if (!_baseURL) {
        NSLog(@"APIService: checkServerStatus - ERROR: Сервер не настроен");
        NSError *error = [NSError errorWithDomain:@"APIService" code:1001 userInfo:@{NSLocalizedDescriptionKey: @"Сервер не настроен"}];
        if (failure) failure(error);
        return;
    }
    
    NSString *urlString = [NSString stringWithFormat:@"%@/api/v1/status", _baseURL];
    NSURL *url = [NSURL URLWithString:urlString];
    NSLog(@"APIService: checkServerStatus - URL: %@", urlString);
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setTimeoutInterval:5.0];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               if (error) {
                                   NSLog(@"APIService: checkServerStatus - Network error: %@", error.localizedDescription);
                                   if (failure) failure(error);
                                   return;
                               }
                               NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                               NSLog(@"APIService: checkServerStatus - Status code: %ld", (long)httpResponse.statusCode);
                               if (httpResponse.statusCode != 200) {
                                   NSError *statusError = [NSError errorWithDomain:@"APIService" code:httpResponse.statusCode userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Сервер вернул статус: %ld", (long)httpResponse.statusCode]}];
                                   NSLog(@"APIService: checkServerStatus - Status error: %ld", (long)httpResponse.statusCode);
                                   if (failure) failure(statusError);
                                   return;
                               }
                               NSError *parseError = nil;
                               id jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
                               if (parseError) {
                                   NSLog(@"APIService: checkServerStatus - Parse error: %@", parseError.localizedDescription);
                                   if (failure) failure(parseError);
                                   return;
                               }
                               NSLog(@"APIService: checkServerStatus - Success");
                               if (success) success(jsonResponse);
                           }];
}

- (void)fetchChatSessions:(APISuccessBlock)success failure:(APIFailureBlock)failure {
    NSLog(@"APIService: fetchChatSessions - start");
    if (!_baseURL) {
        NSLog(@"APIService: fetchChatSessions - ERROR: Сервер не настроен");
        NSError *error = [NSError errorWithDomain:@"APIService" code:1001 userInfo:@{NSLocalizedDescriptionKey: @"Сервер не настроен"}];
        if (failure) failure(error);
        return;
    }
    
    NSString *urlString = [NSString stringWithFormat:@"%@/api/v1/chats", _baseURL];
    NSURL *url = [NSURL URLWithString:urlString];
    NSLog(@"APIService: fetchChatSessions - URL: %@", urlString);
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setTimeoutInterval:10.0];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               if (error) {
                                   NSLog(@"APIService: fetchChatSessions - Network error: %@", error.localizedDescription);
                                   if (failure) failure(error);
                                   return;
                               }
                               NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                               NSLog(@"APIService: fetchChatSessions - Status code: %ld", (long)httpResponse.statusCode);
                               if (httpResponse.statusCode != 200) {
                                   NSError *statusError = [NSError errorWithDomain:@"APIService" code:httpResponse.statusCode userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Сервер вернул статус: %ld", (long)httpResponse.statusCode]}];
                                   NSLog(@"APIService: fetchChatSessions - Status error: %ld", (long)httpResponse.statusCode);
                                   if (failure) failure(statusError);
                                   return;
                               }
                               NSError *parseError = nil;
                               id jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
                               if (parseError) {
                                   NSLog(@"APIService: fetchChatSessions - Parse error: %@", parseError.localizedDescription);
                                   if (failure) failure(parseError);
                                   return;
                               }
                               
                               NSArray *chatSessions = nil;
                               if ([jsonResponse isKindOfClass:[NSDictionary class]]) {
                                   NSDictionary *responseDict = (NSDictionary *)jsonResponse;
                                   if ([responseDict[@"ok"] boolValue]) {
                                       NSDictionary *dataDict = responseDict[@"data"];
                                       NSArray *sessionsArray = dataDict[@"chat_sessions"];
                                       if ([sessionsArray isKindOfClass:[NSArray class]]) {
                                           NSMutableArray *sessions = [NSMutableArray array];
                                           for (NSDictionary *sessionDict in sessionsArray) {
                                               ChatSession *session = [ChatSession sessionWithDictionary:sessionDict];
                                               [sessions addObject:session];
                                           }
                                           chatSessions = [NSArray arrayWithArray:sessions];
                                           NSLog(@"APIService: fetchChatSessions - Parsed %lu sessions", (unsigned long)sessions.count);
                                       }
                                   }
                               }
                               NSLog(@"APIService: fetchChatSessions - Success");
                               if (success) success(chatSessions);
                           }];
}

- (void)fetchChatHistory:(NSString *)chatId
                 success:(APISuccessBlock)success
                 failure:(APIFailureBlock)failure {
    NSLog(@"APIService: fetchChatHistory - start, chatId: %@", chatId);
    if (!_baseURL) {
        NSLog(@"APIService: fetchChatHistory - ERROR: Сервер не настроен");
        NSError *error = [NSError errorWithDomain:@"APIService" code:1001 userInfo:@{NSLocalizedDescriptionKey: @"Сервер не настроен"}];
        if (failure) failure(error);
        return;
    }
    
    if (!chatId || chatId.length == 0) {
        NSLog(@"APIService: fetchChatHistory - ERROR: chatId пустой");
        NSError *error = [NSError errorWithDomain:@"APIService" code:1002 userInfo:@{NSLocalizedDescriptionKey: @"chatId не может быть пустым"}];
        if (failure) failure(error);
        return;
    }
    
    NSString *urlString = [NSString stringWithFormat:@"%@/api/v1/chats/history", _baseURL];
    NSURL *url = [NSURL URLWithString:urlString];
    NSLog(@"APIService: fetchChatHistory - URL: %@", urlString);
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setTimeoutInterval:15.0];
    
    NSDictionary *body = @{@"chatId": chatId};
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:body options:0 error:nil];
    [request setHTTPBody:jsonData];
    NSLog(@"APIService: fetchChatHistory - Body: %@", body);
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               if (error) {
                                   NSLog(@"APIService: fetchChatHistory - Network error: %@", error.localizedDescription);
                                   if (failure) failure(error);
                                   return;
                               }
                               NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                               NSLog(@"APIService: fetchChatHistory - Status code: %ld", (long)httpResponse.statusCode);
                               if (httpResponse.statusCode != 200) {
                                   NSError *statusError = [NSError errorWithDomain:@"APIService" code:httpResponse.statusCode userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Сервер вернул статус: %ld", (long)httpResponse.statusCode]}];
                                   NSLog(@"APIService: fetchChatHistory - Status error: %ld", (long)httpResponse.statusCode);
                                   if (failure) failure(statusError);
                                   return;
                               }
                               NSError *parseError = nil;
                               id jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
                               if (parseError) {
                                   NSLog(@"APIService: fetchChatHistory - Parse error: %@", parseError.localizedDescription);
                                   if (failure) failure(parseError);
                                   return;
                               }
                               
                               NSArray *messages = nil;
                               if ([jsonResponse isKindOfClass:[NSDictionary class]]) {
                                   NSDictionary *responseDict = (NSDictionary *)jsonResponse;
                                   if ([responseDict[@"ok"] boolValue]) {
                                       NSDictionary *dataDict = responseDict[@"data"];
                                       messages = dataDict[@"chat_messages"];
                                       NSLog(@"APIService: fetchChatHistory - Parsed %lu messages", (unsigned long)messages.count);
                                   }
                               }
                               NSLog(@"APIService: fetchChatHistory - Success");
                               if (success) success(messages);
                           }];
}

- (void)continueChat:(NSString *)chatId
     parentMessageId:(NSInteger)parentMessageId
             message:(NSString *)message
            thinking:(BOOL)thinking
              search:(BOOL)search
             success:(APISuccessBlock)success
             failure:(APIFailureBlock)failure {
    NSLog(@"APIService: continueChat - start, chatId: %@, parentMessageId: %ld, thinking: %d, search: %d", chatId, (long)parentMessageId, thinking, search);
    if (!_baseURL) {
        NSLog(@"APIService: continueChat - ERROR: Сервер не настроен");
        NSError *error = [NSError errorWithDomain:@"APIService" code:1001 userInfo:@{NSLocalizedDescriptionKey: @"Сервер не настроен"}];
        if (failure) failure(error);
        return;
    }
    
    if (!chatId || chatId.length == 0) {
        NSLog(@"APIService: continueChat - ERROR: chatId пустой");
        NSError *error = [NSError errorWithDomain:@"APIService" code:1002 userInfo:@{NSLocalizedDescriptionKey: @"chatId не может быть пустым"}];
        if (failure) failure(error);
        return;
    }
    
    if (parentMessageId <= 0) {
        NSLog(@"APIService: continueChat - ERROR: parentMessageId <= 0");
        NSError *error = [NSError errorWithDomain:@"APIService" code:1003 userInfo:@{NSLocalizedDescriptionKey: @"parentMessageId должен быть больше 0"}];
        if (failure) failure(error);
        return;
    }
    
    NSString *urlString = [NSString stringWithFormat:@"%@/api/v1/chats/continue", _baseURL];
    NSURL *url = [NSURL URLWithString:urlString];
    NSLog(@"APIService: continueChat - URL: %@", urlString);
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setTimeoutInterval:30.0];
    
    NSDictionary *body = @{
                           @"chatId": chatId,
                           @"parentMessageId": @(parentMessageId),
                           @"message": message,
                           @"thinking": @(thinking),
                           @"search": @(search)
                           };
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:body options:0 error:nil];
    [request setHTTPBody:jsonData];
    NSLog(@"APIService: continueChat - Body: %@", body);
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               if (error) {
                                   NSLog(@"APIService: continueChat - Network error: %@", error.localizedDescription);
                                   if (failure) failure(error);
                                   return;
                               }
                               NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                               NSLog(@"APIService: continueChat - Status code: %ld", (long)httpResponse.statusCode);
                               if (httpResponse.statusCode != 200) {
                                   NSError *statusError = [NSError errorWithDomain:@"APIService" code:httpResponse.statusCode userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Сервер вернул статус: %ld", (long)httpResponse.statusCode]}];
                                   NSLog(@"APIService: continueChat - Status error: %ld", (long)httpResponse.statusCode);
                                   if (failure) failure(statusError);
                                   return;
                               }
                               NSError *parseError = nil;
                               id jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
                               if (parseError) {
                                   NSLog(@"APIService: continueChat - Parse error: %@", parseError.localizedDescription);
                                   if (failure) failure(parseError);
                                   return;
                               }
                               NSLog(@"APIService: continueChat - Success");
                               NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                               NSLog(@"APIService: continueChat - Raw: %@", responseString);
                               if (success) success(jsonResponse);
                           }];
}

- (void)createNewChatWithMessage:(NSString *)message
                       modelType:(NSString *)modelType
                        thinking:(BOOL)thinking
                          search:(BOOL)search
                         success:(APISuccessBlock)success
                         failure:(APIFailureBlock)failure {
    NSLog(@"APIService: createNewChat - start, thinking: %d, search: %d, modelType: %@", thinking, search, modelType);
    if (!_baseURL) {
        NSLog(@"APIService: createNewChat - ERROR: Сервер не настроен");
        NSError *error = [NSError errorWithDomain:@"APIService" code:1001 userInfo:@{NSLocalizedDescriptionKey: @"Сервер не настроен"}];
        if (failure) failure(error);
        return;
    }
    
    if (!message || message.length == 0) {
        NSLog(@"APIService: createNewChat - ERROR: сообщение пустое");
        NSError *error = [NSError errorWithDomain:@"APIService" code:1002 userInfo:@{NSLocalizedDescriptionKey: @"Сообщение не может быть пустым"}];
        if (failure) failure(error);
        return;
    }
    
    NSString *urlString = [NSString stringWithFormat:@"%@/api/v1/chats/completion", _baseURL];
    NSURL *url = [NSURL URLWithString:urlString];
    NSLog(@"APIService: createNewChat - URL: %@", urlString);
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setTimeoutInterval:30.0];
    NSDictionary *body = @{
                           @"message": message,
                           @"model": modelType ?: @"default",
                           @"thinking": @(thinking),
                           @"search": @(search)
                           };
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:body options:0 error:nil];
    [request setHTTPBody:jsonData];
    NSLog(@"APIService: createNewChat - Body: %@", body);
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               if (error) {
                                   NSLog(@"APIService: createNewChat - Network error: %@", error.localizedDescription);
                                   if (failure) failure(error);
                                   return;
                               }
                               NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                               NSLog(@"APIService: createNewChat - Status code: %ld", (long)httpResponse.statusCode);
                               if (httpResponse.statusCode != 200) {
                                   NSError *statusError = [NSError errorWithDomain:@"APIService" code:httpResponse.statusCode userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Сервер вернул статус: %ld", (long)httpResponse.statusCode]}];
                                   NSLog(@"APIService: createNewChat - Status error: %ld", (long)httpResponse.statusCode);
                                   if (failure) failure(statusError);
                                   return;
                               }
                               NSError *parseError = nil;
                               id jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
                               if (parseError) {
                                   NSLog(@"APIService: createNewChat - Parse error: %@", parseError.localizedDescription);
                                   if (failure) failure(parseError);
                                   return;
                               }
                               NSLog(@"APIService: createNewChat - Success");
                               if (success) success(jsonResponse);
                           }];
}

- (void)deleteChat:(NSString *)chatId
           success:(APISuccessBlock)success
           failure:(APIFailureBlock)failure {
    NSLog(@"APIService: deleteChat - start, chatId: %@", chatId);
    if (!_baseURL) {
        NSLog(@"APIService: deleteChat - ERROR: Сервер не настроен");
        NSError *error =
        [NSError errorWithDomain:@"APIService"
                            code:1001
                        userInfo:@{
       NSLocalizedDescriptionKey:@"Сервер не настроен"
         }];
        
        if (failure) failure(error);
        return;
    }
    
    if (!chatId || chatId.length == 0) {
        NSLog(@"APIService: deleteChat - ERROR: chatId пустой");
        NSError *error =
        [NSError errorWithDomain:@"APIService"
                            code:1002
                        userInfo:@{
       NSLocalizedDescriptionKey:@"chatId пустой"
         }];
        
        if (failure) failure(error);
        return;
    }
    
    NSString *urlString =
    [NSString stringWithFormat:@"%@/api/v1/chats/%@", _baseURL, chatId];
    NSLog(@"APIService: deleteChat - URL: %@", urlString);
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSMutableURLRequest *request =
    [NSMutableURLRequest requestWithURL:url];
    
    request.HTTPMethod = @"DELETE";
    [request setValue:@"application/json"
   forHTTPHeaderField:@"Accept"];
    
    request.timeoutInterval = 15.0;
    
    [NSURLConnection
     sendAsynchronousRequest:request
     queue:[NSOperationQueue mainQueue]
     completionHandler:^(NSURLResponse *response,
                         NSData *data,
                         NSError *error) {
         if (error) {
             NSLog(@"APIService: deleteChat - Network error: %@", error.localizedDescription);
             if (failure) failure(error);
             return;
         }
         
         NSHTTPURLResponse *httpResponse =
         (NSHTTPURLResponse *)response;
         NSLog(@"APIService: deleteChat - Status code: %ld", (long)httpResponse.statusCode);
         
         if (httpResponse.statusCode != 200 &&
             httpResponse.statusCode != 204) {
             NSError *statusError =
             [NSError errorWithDomain:@"APIService"
                                 code:httpResponse.statusCode
                             userInfo:@{
            NSLocalizedDescriptionKey:
              [NSString stringWithFormat:
               @"Ошибка удаления: %ld",
               (long)httpResponse.statusCode]
              }];
             NSLog(@"APIService: deleteChat - Status error: %ld", (long)httpResponse.statusCode);
             if (failure) failure(statusError);
             return;
         }
         
         NSLog(@"APIService: deleteChat - Success");
         if (success) {
             success(@{
                     @"ok": @YES
                     });
         }
     }];
}

- (void)fetchMe:(APISuccessBlock)success
        failure:(APIFailureBlock)failure {
    NSLog(@"APIService: fetchMe - start");
    if (!_baseURL) {
        NSLog(@"APIService: fetchMe - ERROR: Сервер не настроен");
        NSError *error =
        [NSError errorWithDomain:@"APIService"
                            code:1001
                        userInfo:@{
       NSLocalizedDescriptionKey:@"Сервер не настроен"
         }];
        
        if (failure)
            failure(error);
        
        return;
    }
    
    NSString *urlString =
    [NSString stringWithFormat:@"%@/api/v1/me", _baseURL];
    NSLog(@"APIService: fetchMe - URL: %@", urlString);
    
    NSURL *url =
    [NSURL URLWithString:urlString];
    
    NSMutableURLRequest *request =
    [NSMutableURLRequest requestWithURL:url];
    
    request.HTTPMethod = @"GET";
    
    [request setValue:@"application/json"
   forHTTPHeaderField:@"Accept"];
    
    request.timeoutInterval = 10.0;
    
    [NSURLConnection
     sendAsynchronousRequest:request
     queue:[NSOperationQueue mainQueue]
     completionHandler:^(NSURLResponse *response,
                         NSData *data,
                         NSError *error) {
         if (error) {
             NSLog(@"APIService: fetchMe - Network error: %@", error.localizedDescription);
             if (failure)
                 failure(error);
             return;
         }
         
         NSHTTPURLResponse *httpResponse =
         (NSHTTPURLResponse *)response;
         NSLog(@"APIService: fetchMe - Status code: %ld", (long)httpResponse.statusCode);
         
         if (httpResponse.statusCode != 200) {
             NSError *statusError =
             [NSError errorWithDomain:@"APIService"
                                 code:httpResponse.statusCode
                             userInfo:@{
            NSLocalizedDescriptionKey:
              [NSString stringWithFormat:
               @"Ошибка сервера %ld",
               (long)httpResponse.statusCode]
              }];
             NSLog(@"APIService: fetchMe - Status error: %ld", (long)httpResponse.statusCode);
             if (failure)
                 failure(statusError);
             return;
         }
         
         NSError *parseError = nil;
         id json =
         [NSJSONSerialization JSONObjectWithData:data
                                         options:0
                                           error:&parseError];
         
         if (parseError) {
             NSLog(@"APIService: fetchMe - Parse error: %@", parseError.localizedDescription);
             if (failure)
                 failure(parseError);
             return;
         }
         
         NSDictionary *user = nil;
         
         if ([json isKindOfClass:[NSDictionary class]]) {
             NSDictionary *dataDict =
             json[@"data"];
             NSDictionary *bizData =
             dataDict[@"biz_data"];
             if ([bizData isKindOfClass:[NSDictionary class]]) {
                 user = bizData;
                 NSLog(@"APIService: fetchMe - Parsed user data");
             }
         }
         
         NSLog(@"APIService: fetchMe - Success");
         if (success)
             success(user);
     }];
}
@end