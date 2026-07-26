
#import <UIKit/UIKit.h>

@interface MarkdownRenderer : NSObject

+ (UIView *)renderMarkdown:(NSString *)text maxWidth:(CGFloat)maxWidth textColor:(UIColor *)textColor;
+ (CGFloat)realWidthForMarkdown:(NSString *)text maxWidth:(CGFloat)maxWidth;
+ (CGFloat)heightForMarkdown:(NSString *)text maxWidth:(CGFloat)maxWidth;

@end
