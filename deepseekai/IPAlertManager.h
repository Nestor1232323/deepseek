
#import <UIKit/UIKit.h>

@protocol IPAlertManagerDelegate <NSObject>
@optional
- (void)ipAlertDidConfirmWithIP:(NSString *)ip;
- (void)ipAlertDidCancel;
@end

@interface IPAlertManager : NSObject <UIAlertViewDelegate>

@property (nonatomic, weak) id<IPAlertManagerDelegate> delegate;
@property (nonatomic, strong) UIAlertView *currentAlert;

+ (instancetype)sharedManager;
- (void)showIPAlert;
- (void)dismiss;

@end
