
#import "DetailPresenter.h"
#import "BubbleCell.h"
#import "ChatSession.h"
#import "Message.h"
#import "APIService.h"
#import "DetailViewController.h"  

@interface DetailPresenter () {
    NSMutableArray *_messages;
    NSString *_currentChatId;
    NSInteger _lastMessageId;
    BOOL _isLoading;
    BOOL _isNewChat;
    NSString *_selectedModel;
    
    BOOL _deepThinkEnabled;
    BOOL _searchEnabled;
}
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
@end

@implementation DetailPresenter

- (instancetype)initWithView:(id<DetailViewProtocol>)view {
    self = [super init];
    if (self) {
        _view = view;
        _messages = [[NSMutableArray alloc] init];
        _isLoading = NO;
        _isNewChat = YES;
        _lastMessageId = 0;
        _currentChatId = nil;
    }
    return self;
}

- (void)setDetailItem:(id)detailItem {
    
    if (_detailItem != detailItem) {
        
        _detailItem = detailItem;
        
        _lastMessageId = 0;
        _currentChatId = nil;
        _isNewChat = YES;
        
        
        if ([detailItem isKindOfClass:[ChatSession class]]) {
            
            ChatSession *session = (ChatSession *)detailItem;
            
            
            if (session.sessionId &&
                session.sessionId.length > 0) {
                
                
                _currentChatId = session.sessionId;
                _isNewChat = NO;
                
                [self loadChatHistory];
                
            }
            else {
                
                
                [_messages removeAllObjects];
                
                [self.view updateNavigationTitle:@"Новый чат"];
                [self.view reloadChatTable];
                
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([self.view respondsToSelector:@selector(showModelSelection)]) {
                        [self.view showModelSelection];
                    }
                });
            }
        }
    }
    
    
    if (self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }
}

- (void)viewReadyToConfigure {
    if (_currentChatId && _currentChatId.length > 0) {
        [self loadChatHistory];
    } else {
        [_messages removeAllObjects];
        [self.view updateNavigationTitle:@"Новый чат"];
        [self.view reloadChatTable];
        
    }
}
- (NSInteger)messagesCount {
    return _messages.count;
}
- (void)setModesWithDeepThink:(BOOL)deepThink
                       search:(BOOL)search {
    
    _deepThinkEnabled = deepThink;
    
    if ([_selectedModel isEqualToString:@"expert"]) {
        _searchEnabled = NO;
    } else {
        _searchEnabled = search;
    }
    
          _deepThinkEnabled ? @"YES" : @"NO",
          _searchEnabled ? @"YES" : @"NO";
}
#pragma mark - Load History

- (void)loadChatHistory {
    [_messages removeAllObjects];
    
    if (_currentChatId && _currentChatId.length > 0) {
        [self.view updateNavigationTitle:@"Загрузка..."];
        _isLoading = YES;
        
        [[APIService sharedService] fetchChatHistory:_currentChatId
                                             success:^(id response) {
                                                 self->_isLoading = NO;
                                                 NSArray *messagesData = (NSArray *)response;
                                                 [self parseMessages:messagesData];
                                                 
                                                 ChatSession *s = (ChatSession *)self.detailItem;
                                                 [self.view updateNavigationTitle:s.title ?: @"Чат"];
                                                 [self.view reloadChatTable];
                                                 [self.view scrollToBottomAnimated:NO];
                                             } failure:^(NSError *error) {
                                                 self->_isLoading = NO;
                                                 ChatSession *s = (ChatSession *)self.detailItem;
                                                 [self.view updateNavigationTitle:s.title ?: @"Чат"];
                                                 [self.view reloadChatTable];
                                             }];
    }
}

- (void)parseMessages:(NSArray *)messagesData {
    [_messages removeAllObjects];
    _lastMessageId = 0;
    
    if ([messagesData isKindOfClass:[NSArray class]]) {
        for (NSDictionary *dict in messagesData) {
            Message *msg = [Message messageWithDictionary:dict];
            if (msg.content && msg.content.length > 0) {
                [_messages addObject:msg];
                NSInteger msgId = [msg.messageId integerValue];
                if (msgId > _lastMessageId) {
                    _lastMessageId = msgId;
                }
            }
        }
    }
    
    [_messages sortUsingComparator:^NSComparisonResult(Message *obj1, Message *obj2) {
        NSInteger id1 = [obj1.messageId integerValue];
        NSInteger id2 = [obj2.messageId integerValue];
        if (id1 < id2) return NSOrderedAscending;
        if (id1 > id2) return NSOrderedDescending;
        return NSOrderedSame;
    }];
    
}

#pragma mark - Send Message

- (void)sendMessageFromUser:(NSString *)text {
    if (text.length == 0 || _isLoading) return;
    
    Message *userMsg = [Message messageWithText:text isOutgoing:YES];
    if (_isNewChat || !_currentChatId) {
        userMsg.messageId = @"-1";
    }
    [_messages addObject:userMsg];
    
    [self.view reloadChatTable];
    [self.view scrollToBottomAnimated:YES];
    
    _isLoading = YES;
    [self.view showLoading:YES];
    
    if (_isNewChat || !_currentChatId || _currentChatId.length == 0) {
        [self createNewChat:text];
    } else {
        [self continueChat:text];
    }
}

#pragma mark - API Calls

- (void)continueChat:(NSString *)text {
    
    [[APIService sharedService] continueChat:_currentChatId
                             parentMessageId:_lastMessageId
                                     message:text
                                    thinking:_deepThinkEnabled
                                      search:_searchEnabled
                                     success:^(id response) {
                                         
                                         self->_isLoading = NO;
                                         [self.view showLoading:NO];
                                         [self handleContinueResponse:response];
                                         
                                     } failure:^(NSError *error) {
                                         
                                         self->_isLoading = NO;
                                         [self.view showLoading:NO];
                                         
                                     }];
}

- (void)createNewChat:(NSString *)text {
    [[APIService sharedService] createNewChatWithMessage:text
                                               modelType:_selectedModel
                                                thinking:_deepThinkEnabled
                                                  search:_searchEnabled
                                                 success:^(id response) {
                                                     self->_isLoading = NO;
                                                     [self.view showLoading:NO];
                                                     [self handleCreateResponse:response];
                                                 } failure:^(NSError *error) {
                                                     self->_isLoading = NO;
                                                     [self.view showLoading:NO];
                                                     [self showError:@"Не удалось создать чат"];
                                                 }];
}
- (BOOL)isNewChat {
    return _isNewChat;
}
- (void)setModel:(NSString *)modelType {
    
    if ([modelType isEqualToString:@"expert"] ||
        [modelType isEqualToString:@"default"]) {
        
        _selectedModel = modelType;
        
        
        if ([_selectedModel isEqualToString:@"expert"]) {
            _searchEnabled = NO;
        }
        
        
        
        
        if ([self.detailItem isKindOfClass:[ChatSession class]]) {
            ((ChatSession *)self.detailItem).modelType = modelType;
        }
    }
}
- (void)resetForNewChat {
    [_messages removeAllObjects];
    _currentChatId = nil;
    _lastMessageId = 0;
    _isNewChat = YES;
    _isLoading = NO;
    
    [self.view updateNavigationTitle:@"Новый чат"];
    [self.view reloadChatTable];
    
    if ([self.view respondsToSelector:@selector(showModelSelection)]) {
        [self.view showModelSelection];
    }
}
#pragma mark - Response Handlers

- (void)handleContinueResponse:(id)response {
    if ([response isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dict = (NSDictionary *)response;
        if ([dict[@"ok"] boolValue]) {
            NSString *content = dict[@"content"];
            NSInteger parentMessageId = [dict[@"parentMessageId"] integerValue];
            NSString *title = dict[@"title"];
            
            _lastMessageId = parentMessageId;
            _isNewChat = NO;
            
            if (title && ![title isKindOfClass:[NSNull class]] && title.length > 0) {
                [self.view updateNavigationTitle:title];
                if ([self.detailItem isKindOfClass:[ChatSession class]]) {
                    ((ChatSession *)self.detailItem).title = title;
                }
                
                if (_currentChatId) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"ChatTitleUpdated"
                                                                        object:@{@"chatId": _currentChatId,
                     @"title": title}];
                }
            }
            
            Message *assistantMsg = [Message messageWithText:content isOutgoing:NO];
            assistantMsg.messageId = [NSString stringWithFormat:@"%ld", (long)_lastMessageId];
            [_messages addObject:assistantMsg];
            
            [self.view reloadChatTable];
            [self.view scrollToBottomAnimated:YES];
            
        } else {
            [self showError:@"Ошибка получения ответа"];
        }
    }
}
- (void)handleCreateResponse:(id)response {
    if ([response isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dict = (NSDictionary *)response;
        if ([dict[@"ok"] boolValue]) {
            NSString *chatId = dict[@"chatId"];
            NSString *content = dict[@"content"];
            NSString *title = dict[@"title"];
            NSInteger parentMessageId = [dict[@"parentMessageId"] integerValue];
            
            _currentChatId = chatId;
            _lastMessageId = parentMessageId;
            _isNewChat = NO;
            
            if (title && ![title isKindOfClass:[NSNull class]] && title.length > 0) {
                [self.view updateNavigationTitle:title];
            }
            
            if ([self.detailItem isKindOfClass:[ChatSession class]]) {
                ChatSession *session = (ChatSession *)self.detailItem;
                session.sessionId = chatId;
                if (title && ![title isKindOfClass:[NSNull class]] && title.length > 0) {
                    session.title = title;
                }
                session.updatedAt = [[NSDate date] timeIntervalSince1970];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ChatCreated"
                                                                    object:session];
            }
            
            Message *assistantMsg = [Message messageWithText:content isOutgoing:NO];
            assistantMsg.messageId = [NSString stringWithFormat:@"%ld", (long)_lastMessageId];
            [_messages addObject:assistantMsg];
            
            [self.view reloadChatTable];
            [self.view scrollToBottomAnimated:YES];
            
        } else {
            [self showError:@"Ошибка создания чата"];
        }
    }
}

- (void)showError:(NSString *)message {
    Message *errorMsg = [Message messageWithText:message isOutgoing:NO];
    [_messages addObject:errorMsg];
    [self.view reloadChatTable];
    [self.view scrollToBottomAnimated:YES];
}

#pragma mark - Table View Data Source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _messages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"BubbleCell";
    BubbleCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[BubbleCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    Message *msg = _messages[indexPath.row];
    BOOL isOutgoing = [msg.role isEqualToString:@"USER"];
    [cell configureWithText:msg.content isOutgoing:isOutgoing];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    Message *msg = _messages[indexPath.row];
    CGFloat tableWidth = tableView.bounds.size.width;
    BOOL isOutgoing = [msg.role isEqualToString:@"USER"];
    return [BubbleCell heightForText:msg.content width:tableWidth isOutgoing:isOutgoing];
}

#pragma mark - Split View Delegate

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController {
    barButtonItem.title = NSLocalizedString(@"Чаты", @"Чаты");
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem {
    self.masterPopoverController = nil;
}

@end
