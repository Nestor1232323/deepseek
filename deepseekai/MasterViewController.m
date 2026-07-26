
#import "MasterViewController.h"
#import "DetailViewController.h"
#import "SettingsViewController.h"
#import "DataManager.h"
#import "MasterDataSource.h"
#import "NavigationRouter.h"
#import "SettingsManager.h"
#import "APIService.h"
#import "IPAlertManager.h"
#import "ErrorAlertManager.h"
#import "ChatSession.h"

@interface MasterViewController () <IPAlertManagerDelegate>

@property (nonatomic, strong) MasterDataSource *tableDataSource;
@property (nonatomic, strong) UIRefreshControl *refreshControl;

@end

@implementation MasterViewController

- (void)awakeFromNib
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
        self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
    }
    [super awakeFromNib];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableDataSource = [[MasterDataSource alloc] init];
    self.tableDataSource.deleteDelegate = self;
    self.tableView.dataSource = self.tableDataSource;
    
    [self setupRefreshControl];
    
    UIBarButtonItem *settingsButton = [[UIBarButtonItem alloc] initWithTitle:@"Настройки"
                                                                       style:UIBarButtonItemStyleBordered
                                                                      target:self
                                                                      action:@selector(settingsButtonTapped:)];
    self.navigationItem.leftBarButtonItem = settingsButton;
    
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                               target:self
                                                                               action:@selector(insertNewObjectTapped:)];
    self.navigationItem.rightBarButtonItem = addButton;
    
    self.detailViewController = (DetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    
    [self checkServerIP];

    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(chatCreated:)
                                                 name:@"ChatCreated"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(chatTitleUpdated:)
                                                 name:@"ChatTitleUpdated"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(debugReplaceChats)
                                                 name:@"DebugReplaceChats"
                                               object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Chat Notifications
- (void)chatCreated:(NSNotification *)notification {
    
    ChatSession *session = notification.object;
    
    if (!session.sessionId || session.sessionId.length == 0) {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSMutableArray *sessions =
        [NSMutableArray arrayWithArray:[DataManager sharedManager].chatSessions];
        
        
        BOOL updated = NO;
        
        
        for (ChatSession *s in sessions) {
            
            if (s.isTemporary) {
                
                s.sessionId = session.sessionId;
                s.title = session.title;
                s.updatedAt = session.updatedAt;
                s.isTemporary = NO;
                
                updated = YES;
                
                
                break;
            }
        }
        
        
        if (!updated) {
            
            
            [sessions insertObject:session atIndex:0];
        }
        
        
        [[DataManager sharedManager] setChatSessions:sessions];
        
        [self.tableView reloadData];
        
        
        for (NSInteger i = 0; i < sessions.count; i++) {
            
            ChatSession *s = sessions[i];
            
            if ([s.sessionId isEqualToString:session.sessionId]) {
                
                NSIndexPath *indexPath =
                [NSIndexPath indexPathForRow:i inSection:0];
                
                
                [self.tableView selectRowAtIndexPath:indexPath
                                            animated:YES
                                      scrollPosition:UITableViewScrollPositionMiddle];
                
                break;
            }
        }
        
        
    });
}

- (void)chatTitleUpdated:(NSNotification *)notification {
    NSDictionary *data = notification.object;
    NSString *chatId = data[@"chatId"];
    NSString *title = data[@"title"];
    
    if (!chatId || !title) return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray *sessions = [DataManager sharedManager].chatSessions;
        for (int i = 0; i < sessions.count; i++) {
            ChatSession *session = sessions[i];
            if ([session.sessionId isEqualToString:chatId]) {
                session.title = title;
                [self.tableView reloadData];
                
                if (self.detailViewController && self.detailViewController.detailItem == session) {
                    self.detailViewController.title = title;
                }
                
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
                [self.tableView selectRowAtIndexPath:indexPath
                                            animated:YES
                                      scrollPosition:UITableViewScrollPositionTop];
                
                break;
            }
        }
    });
}

#pragma mark - Debug

- (void)debugReplaceChats {
    NSMutableArray *testSessions = [NSMutableArray array];
    
    for (int i = 1; i <= 100; i++) {
        ChatSession *session = [[ChatSession alloc] init];
        session.sessionId = [NSString stringWithFormat:@"test_%d", i];
        session.title = [NSString stringWithFormat:@"Placeholder %d", i];
        session.updatedAt = [[NSDate date] timeIntervalSince1970] - (i * 3600);
        session.insertedAt = session.updatedAt;
        session.titleType = @"SYSTEM";
        session.modelType = @"default";
        session.agent = @"chat";
        session.version = i;
        session.currentMessageId = [NSString stringWithFormat:@"%d", i];
        [testSessions addObject:session];
    }
    
    [[DataManager sharedManager] setChatSessions:testSessions];
    [self.tableView reloadData];
}

#pragma mark - Pull-to-Refresh

- (void)setupRefreshControl {
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self
                            action:@selector(refreshChats)
                  forControlEvents:UIControlEventValueChanged];
    self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Обновление..."];
    [self.tableView addSubview:self.refreshControl];
}

- (void)refreshChats {
    [self loadChatSessions];
}

#pragma mark - Server IP Management

- (void)checkServerIP {
    if (![[SettingsManager sharedManager] hasServerIP]) {
        [self performSelector:@selector(showIPAlert) withObject:nil afterDelay:0.5];
    } else {
        NSString *savedIP = [[SettingsManager sharedManager] getServerIP];
        [self initializeAPIServiceWithIP:savedIP];
    }
}

- (void)showIPAlert {
    [IPAlertManager sharedManager].delegate = self;
    [[IPAlertManager sharedManager] showIPAlert];
}

#pragma mark - IPAlertManagerDelegate

- (void)ipAlertDidConfirmWithIP:(NSString *)ip {
    [[IPAlertManager sharedManager] dismiss];
    [self initializeAPIServiceWithIP:ip];
}

- (void)ipAlertDidCancel {
    [[IPAlertManager sharedManager] dismiss];
    
    [[ErrorAlertManager sharedManager] showConfirmationWithTitle:@"Внимание"
                                                         message:@"Для работы приложения необходим IP-адрес сервера"
                                                     cancelTitle:@"Выйти"
                                                    confirmTitle:@"Попробовать снова"
                                                          target:self
                                                    cancelAction:@selector(exitApp)
                                                   confirmAction:@selector(showIPAlert)];
}

- (void)exitApp {
    exit(0);
}

#pragma mark - API Service

- (void)initializeAPIServiceWithIP:(NSString *)ip {
    [[APIService sharedService] initializeWithIP:ip];
    
    [[APIService sharedService] checkServerStatus:^(id response) {
        [self loadChatSessions];
    } failure:^(NSError *error) {
        
        [[ErrorAlertManager sharedManager] showConfirmationWithTitle:@"Ошибка подключения"
                                                             message:[NSString stringWithFormat:@"Сервер по адресу %@:45516 недоступен.", ip]
                                                         cancelTitle:@"OK"
                                                        confirmTitle:@"Изменить IP"
                                                              target:self
                                                        cancelAction:nil
                                                       confirmAction:@selector(showIPAlert)];
    }];
}

- (void)loadChatSessions {
    [[APIService sharedService] fetchChatSessions:^(id response) {
        NSArray *sessions = (NSArray *)response;
        
        [[DataManager sharedManager] setChatSessions:sessions];
        [self.tableView reloadData];
        [self.refreshControl endRefreshing];
        
    } failure:^(NSError *error) {
        [[ErrorAlertManager sharedManager] showErrorWithTitle:@"Ошибка"
                                                      message:@"Не удалось загрузить список чатов"];
        [self.refreshControl endRefreshing];
    }];
}

#pragma mark - Actions

- (void)settingsButtonTapped:(UIBarButtonItem *)sender {
    [[NavigationRouter sharedRouter] presentSettingsFromButton:sender insideController:self];
}
- (void)insertNewObjectTapped:(id)sender {
    ChatSession *newSession = [[ChatSession alloc] init];
    
    newSession.title = @"Новый чат";
    newSession.sessionId = nil;
    
    newSession.updatedAt = [[NSDate date] timeIntervalSince1970];
    newSession.insertedAt = newSession.updatedAt;
    
    newSession.isTemporary = YES;
    NSMutableArray *sessions = [NSMutableArray arrayWithArray:[DataManager sharedManager].chatSessions];
    [sessions insertObject:newSession atIndex:0];
    [[DataManager sharedManager] setChatSessions:sessions];
    
    [self.tableView reloadData];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionTop];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        [self performSegueWithIdentifier:@"showDetail" sender:self];
    } else {
        self.detailViewController.detailItem = newSession;
        [self.detailViewController resetForNewChat];
    }
}
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        if (indexPath) {
            ChatSession *session = [self.tableDataSource chatSessionAtIndexPath:indexPath];
            DetailViewController *controller = (DetailViewController *)[segue destinationViewController];
            
            if ([controller isKindOfClass:[UINavigationController class]]) {
                controller = (DetailViewController *)[(UINavigationController *)controller topViewController];
            }
            
            [controller setDetailItem:session];
            
            if (!session.sessionId || session.sessionId.length == 0) {
                [controller resetForNewChat];
            }
        }
    }
}

#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        ChatSession *session = [self.tableDataSource chatSessionAtIndexPath:indexPath];
        self.detailViewController.detailItem = session;
    }
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger count = [DataManager sharedManager].chatSessions.count;
    
    if (count == 0) {
        return 1;
    }
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *sessions = [DataManager sharedManager].chatSessions;
    
    if (sessions.count == 0) {
        static NSString *EmptyCellIdentifier = @"EmptyCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:EmptyCellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:EmptyCellIdentifier];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.text = @"Нет чатов. Нажмите + чтобы начать";
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.textLabel.textColor = [UIColor grayColor];
        }
        return cell;
    }
    
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    ChatSession *session = sessions[indexPath.row];
    cell.textLabel.text = session.title ?: @"Новый чат";
    
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:session.updatedAt];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterShortStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    cell.detailTextLabel.text = [formatter stringFromDate:date];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

- (ChatSession *)chatSessionAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *sessions = [DataManager sharedManager].chatSessions;
    if (sessions.count == 0) {
        return nil;
    }
    if (indexPath.row < sessions.count) {
        return sessions[indexPath.row];
    }
    return nil;
}
- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return @"Удалить"; 
}
- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (editingStyle != UITableViewCellEditingStyleDelete)
        return;
    
    
    NSArray *sessions =
    [DataManager sharedManager].chatSessions;
    
    
    if (indexPath.row >= sessions.count)
        return;
    
    
    ChatSession *session = sessions[indexPath.row];
    
    
    if (!session.sessionId ||
        session.sessionId.length == 0) {
        
        
        NSMutableArray *mutable =
        [NSMutableArray arrayWithArray:sessions];
        
        
        [mutable removeObjectAtIndex:indexPath.row];
        
        
        [[DataManager sharedManager]
         setChatSessions:mutable];
        
        
        [tableView deleteRowsAtIndexPaths:@[indexPath]
                         withRowAnimation:UITableViewRowAnimationAutomatic];
        
        return;
    }
    
    
    
    NSString *chatId = session.sessionId;
    
    
    
    [[APIService sharedService]
     deleteChat:chatId
     success:^(id response) {
         
         
         dispatch_async(dispatch_get_main_queue(), ^{
             
             
             NSMutableArray *mutable =
             [NSMutableArray arrayWithArray:
              [DataManager sharedManager].chatSessions];
             
             
             [mutable removeObjectAtIndex:indexPath.row];
             
             
             [[DataManager sharedManager]
              setChatSessions:mutable];
             
             
             [tableView deleteRowsAtIndexPaths:@[indexPath]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
             
             
             
         });
         
         
     }
     failure:^(NSError *error) {
         
         
               error.localizedDescription;
         
         
         [[ErrorAlertManager sharedManager]
          showErrorWithTitle:@"Ошибка"
          message:@"Не удалось удалить чат"];
         
     }];
}
@end
