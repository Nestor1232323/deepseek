
#import "SettingsViewController.h"
#import "SettingsManager.h"
#import "APIService.h"
#import "IPAlertManager.h"
#import "ErrorAlertManager.h"

@interface UserTableViewCell : UITableViewCell
@end

@implementation UserTableViewCell

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect imageFrame = self.imageView.frame;
    imageFrame.origin.x = 0; 
    imageFrame.size = CGSizeMake(44, 44);
    self.imageView.frame = imageFrame;
    
    CGRect textFrame = self.textLabel.frame;
    textFrame.origin.x = CGRectGetMaxX(imageFrame) + 10;
    textFrame.size.width = self.contentView.frame.size.width - textFrame.origin.x - 25;
    self.textLabel.frame = textFrame;
    
    CGFloat centerY = self.contentView.frame.size.height / 2;
    CGRect newImageFrame = self.imageView.frame;
    newImageFrame.origin.y = (self.contentView.frame.size.height - newImageFrame.size.height) / 2;
    self.imageView.frame = newImageFrame;
    
    CGRect newTextFrame = self.textLabel.frame;
    newTextFrame.origin.y = (self.contentView.frame.size.height - newTextFrame.size.height) / 2;
    self.textLabel.frame = newTextFrame;
}

@end

@interface SettingsViewController () <IPAlertManagerDelegate>

@property (nonatomic, assign) BOOL isDebugMode;
@property (nonatomic, strong) NSDictionary *userData;
@property (nonatomic, strong) UIImage *avatarImage;
@property (nonatomic, assign) BOOL isUserDataLoaded;

@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Настройки";
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [self.tableView registerClass:[UserTableViewCell class] forCellReuseIdentifier:@"UserCell"];
    
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    id debugValue = infoDict[@"Debug"];
    if (!debugValue) {
        debugValue = infoDict[@"debug"];
    }
    self.isDebugMode = [debugValue boolValue];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(serverIPDidChange:)
                                                 name:@"ServerIPChanged"
                                               object:nil];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                    target:self
                                                                                    action:@selector(dismissSettings)];
        self.navigationItem.rightBarButtonItem = doneButton;
    }
    
    self.isUserDataLoaded = NO;
    [self fetchUserData];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)dismissSettings {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)serverIPDidChange:(NSNotification *)notification {
    NSString *newIP = notification.object;
    [[APIService sharedService] initializeWithIP:newIP];
    
    [[APIService sharedService] checkServerStatus:^(id response) {
        [self.tableView reloadData];
        [[ErrorAlertManager sharedManager] showSuccessWithTitle:@"Успешно"
                                                        message:[NSString stringWithFormat:@"Подключение к серверу %@ установлено", newIP]];
    } failure:^(NSError *error) {
        [self.tableView reloadData];
        [[ErrorAlertManager sharedManager] showErrorWithTitle:@"Ошибка подключения"
                                                      message:[NSString stringWithFormat:@"Сервер по адресу %@:45516 недоступен.", newIP]];
    }];
}

#pragma mark - Helper Methods

- (NSString *)appVersion {
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString *version = infoDict[@"CFBundleShortVersionString"];
    NSString *build = infoDict[@"CFBundleVersion"];
    
    id debugValue = infoDict[@"Debug"];
    if (!debugValue) {
        debugValue = infoDict[@"debug"];
    }
    BOOL isDebug = [debugValue boolValue];
    
    NSString *versionString;
    if (version && build) {
        versionString = [NSString stringWithFormat:@"DeepSeek v%@ (build %@)", version, build];
    } else if (version) {
        versionString = [NSString stringWithFormat:@"DeepSeek v%@", version];
    } else {
        versionString = @"DeepSeek v1.0";
    }
    
    if (isDebug) {
        versionString = [versionString stringByAppendingString:@" 🔧"];
    }
    
    return versionString;
}

- (void)showDebugAlert {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Debug режим"
                                                    message:@"Заменить все ячейки таблицы чатов на тестовые данные?"
                                                   delegate:self
                                          cancelButtonTitle:@"Отмена"
                                          otherButtonTitles:@"Да", nil];
    alert.tag = 999;
    [alert show];
}

#pragma mark - User Data

- (void)fetchUserData {
    [[APIService sharedService] fetchMe:^(id response) {
        
        NSDictionary *user = (NSDictionary *)response;
        
        NSDictionary *idProfile = user[@"id_profile"];
        
        self.userData = @{
                          @"id": user[@"id"] ?: @"",
                          @"token": user[@"token"] ?: @"",
                          @"email": user[@"email"] ?: @"",
                          @"name": idProfile[@"name"] ?: @"Пользователь",
                          @"provider": idProfile[@"provider"] ?: @"",
                          @"picture": idProfile[@"picture"] ?: @"",
                          @"profile_id": idProfile[@"id"] ?: @""
                          };
        
        self.isUserDataLoaded = YES;
        
        
        [self loadAvatarFromURL:self.userData[@"picture"]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
        
    } failure:^(NSError *error) {
        self.userData = @{
                          @"id": @"",
                          @"token": @"",
                          @"email": @"",
                          @"name": @"Пользователь",
                          @"provider": @"",
                          @"picture": @"",
                          @"profile_id": @""
                          };
        self.isUserDataLoaded = YES;
        self.avatarImage = [self createDefaultAvatar];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    }];
}

- (void)loadAvatarFromURL:(NSString *)urlString {
    if (!urlString || urlString.length == 0) {
        self.avatarImage = [self createDefaultAvatar];
        return;
    }
    
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        self.avatarImage = [self createDefaultAvatar];
        return;
    }
    
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               if (error || !data) {
                                   self.avatarImage = [self createDefaultAvatar];
                                   [self.tableView reloadData];
                                   return;
                               }
                               
                               UIImage *image = [UIImage imageWithData:data];
                               if (image) {
                                   UIImage *squareImage = [self cropToSquare:image size:CGSizeMake(40, 40)];
                                   self.avatarImage = squareImage;
                               } else {
                                   self.avatarImage = [self createDefaultAvatar];
                               }
                               [self.tableView reloadData];
                           }];
}

- (UIImage *)cropToSquare:(UIImage *)image size:(CGSize)size {
    UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *squareImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return squareImage;
}
- (UIImage *)createDefaultAvatar {
    CGSize size = CGSizeMake(44, 44);
    UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
    
    [[UIColor lightGrayColor] setFill];
    UIRectFill(CGRectMake(0, 0, size.width, size.height));
    
    UIImage *defaultImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return defaultImage;
}
- (void)showUserInfo {
    if (!self.userData) {
        [[ErrorAlertManager sharedManager] showErrorWithTitle:@"Ошибка"
                                                      message:@"Данные пользователя не загружены"];
        return;
    }
    
    NSString *message = [NSString stringWithFormat:
                         @"ID: %@\n\nEmail: %@\n\nИмя: %@\n\nПровайдер: %@\n\nProfile ID: %@",
                         self.userData[@"id"],
                         self.userData[@"email"],
                         self.userData[@"name"],
                         self.userData[@"provider"],
                         self.userData[@"profile_id"]
                         ];
    
    [[ErrorAlertManager sharedManager] showSuccessWithTitle:@"Информация о пользователе"
                                                    message:message];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 999 && buttonIndex == 1) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DebugReplaceChats" object:nil];
        [[ErrorAlertManager sharedManager] showSuccessWithTitle:@"Готово"
                                                        message:@"Ячейки таблицы чатов заменены на тестовые данные"];
    }
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.isDebugMode) {
        return 3;
    }
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return 3;
    if (self.isDebugMode && section == 1) return 1;
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) return @"Профиль";
    if (self.isDebugMode && section == 1) return @"Debug";
    return @"Информация";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row == 0) {
        UserTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UserCell"];
        if (cell == nil) {
            cell = [[UserTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"UserCell"];
        }
        
        cell.textLabel.textColor = [UIColor blackColor];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.imageView.image = nil;
        cell.detailTextLabel.text = nil;
        
        if (self.isUserDataLoaded && self.userData) {
            cell.textLabel.text = self.userData[@"name"] ?: @"Пользователь";
        } else {
            cell.textLabel.text = @"Загрузка...";
        }
        
        if (self.avatarImage) {
            cell.imageView.image = self.avatarImage;
        } else {
            cell.imageView.image = [self createDefaultAvatar];
        }
        
        return cell;
    }
    
    static NSString *CellIdentifier = @"SettingsCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell.textLabel.textColor = [UIColor blackColor];
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.imageView.image = nil;
    cell.detailTextLabel.text = nil;
    
    if (indexPath.section == 0) {
        if (indexPath.row == 1) {
            cell.textLabel.text = @"IP сервера";
            cell.detailTextLabel.text = [[SettingsManager sharedManager] getServerIP] ?: @"Не задан";
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.accessoryType = UITableViewCellAccessoryNone;
        } else {
            cell.textLabel.text = @"Изменить IP";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    } else if (self.isDebugMode && indexPath.section == 1) {
        cell.textLabel.text = @"Заменить ячейки чатов";
        cell.textLabel.textColor = [UIColor redColor];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        cell.textLabel.text = @"О приложении";
        cell.detailTextLabel.text = [self appVersion];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 0 && indexPath.row == 0) {
        [self showUserInfo];
    } else if (indexPath.section == 0 && indexPath.row == 2) {
        [IPAlertManager sharedManager].delegate = self;
        [[IPAlertManager sharedManager] showIPAlert];
    } else if (self.isDebugMode && indexPath.section == 1 && indexPath.row == 0) {
        [self showDebugAlert];
    } else if (indexPath.section == (self.isDebugMode ? 2 : 1) && indexPath.row == 0) {
        NSString *version = [self appVersion];
        [[ErrorAlertManager sharedManager] showSuccessWithTitle:version
                                                        message:@"Приложение для общения с ИИ\n\n© 2026"];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row == 0) {
        return 44.0; 
    }
    return 44.0;
}

#pragma mark - IPAlertManagerDelegate

- (void)ipAlertDidConfirmWithIP:(NSString *)ip {
    [[IPAlertManager sharedManager] dismiss];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ServerIPChanged" object:ip];
}

- (void)ipAlertDidCancel {
    [[IPAlertManager sharedManager] dismiss];
}

@end
