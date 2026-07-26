#import "NavigationRouter.h"
#import "SettingsViewController.h"

@interface NavigationRouter () {
    UIPopoverController *_settingsPopover;
}
@end

@implementation NavigationRouter

+ (instancetype)sharedRouter {
    static NavigationRouter *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)presentSettingsFromButton:(UIBarButtonItem *)barButtonItem insideController:(UIViewController *)parentController {
    SettingsViewController *settingsVC = [[SettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:settingsVC];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        if ([_settingsPopover isPopoverVisible]) {
            [_settingsPopover dismissPopoverAnimated:YES];
            return;
        }
        
        navController.contentSizeForViewInPopover = CGSizeMake(320.0, 480.0);
        _settingsPopover = [[UIPopoverController alloc] initWithContentViewController:navController];
        
        [_settingsPopover presentPopoverFromBarButtonItem:barButtonItem
                                 permittedArrowDirections:UIPopoverArrowDirectionAny
                                                 animated:YES];
    } else {
        navController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        [parentController presentViewController:navController animated:YES completion:nil];
    }
}

@end
