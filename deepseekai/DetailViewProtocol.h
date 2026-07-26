#import <Foundation/Foundation.h>

@protocol DetailViewProtocol <NSObject>

- (void)updateNavigationTitle:(NSString *)title;
- (void)updateDescriptionText:(NSString *)text;
- (void)setLeftBarButton:(UIBarButtonItem *)barButton;

@end
