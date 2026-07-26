
#import "DetailViewController.h"
#import "DetailPresenter.h"
#import "DetailViewProtocol.h"
#import "ChatSession.h"
#import "BubbleCell.h"
#import "ModesViewController.h"

@interface DetailViewController () <DetailViewProtocol, UITextFieldDelegate, UIPopoverControllerDelegate, UIActionSheetDelegate> {
    UIView *_modelSelectionView;
    UIView *_welcomeContainer;
    UISegmentedControl *_modelSegment;
    BOOL _modelShown;
    UILabel *_welcomeTitleLabel;
    UILabel *_welcomeSubtitleLabel;
    UIPopoverController *_modesPopover;
    
    BOOL _deepThinkEnabled;
    BOOL _searchEnabled;
    BOOL _isExpertMode;
}

@property (nonatomic, strong) DetailPresenter *presenter;

@end

@implementation DetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.presenter = [[DetailPresenter alloc] initWithView:self];
    _modelShown = NO;
    _deepThinkEnabled = NO;
    _searchEnabled = NO;
    _isExpertMode = NO;
    
    self.chatTableView.dataSource = self.presenter;
    self.chatTableView.delegate = self.presenter;
    self.chatTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.chatTableView.backgroundColor = [UIColor colorWithRed:0.92 green:0.94 blue:0.97 alpha:1.0];
    [self.chatTableView registerClass:[BubbleCell class] forCellReuseIdentifier:@"BubbleCell"];
    
    self.messageTextField.delegate = self;
    self.messageTextField.placeholder = @"Сообщение...";
    
    self.sendButton.target = self;
    self.sendButton.action = @selector(sendMessageTapped);
    
    self.modesButton.target = self;
    self.modesButton.action = @selector(modesTapped:);
    
    if (!self.detailItem) {
        self.detailItem = [self createEmptyChatSession];
    }
    
    self.presenter.detailItem = self.detailItem;
    [self.presenter viewReadyToConfigure];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)modesTapped:(UIBarButtonItem *)sender {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        if (_modesPopover) {
            [_modesPopover dismissPopoverAnimated:YES];
            _modesPopover = nil;
            return;
        }
        
        ModesViewController *vc = [[ModesViewController alloc] initWithStyle:UITableViewStylePlain];
        vc.deepThinkEnabled = _deepThinkEnabled;
        vc.searchEnabled = _searchEnabled;
        vc.allowSearch = !_isExpertMode;
        
        __weak typeof(self) weakSelf = self;
        vc.onChange = ^(BOOL deepThink, BOOL search) {
            [weakSelf.presenter setModesWithDeepThink:deepThink search:search];
        };
        
        _modesPopover = [[UIPopoverController alloc] initWithContentViewController:vc];
        _modesPopover.delegate = self;
        [_modesPopover presentPopoverFromBarButtonItem:sender
                              permittedArrowDirections:UIPopoverArrowDirectionUp
                                              animated:YES];
    } else {
        NSString *deep = _deepThinkEnabled ? @"✓ DeepThink" : @"DeepThink";
        NSString *search;
        if (_isExpertMode) {
            search = @"Search (недоступно)";
        } else {
            search = _searchEnabled ? @"✓ Search" : @"Search";
        }
        
        UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Modes"
                                                           delegate:self
                                                  cancelButtonTitle:@"Отмена"
                                             destructiveButtonTitle:nil
                                                  otherButtonTitles:deep, search, nil];
        [sheet showFromBarButtonItem:sender animated:YES];
    }
}

- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary *info = notification.userInfo;
    CGRect keyboardFrame = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardFrame = [self.view convertRect:keyboardFrame fromView:nil];
    CGFloat keyboardHeight = keyboardFrame.size.height;
    
    CGRect frame = self.inputToolbar.frame;
    frame.origin.y = self.view.bounds.size.height - keyboardHeight - frame.size.height;
    
    [UIView animateWithDuration:0.25 animations:^{
        self.inputToolbar.frame = frame;
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    CGRect frame = self.inputToolbar.frame;
    frame.origin.y = self.view.bounds.size.height - frame.size.height;
    
    [UIView animateWithDuration:0.25 animations:^{
        self.inputToolbar.frame = frame;
    }];
}

- (void)setDetailItem:(id)newDetailItem {
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        
        [self dismissModelSelection];
        _modelShown = NO;
        
        if ([newDetailItem isKindOfClass:[ChatSession class]]) {
            ChatSession *session = (ChatSession *)newDetailItem;
            self.title = session.title ?: @"Чат";
        }
        
        if (self.presenter) {
            self.presenter.detailItem = newDetailItem;
        }
    }
}

#pragma mark - Actions

- (void)sendMessageTapped {
    NSString *text = [self.messageTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (text.length == 0) return;
    
    _welcomeContainer.hidden = YES;
    _welcomeTitleLabel.hidden = YES;
    _welcomeSubtitleLabel.hidden = YES;
    _modelSegment.hidden = YES;
    _modelShown = NO;
    
    [self.messageTextField resignFirstResponder];
    [self.presenter sendMessageFromUser:text];
    self.messageTextField.text = @"";
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self sendMessageTapped];
    return YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self bringToolbarToFront];
    
    if ([self.presenter isNewChat] && !_modelShown && self.presenter.messagesCount == 0) {
        [self showModelSelection];
    }
}

#pragma mark - Model Selection

- (void)showModelSelection {
    if (_modelShown || _modelSelectionView) {
        return;
    }
    
    _modelShown = YES;
    
    if (!_welcomeContainer) {
        _welcomeContainer = [[UIView alloc] init];
        _welcomeContainer.backgroundColor = [UIColor colorWithRed:0.92 green:0.94 blue:0.97 alpha:1.0];
        _welcomeContainer.translatesAutoresizingMaskIntoConstraints = NO;
        [self.view addSubview:_welcomeContainer];
        
        [self.view addConstraints:@[
         [NSLayoutConstraint constraintWithItem:_welcomeContainer
                                      attribute:NSLayoutAttributeTop
                                      relatedBy:NSLayoutRelationEqual
                                         toItem:self.view
                                      attribute:NSLayoutAttributeTop
                                     multiplier:1 constant:0],
         [NSLayoutConstraint constraintWithItem:_welcomeContainer
                                      attribute:NSLayoutAttributeBottom
                                      relatedBy:NSLayoutRelationEqual
                                         toItem:self.inputToolbar
                                      attribute:NSLayoutAttributeTop
                                     multiplier:1 constant:0],
         [NSLayoutConstraint constraintWithItem:_welcomeContainer
                                      attribute:NSLayoutAttributeLeft
                                      relatedBy:NSLayoutRelationEqual
                                         toItem:self.view
                                      attribute:NSLayoutAttributeLeft
                                     multiplier:1 constant:0],
         [NSLayoutConstraint constraintWithItem:_welcomeContainer
                                      attribute:NSLayoutAttributeRight
                                      relatedBy:NSLayoutRelationEqual
                                         toItem:self.view
                                      attribute:NSLayoutAttributeRight
                                     multiplier:1 constant:0]
         ]];
    }
    
    if (!_welcomeTitleLabel) {
        _welcomeTitleLabel = [[UILabel alloc] init];
        _welcomeTitleLabel.text = @"Привет, я DeepSeek";
        _welcomeTitleLabel.textAlignment = NSTextAlignmentCenter;
        _welcomeTitleLabel.font = [UIFont boldSystemFontOfSize:24];
        _welcomeTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _welcomeTitleLabel.backgroundColor = [UIColor clearColor];
        [_welcomeContainer addSubview:_welcomeTitleLabel];
        
        [_welcomeContainer addConstraints:@[
         [NSLayoutConstraint constraintWithItem:_welcomeTitleLabel
                                      attribute:NSLayoutAttributeCenterX
                                      relatedBy:NSLayoutRelationEqual
                                         toItem:_welcomeContainer
                                      attribute:NSLayoutAttributeCenterX
                                     multiplier:1 constant:0],
         [NSLayoutConstraint constraintWithItem:_welcomeTitleLabel
                                      attribute:NSLayoutAttributeCenterY
                                      relatedBy:NSLayoutRelationEqual
                                         toItem:_welcomeContainer
                                      attribute:NSLayoutAttributeCenterY
                                     multiplier:1 constant:-70]
         ]];
    }
    
    if (!_welcomeSubtitleLabel) {
        _welcomeSubtitleLabel = [[UILabel alloc] init];
        _welcomeSubtitleLabel.text = @"Чем могу помочь?";
        _welcomeSubtitleLabel.textAlignment = NSTextAlignmentCenter;
        _welcomeSubtitleLabel.font = [UIFont systemFontOfSize:16];
        _welcomeSubtitleLabel.textColor = [UIColor grayColor];
        _welcomeSubtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _welcomeSubtitleLabel.backgroundColor = [UIColor clearColor];
        [_welcomeContainer addSubview:_welcomeSubtitleLabel];
        
        [_welcomeContainer addConstraints:@[
         [NSLayoutConstraint constraintWithItem:_welcomeSubtitleLabel
                                      attribute:NSLayoutAttributeCenterX
                                      relatedBy:NSLayoutRelationEqual
                                         toItem:_welcomeContainer
                                      attribute:NSLayoutAttributeCenterX
                                     multiplier:1 constant:0],
         [NSLayoutConstraint constraintWithItem:_welcomeSubtitleLabel
                                      attribute:NSLayoutAttributeTop
                                      relatedBy:NSLayoutRelationEqual
                                         toItem:_welcomeTitleLabel
                                      attribute:NSLayoutAttributeBottom
                                     multiplier:1 constant:8]
         ]];
    }
    
    if (!_modelSegment) {
        _modelSegment = [[UISegmentedControl alloc] initWithItems:@[@"Быстрый", @"Эксперт"]];
        _modelSegment.translatesAutoresizingMaskIntoConstraints = NO;
        _modelSegment.selectedSegmentIndex = 0;
        [_modelSegment addTarget:self action:@selector(modelSegmentChanged:) forControlEvents:UIControlEventValueChanged];
        [_welcomeContainer addSubview:_modelSegment];
        
        [_welcomeContainer addConstraints:@[
         [NSLayoutConstraint constraintWithItem:_modelSegment
                                      attribute:NSLayoutAttributeCenterX
                                      relatedBy:NSLayoutRelationEqual
                                         toItem:_welcomeContainer
                                      attribute:NSLayoutAttributeCenterX
                                     multiplier:1 constant:0],
         [NSLayoutConstraint constraintWithItem:_modelSegment
                                      attribute:NSLayoutAttributeTop
                                      relatedBy:NSLayoutRelationEqual
                                         toItem:_welcomeSubtitleLabel
                                      attribute:NSLayoutAttributeBottom
                                     multiplier:1 constant:25],
         [NSLayoutConstraint constraintWithItem:_modelSegment
                                      attribute:NSLayoutAttributeWidth
                                      relatedBy:NSLayoutRelationEqual
                                         toItem:nil
                                      attribute:NSLayoutAttributeNotAnAttribute
                                     multiplier:1 constant:260],
         [NSLayoutConstraint constraintWithItem:_modelSegment
                                      attribute:NSLayoutAttributeHeight
                                      relatedBy:NSLayoutRelationEqual
                                         toItem:nil
                                      attribute:NSLayoutAttributeNotAnAttribute
                                     multiplier:1 constant:36]
         ]];
    }
    
    _welcomeContainer.hidden = NO;
    _welcomeTitleLabel.hidden = NO;
    _welcomeSubtitleLabel.hidden = NO;
    _modelSegment.hidden = NO;
    
    [self.view bringSubviewToFront:self.inputToolbar];
}

- (void)bringToolbarToFront {
    if (self.inputToolbar) {
        [self.view bringSubviewToFront:self.inputToolbar];
    }
}

- (void)dismissModelSelection {
    _modelShown = NO;
    _welcomeContainer.hidden = YES;
    _welcomeTitleLabel.hidden = YES;
    _welcomeSubtitleLabel.hidden = YES;
    _modelSegment.hidden = YES;
}

- (ChatSession *)createEmptyChatSession {
    ChatSession *session = [[ChatSession alloc] init];
    session.title = @"Новый чат";
    session.sessionId = nil;
    session.updatedAt = [[NSDate date] timeIntervalSince1970];
    session.insertedAt = session.updatedAt;
    session.isTemporary = YES;
    return session;
}

- (void)resetForNewChat {
    _modelShown = NO;
    [self dismissModelSelection];
    
    if (self.presenter) {
        [self.presenter resetForNewChat];
    }
    
    [self showModelSelection];
}

- (void)modelSegmentChanged:(UISegmentedControl *)sender {
    _isExpertMode = sender.selectedSegmentIndex == 1;
    NSString *modelType = _isExpertMode ? @"expert" : @"default";
    
    if (_isExpertMode) {
        _searchEnabled = NO;
        if (_modesPopover) {
            ModesViewController *vc = (ModesViewController *)_modesPopover.contentViewController;
            vc.allowSearch = NO;
            vc.searchEnabled = NO;
            [vc.tableView reloadData];
        }
    }
    
    [self.presenter setModel:modelType];
}

#pragma mark - DetailViewProtocol

- (void)updateNavigationTitle:(NSString *)title {
    self.title = title;
}

- (void)reloadChatTable {
    [self.chatTableView reloadData];
}

- (void)scrollToBottomAnimated:(BOOL)animated {
    NSInteger rows = [self.chatTableView numberOfRowsInSection:0];
    if (rows > 0) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:rows - 1 inSection:0];
        [self.chatTableView scrollToRowAtIndexPath:indexPath
                                  atScrollPosition:UITableViewScrollPositionBottom
                                          animated:animated];
    }
}

- (void)showLoading:(BOOL)show {
    if (show) {
        self.sendButton.enabled = NO;
        self.messageTextField.enabled = NO;
        
        UIActivityIndicatorViewStyle style = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) ? UIActivityIndicatorViewStyleGray : UIActivityIndicatorViewStyleWhite;
        
        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:style];
        [spinner startAnimating];
        
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinner];
    } else {
        self.sendButton.enabled = YES;
        self.messageTextField.enabled = YES;
        self.navigationItem.rightBarButtonItem = nil;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (DetailPresenter *)presenter {
    return _presenter;
}

#pragma mark - UIActionSheet

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        return;
    }
    
    if (buttonIndex == 0) {
        _deepThinkEnabled = !_deepThinkEnabled;
    }
    
    if (buttonIndex == 1) {
        if (_isExpertMode) {
            return;
        }
        _searchEnabled = !_searchEnabled;
    }
    
    [self.presenter setModesWithDeepThink:_deepThinkEnabled search:_searchEnabled];
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    if (_modesPopover == popoverController) {
        _modesPopover = nil;
    }
}

@end
