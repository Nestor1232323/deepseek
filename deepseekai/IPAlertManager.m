
#import "IPAlertManager.h"
#import "SettingsManager.h"

@implementation IPAlertManager

+ (instancetype)sharedManager {
    static IPAlertManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (void)showIPAlert {
    if (self.currentAlert && self.currentAlert.isVisible) {
        return;
    }
    
    self.currentAlert = [[UIAlertView alloc] initWithTitle:@"Настройка сервера"
                                                   message:@"Введите IP-адрес сервера (например: 192.168.1.100)"
                                                  delegate:self
                                         cancelButtonTitle:@"Отмена"
                                         otherButtonTitles:@"OK", nil];
    self.currentAlert.tag = 1;
    
    self.currentAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
    UITextField *textField = [self.currentAlert textFieldAtIndex:0];
    textField.placeholder = @"192.168.1.100";
    textField.keyboardType = UIKeyboardTypeDecimalPad;
    textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    textField.autocorrectionType = UITextAutocorrectionTypeNo;
    
    NSString *savedIP = [[SettingsManager sharedManager] getServerIP];
    if (savedIP) {
        textField.text = savedIP;
    }
    
    [self.currentAlert show];
}

- (void)dismiss {
    if (self.currentAlert && self.currentAlert.isVisible) {
        [self.currentAlert dismissWithClickedButtonIndex:0 animated:YES];
    }
    self.currentAlert = nil;
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag != 1) return;
    
    id<IPAlertManagerDelegate> delegate = self.delegate;
    
    if (buttonIndex == 0) {
        if ([delegate respondsToSelector:@selector(ipAlertDidCancel)]) {
            [delegate ipAlertDidCancel];
        }
    } else if (buttonIndex == 1) {
        UITextField *textField = [alertView textFieldAtIndex:0];
        NSString *ip = textField.text;
        ip = [ip stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        if (ip.length > 0) {
            [[SettingsManager sharedManager] saveServerIP:ip];
            if ([delegate respondsToSelector:@selector(ipAlertDidConfirmWithIP:)]) {
                [delegate ipAlertDidConfirmWithIP:ip];
            }
        } else {
            UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Ошибка"
                                                                 message:@"IP-адрес не может быть пустым"
                                                                delegate:nil
                                                       cancelButtonTitle:@"OK"
                                                       otherButtonTitles:nil];
            [errorAlert show];
            [self showIPAlert];
        }
    }
    
    self.currentAlert = nil;
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 1) {
        self.currentAlert = nil;
    }
}

@end
