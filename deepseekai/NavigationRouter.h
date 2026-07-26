#import <UIKit/UIKit.h>

@interface NavigationRouter : NSObject

+ (instancetype)sharedRouter;
- (void)presentSettingsFromButton:(UIBarButtonItem *)barButtonItem insideController:(UIViewController *)parentController;

@end
