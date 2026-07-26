
#import <UIKit/UIKit.h>

@class ChatSession;

@protocol DetailViewProtocol <NSObject>
@optional
- (void)updateNavigationTitle:(NSString *)title;
- (void)reloadChatTable;
- (void)scrollToBottomAnimated:(BOOL)animated;
- (void)showLoading:(BOOL)show;
- (void)showModelSelection;
- (void)dismissModelSelection;
@end

@interface DetailPresenter : NSObject <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) id<DetailViewProtocol> view;
@property (nonatomic, strong) id detailItem;
@property (nonatomic, strong) NSString *selectedModel;
@property (nonatomic, readonly) NSInteger messagesCount;
- (instancetype)initWithView:(id<DetailViewProtocol>)view;
- (void)viewReadyToConfigure;
- (void)sendMessageFromUser:(NSString *)text;
- (void)setModel:(NSString *)modelType;
- (void)chatWasCreated:(ChatSession *)session;
- (BOOL)isNewChat;
- (void)setModesWithDeepThink:(BOOL)deepThink
                       search:(BOOL)search;

- (void)resetForNewChat;
@end
