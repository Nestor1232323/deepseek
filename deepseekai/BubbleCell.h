
#import <UIKit/UIKit.h>

@interface BubbleCell : UITableViewCell

@property (nonatomic, strong) UIImageView *bubbleContainer;
@property (nonatomic, strong) UIView *contentContainer;
@property (nonatomic, assign) BOOL isOutgoing;

- (void)configureWithText:(NSString *)text isOutgoing:(BOOL)isOutgoing;
+ (CGFloat)heightForText:(NSString *)text width:(CGFloat)width isOutgoing:(BOOL)isOutgoing;

@end
