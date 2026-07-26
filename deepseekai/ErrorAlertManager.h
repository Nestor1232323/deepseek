
#import <UIKit/UIKit.h>

@interface ErrorAlertManager : NSObject

+ (instancetype)sharedManager;

- (void)showErrorWithTitle:(NSString *)title message:(NSString *)message;
- (void)showSuccessWithTitle:(NSString *)title message:(NSString *)message;
- (void)showConfirmationWithTitle:(NSString *)title
                          message:(NSString *)message
                      cancelTitle:(NSString *)cancelTitle
                     confirmTitle:(NSString *)confirmTitle
                           target:(id)target
                     cancelAction:(SEL)cancelAction
                    confirmAction:(SEL)confirmAction;

@end
