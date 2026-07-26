
#import "ErrorAlertManager.h"

@interface ErrorAlertManager () <UIAlertViewDelegate>

@property (nonatomic, weak) id confirmationTarget;
@property (nonatomic, assign) SEL cancelSelector;
@property (nonatomic, assign) SEL confirmSelector;

@end

@implementation ErrorAlertManager

+ (instancetype)sharedManager {
    static ErrorAlertManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (void)showErrorWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

- (void)showSuccessWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

- (void)showConfirmationWithTitle:(NSString *)title
                          message:(NSString *)message
                      cancelTitle:(NSString *)cancelTitle
                     confirmTitle:(NSString *)confirmTitle
                           target:(id)target
                     cancelAction:(SEL)cancelAction
                    confirmAction:(SEL)confirmAction {
    
    self.confirmationTarget = target;
    self.cancelSelector = cancelAction;
    self.confirmSelector = confirmAction;
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:cancelTitle
                                          otherButtonTitles:confirmTitle, nil];
    alert.tag = 1000;
    [alert show];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag != 1000) return;
    
    id target = self.confirmationTarget;
    
    if (buttonIndex == 0) {
        if (target && self.cancelSelector && [target respondsToSelector:self.cancelSelector]) {
            NSMethodSignature *signature = [target methodSignatureForSelector:self.cancelSelector];
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
            [invocation setTarget:target];
            [invocation setSelector:self.cancelSelector];
            [invocation invoke];
        }
    } else if (buttonIndex == 1) {
        if (target && self.confirmSelector && [target respondsToSelector:self.confirmSelector]) {
            NSMethodSignature *signature = [target methodSignatureForSelector:self.confirmSelector];
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
            [invocation setTarget:target];
            [invocation setSelector:self.confirmSelector];
            [invocation invoke];
        }
    }
    
    self.confirmationTarget = nil;
    self.cancelSelector = nil;
    self.confirmSelector = nil;
}

@end
