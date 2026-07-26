
#import "BubbleCell.h"
#import "MarkdownRenderer.h"

@interface BubbleCell ()
@property (nonatomic, strong) NSString *currentText;
@property (nonatomic) CGFloat contentHeight;
@property (nonatomic) CGFloat contentWidth;
@end

@implementation BubbleCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        
        self.bubbleContainer = [[UIImageView alloc] init];
        self.bubbleContainer.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:self.bubbleContainer];
        
        self.contentContainer = [[UIView alloc] init];
        self.contentContainer.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:self.contentContainer];
    }
    return self;
}

- (void)configureWithText:(NSString *)text isOutgoing:(BOOL)isOutgoing {
    self.isOutgoing = isOutgoing;
    self.currentText = text;
    self.contentWidth = 0;
    self.contentHeight = 0;
    
    for (UIView *v in self.contentContainer.subviews) {
        [v removeFromSuperview];
    }
    
    CGFloat screenWidth = [[UIScreen mainScreen] bounds].size.width;
    CGFloat maxBubbleWidth = screenWidth * 0.75f;
    if (maxBubbleWidth > 600) {
        maxBubbleWidth = 600;
    }
    
    CGFloat leftPadding = 12;
    CGFloat rightPadding = 20;
    CGFloat availableTextWidth = maxBubbleWidth - leftPadding - rightPadding;
    
    UIView *markdownView = [MarkdownRenderer renderMarkdown:text
                                                   maxWidth:availableTextWidth
                                                  textColor:[UIColor blackColor]];
    
    CGFloat realTextWidth = [MarkdownRenderer realWidthForMarkdown:text
                                                          maxWidth:availableTextWidth];
    self.contentWidth = realTextWidth;
    self.contentHeight = markdownView.frame.size.height;
    
    markdownView.frame = CGRectMake(0, 0, self.contentWidth, self.contentHeight);
    [self.contentContainer addSubview:markdownView];
    [self.contentContainer setNeedsLayout];
    [self setNeedsLayout];
    
    UIImage *rawImage;
    if (self.isOutgoing) {
        rawImage = [UIImage imageNamed:@"Balloon_1.png"];
        self.bubbleContainer.image = [rawImage stretchableImageWithLeftCapWidth:15
                                                                   topCapHeight:13];
    } else {
        rawImage = [UIImage imageNamed:@"Balloon_2.png"];
        self.bubbleContainer.image = [rawImage stretchableImageWithLeftCapWidth:21
                                                                   topCapHeight:13];
    }
    
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat leftPadding = self.isOutgoing ? 12 : 20;
    CGFloat rightPadding = 20;
    CGFloat topPadding = 9;
    CGFloat bottomPadding = 11;
    CGFloat topMargin = 2;
    CGFloat edgeOffset = 5;
    
    CGFloat bubbleWidth = ceilf(self.contentWidth + leftPadding + rightPadding);
    CGFloat bubbleHeight = self.contentHeight + topPadding + bottomPadding;
    
    if (self.isOutgoing) {
        CGFloat x = self.contentView.bounds.size.width - bubbleWidth - edgeOffset;
        self.bubbleContainer.frame = CGRectMake(x, topMargin, bubbleWidth, bubbleHeight);
        self.contentContainer.frame = CGRectMake(x + leftPadding,
                                                 topMargin + topPadding,
                                                 self.contentWidth,
                                                 self.contentHeight);
    } else {
        self.bubbleContainer.frame = CGRectMake(edgeOffset, topMargin, bubbleWidth, bubbleHeight);
        self.contentContainer.frame = CGRectMake(edgeOffset + leftPadding,
                                                 topMargin + topPadding,
                                                 self.contentWidth,
                                                 self.contentHeight);
    }
}

+ (CGFloat)heightForText:(NSString *)text width:(CGFloat)width isOutgoing:(BOOL)isOutgoing {
    CGFloat maxBubbleWidth = [[UIScreen mainScreen] bounds].size.width * 0.75f;
    if (maxBubbleWidth > 600) {
        maxBubbleWidth = 600;
    }
    
    CGFloat leftPadding = isOutgoing ? 12 : 20;
    CGFloat rightPadding = isOutgoing ? 20 : 16;
    CGFloat textWidth = maxBubbleWidth - leftPadding - rightPadding;
    
    CGFloat textHeight = [MarkdownRenderer heightForMarkdown:text maxWidth:textWidth];
    
    return ceilf(textHeight) + 4 + 4 + 2; 
}

@end
