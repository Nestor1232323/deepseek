
#import "MarkdownRenderer.h"
#import <UIKit/UIKit.h>

@interface MarkdownLinkButton : UIButton
@property (nonatomic, strong) NSString *url;
@end

@implementation MarkdownLinkButton
@end

@implementation MarkdownRenderer

+ (UIView *)renderMarkdown:(NSString *)markdown
                  maxWidth:(CGFloat)maxWidth
                 textColor:(UIColor *)textColor {
    
    if (!markdown || markdown.length == 0) {
        return [[UIView alloc] init];
    }
    
    UIView *container = [[UIView alloc] init];
    container.backgroundColor = [UIColor clearColor];
    
    CGFloat currentY = 0;
    NSArray *lines = [markdown componentsSeparatedByString:@"\n"];
    
    NSMutableArray *quoteLines = [NSMutableArray array];
    BOOL inTable = NO;
    NSMutableArray *tableRows = [NSMutableArray array];
    NSArray *tableHeaders = nil;
    BOOL inCodeBlock = NO;
    NSMutableString *codeBlockText = [NSMutableString string];
    
    for (NSString *line in lines) {
        NSString *trimmedLine = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        if ([trimmedLine hasPrefix:@"```"]) {
            if (!inCodeBlock) {
                inCodeBlock = YES;
                codeBlockText = [NSMutableString string];
                NSString *language = [trimmedLine stringByReplacingOccurrencesOfString:@"```" withString:@""];
                language = [language stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                continue; 
            } else {
                inCodeBlock = NO;
                
                UITextView *codeView = [[UITextView alloc] init];
                codeView.text = codeBlockText;
                codeView.font = [UIFont fontWithName:@"Courier" size:13.0f];
                codeView.textColor = textColor;
                codeView.backgroundColor = [UIColor colorWithWhite:0.9 alpha:0.3];
                codeView.editable = NO;
                codeView.scrollEnabled = NO;
                
                CGSize size = [codeBlockText sizeWithFont:codeView.font
                                        constrainedToSize:CGSizeMake(maxWidth - 20, CGFLOAT_MAX)
                                            lineBreakMode:UILineBreakModeWordWrap];
                codeView.frame = CGRectMake(10, currentY, maxWidth - 20, size.height + 20);
                [container addSubview:codeView];
                currentY += size.height + 30;
                continue; 
            }
        }
        
        if (inCodeBlock) {
            [codeBlockText appendString:line];
            [codeBlockText appendString:@"\n"];
            continue;
        }
        
        if ([trimmedLine hasPrefix:@"$$"] || [trimmedLine hasPrefix:@"\\["]) {
            UILabel *label = [[UILabel alloc] init];
            label.text = @"[LaTeX формула не отображается в iOS 6]";
            label.font = [UIFont italicSystemFontOfSize:13.0f];
            label.textColor = [UIColor colorWithWhite:0.6 alpha:1.0];
            label.numberOfLines = 1;
            label.backgroundColor = [UIColor clearColor];
            label.textAlignment = UITextAlignmentCenter;
            label.frame = CGRectMake(0, currentY, maxWidth, 25);
            [container addSubview:label];
            currentY += 30;
            continue;
        }
        
        NSRange latexRange = [trimmedLine rangeOfString:@"\\\\("];
        if (latexRange.location != NSNotFound) {
            trimmedLine = [trimmedLine stringByReplacingOccurrencesOfString:@"\\(" withString:@""];
            trimmedLine = [trimmedLine stringByReplacingOccurrencesOfString:@"\\)" withString:@""];
        }
        
        if ([trimmedLine hasPrefix:@"|"] && [trimmedLine hasSuffix:@"|"]) {
            if (!inTable) {
                inTable = YES;
                tableRows = [NSMutableArray array];
                tableHeaders = nil;
            }
            
            if ([trimmedLine rangeOfString:@"---"].location != NSNotFound &&
                [trimmedLine rangeOfString:@"|"].location != NSNotFound) {
                continue;
            }
            
            NSArray *cells = [trimmedLine componentsSeparatedByString:@"|"];
            NSMutableArray *cleanCells = [NSMutableArray array];
            for (NSString *cell in cells) {
                NSString *clean = [cell stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                if (clean.length > 0) {
                    [cleanCells addObject:clean];
                }
            }
            
            if (!tableHeaders) {
                tableHeaders = cleanCells;
            } else {
                [tableRows addObject:cleanCells];
            }
            continue;
        }
        
        if (inTable && trimmedLine.length > 0 && ![trimmedLine hasPrefix:@"|"]) {
            CGFloat tableY = currentY;
            CGFloat cellHeight = 30;
            CGFloat colWidth = (maxWidth - 20) / tableHeaders.count;
            
            for (int i = 0; i < tableHeaders.count; i++) {
                UILabel *headerLabel = [[UILabel alloc] init];
                headerLabel.text = tableHeaders[i];
                headerLabel.font = [UIFont boldSystemFontOfSize:14.0f];
                headerLabel.textColor = textColor;
                headerLabel.textAlignment = UITextAlignmentCenter;
                headerLabel.backgroundColor = [UIColor colorWithWhite:0.8 alpha:0.3];
                headerLabel.frame = CGRectMake(10 + i * colWidth, tableY, colWidth - 2, cellHeight);
                [container addSubview:headerLabel];
            }
            tableY += cellHeight;
            
            UIView *separator = [[UIView alloc] init];
            separator.backgroundColor = [UIColor colorWithWhite:0.6 alpha:0.5];
            separator.frame = CGRectMake(10, tableY, maxWidth - 20, 1);
            [container addSubview:separator];
            tableY += 4;
            
            for (NSArray *row in tableRows) {
                for (int i = 0; i < row.count && i < tableHeaders.count; i++) {
                    UILabel *cellLabel =
                    [self createFormattedLabel:row[i]
                                     textColor:textColor
                                      maxWidth:colWidth-4];
                    cellLabel.textAlignment = UITextAlignmentCenter;
                    cellLabel.frame =
                    CGRectMake(10 + i * colWidth,
                               tableY,
                               colWidth - 2,
                               cellHeight);
                    [container addSubview:cellLabel];
                    
                }
                tableY += cellHeight + 2;
            }
            
            currentY = tableY + 10;
            inTable = NO;
            tableRows = [NSMutableArray array];
            tableHeaders = nil;
            continue;
        }
        
        if ([trimmedLine hasPrefix:@">"]) {
            NSString *quoteText = [trimmedLine substringFromIndex:1];
            [quoteLines addObject:quoteText];
            continue;
        }
        
        if (quoteLines.count > 0 && ![trimmedLine hasPrefix:@">"]) {
            UIView *quoteView = [[UIView alloc] init];
            quoteView.backgroundColor = [UIColor colorWithWhite:0.92 alpha:0.2];
            
            UIView *leftLine = [[UIView alloc] init];
            leftLine.backgroundColor = [UIColor colorWithWhite:0.6 alpha:0.5];
            leftLine.frame = CGRectMake(0, 0, 3, 1);
            [quoteView addSubview:leftLine];
            
            CGFloat quoteY = 4;
            for (NSString *ql in quoteLines) {
                UILabel *label = [[UILabel alloc] init];
                label.attributedText = [self parseQuoteWithMarkdown:ql textColor:textColor maxWidth:maxWidth - 30];
                label.numberOfLines = 0;
                label.backgroundColor = [UIColor clearColor];
                label.numberOfLines = 0;
                label.backgroundColor = [UIColor clearColor];
                label.lineBreakMode = UILineBreakModeWordWrap;
                
                CGSize size = [label.attributedText boundingRectWithSize:CGSizeMake(maxWidth - 30, CGFLOAT_MAX)
                                                                 options:NSStringDrawingUsesLineFragmentOrigin
                                                                 context:nil].size;
                label.frame = CGRectMake(15, quoteY, maxWidth - 30, size.height);
                [quoteView addSubview:label];
                quoteY += size.height + 4;
            }
            
            CGRect lineFrame = leftLine.frame;
            lineFrame.size.height = quoteY + 4;
            leftLine.frame = lineFrame;
            
            quoteView.frame = CGRectMake(0, currentY, maxWidth, quoteY + 4);
            [container addSubview:quoteView];
            currentY += quoteY + 8;
            [quoteLines removeAllObjects];
            continue;
        }
        
        if ([trimmedLine hasPrefix:@"# "]) {
            UILabel *label = [self createLabel:[trimmedLine substringFromIndex:2]
                                          font:[UIFont boldSystemFontOfSize:22.0f]
                                     textColor:textColor
                                      maxWidth:maxWidth];
            label.frame = CGRectMake(0, currentY, maxWidth, label.frame.size.height);
            [container addSubview:label];
            currentY += label.frame.size.height + 10;
            continue;
        }
        
        if ([trimmedLine hasPrefix:@"## "]) {
            UILabel *label = [self createLabel:[trimmedLine substringFromIndex:3]
                                          font:[UIFont boldSystemFontOfSize:20.0f]
                                     textColor:textColor
                                      maxWidth:maxWidth];
            label.frame = CGRectMake(0, currentY, maxWidth, label.frame.size.height);
            [container addSubview:label];
            currentY += label.frame.size.height + 8;
            continue;
        }
        
        if ([trimmedLine hasPrefix:@"### "]) {
            UILabel *label = [self createLabel:[trimmedLine substringFromIndex:4]
                                          font:[UIFont boldSystemFontOfSize:18.0f]
                                     textColor:textColor
                                      maxWidth:maxWidth];
            label.frame = CGRectMake(0, currentY, maxWidth, label.frame.size.height);
            [container addSubview:label];
            currentY += label.frame.size.height + 6;
            continue;
        }
        
        if ([trimmedLine hasPrefix:@"- "] ||
            [trimmedLine hasPrefix:@"* "]) {
            
            NSString *text = [trimmedLine substringFromIndex:2];
            
            NSInteger indent = 0;
            NSString *tempLine = line;
            while ([tempLine hasPrefix:@" "]) {
                indent++;
                tempLine = [tempLine substringFromIndex:1];
            }
            
            CGFloat leftOffset = 6 + indent * 8;
            
            
            UILabel *label = [self createFormattedLabel:
                              [NSString stringWithFormat:@"• %@", text]
                                              textColor:textColor
                                               maxWidth:maxWidth - leftOffset - 5];
            
            
            label.frame = CGRectMake(leftOffset,
                                     currentY,
                                     maxWidth - leftOffset - 5,
                                     label.frame.size.height);
            
            [container addSubview:label];
            
            
            currentY += label.frame.size.height;
            
            continue;
        }
        
        NSRange numRange = [trimmedLine rangeOfString:@"^\\d+\\. "
                                              options:NSRegularExpressionSearch];
        
        if (numRange.location != NSNotFound) {
            
            NSString *number =
            [trimmedLine substringWithRange:
             NSMakeRange(0, numRange.length)];
            
            
            NSString *text =
            [trimmedLine substringFromIndex:numRange.length];
            
            
            UILabel *label =
            [self createFormattedLabel:
             [NSString stringWithFormat:@"%@%@", number, text]
                             textColor:textColor
                              maxWidth:maxWidth - 20];
            
            
            label.frame =
            CGRectMake(20,
                       currentY,
                       maxWidth - 20,
                       label.frame.size.height);
            
            
            [container addSubview:label];
            
            
            currentY += label.frame.size.height;
            
            continue;
        }
        
        if ([trimmedLine isEqualToString:@"---"] || [trimmedLine isEqualToString:@"***"] || [trimmedLine isEqualToString:@"___"]) {
            UIView *lineView = [[UIView alloc] init];
            lineView.backgroundColor = [UIColor colorWithWhite:0.7 alpha:0.5];
            lineView.frame = CGRectMake(0, currentY, maxWidth, 1);
            [container addSubview:lineView];
            currentY += 16;
            continue;
        }
        
        if ([trimmedLine hasPrefix:@"!["]) {
            UILabel *label = [[UILabel alloc] init];
            label.text = @"[изображение]";
            label.font = [UIFont italicSystemFontOfSize:14.0f];
            label.textColor = [UIColor colorWithWhite:0.6 alpha:1.0];
            label.numberOfLines = 1;
            label.backgroundColor = [UIColor clearColor];
            label.frame = CGRectMake(0, currentY, maxWidth, 20);
            [container addSubview:label];
            currentY += 24;
            continue;
        }
        
        if (trimmedLine.length > 0) {
            NSRange linkRange = [trimmedLine rangeOfString:@"\\[([^\\]]+)\\]\\(([^\\)]+)\\)" options:NSRegularExpressionSearch];
            
            if (linkRange.location != NSNotFound) {
                NSString *linkText = @"";
                NSString *url = @"";
                
                NSRange textStart = [trimmedLine rangeOfString:@"\\[" options:NSRegularExpressionSearch];
                if (textStart.location != NSNotFound) {
                    NSInteger start = textStart.location + 1;
                    NSInteger end = [trimmedLine rangeOfString:@"\\]" options:NSRegularExpressionSearch].location;
                    if (end != NSNotFound && end > start) {
                        linkText = [trimmedLine substringWithRange:NSMakeRange(start, end - start)];
                    }
                }
                
                NSRange urlStart = [trimmedLine rangeOfString:@"\\(" options:NSRegularExpressionSearch];
                if (urlStart.location != NSNotFound) {
                    NSInteger start = urlStart.location + 1;
                    NSInteger end = [trimmedLine rangeOfString:@"\\)" options:NSRegularExpressionSearch].location;
                    if (end != NSNotFound && end > start) {
                        url = [trimmedLine substringWithRange:NSMakeRange(start, end - start)];
                    }
                }
                
                if (linkText.length > 0) {
                    MarkdownLinkButton *button = [MarkdownLinkButton buttonWithType:UIButtonTypeCustom];
                    [button setTitle:linkText forState:UIControlStateNormal];
                    UIColor *linkColor =
                    [UIColor colorWithRed:0.0f
                                    green:0.45f
                                     blue:1.0f
                                    alpha:1.0f];
                    
                    [button setTitleColor:linkColor forState:UIControlStateNormal];
                    button.titleLabel.font = [UIFont systemFontOfSize:15.0f];
                    button.titleLabel.numberOfLines = 0;
                    button.titleLabel.lineBreakMode = UILineBreakModeWordWrap;
                    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
                    button.backgroundColor = [UIColor clearColor];
                    button.url = url;
                    
                    CGSize textSize = [linkText sizeWithFont:button.titleLabel.font
                                           constrainedToSize:CGSizeMake(maxWidth, CGFLOAT_MAX)
                                               lineBreakMode:UILineBreakModeWordWrap];
                    
                    UIView *underline = [[UIView alloc] init];
                    underline.backgroundColor = textColor;
                    underline.frame = CGRectMake(0, textSize.height - 2, textSize.width, 1);
                    underline.userInteractionEnabled = NO;
                    [button addSubview:underline];
                    
                    button.frame = CGRectMake(0, currentY, textSize.width, textSize.height + 4);
                    [button addTarget:self action:@selector(linkButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
                    [container addSubview:button];
                    
                    currentY += textSize.height + 6;
                    continue;
                }
            }
            
            UILabel *label = [self createFormattedLabel:trimmedLine
                                              textColor:textColor
                                               maxWidth:maxWidth];
            label.frame = CGRectMake(0, currentY, maxWidth, label.frame.size.height);
            [container addSubview:label];
            currentY += label.frame.size.height + 2;
        } else {
            currentY += 8;
        }
    }
    
    if (quoteLines.count > 0) {
        UIView *quoteView = [[UIView alloc] init];
        quoteView.backgroundColor = [UIColor colorWithWhite:0.9 alpha:0.2];
        
        CGFloat quoteY = 4;
        for (NSString *ql in quoteLines) {
            UILabel *label = [[UILabel alloc] init];
            label.attributedText = [self parseQuoteWithMarkdown:ql textColor:textColor maxWidth:maxWidth - 30];
            label.numberOfLines = 0;
            label.backgroundColor = [UIColor clearColor];
            CGSize size = [label.attributedText boundingRectWithSize:CGSizeMake(maxWidth - 30, CGFLOAT_MAX)
                                                             options:NSStringDrawingUsesLineFragmentOrigin
                                                             context:nil].size;
            label.frame = CGRectMake(15, quoteY, maxWidth - 30, ceilf(size.height));
            [quoteView addSubview:label];
            quoteY += label.frame.size.height + 4;
        }
        
        quoteView.frame = CGRectMake(0, currentY, maxWidth, quoteY + 4);
        [container addSubview:quoteView];
        currentY += quoteY + 8;
    }
    
    if (inTable && tableRows.count > 0) {
        
        CGFloat tableY = currentY;
        
        CGFloat tablePadding = 10;
        CGFloat cellHeight = 34;
        
        CGFloat tableWidth = maxWidth - 20;
        CGFloat colWidth = tableWidth / tableHeaders.count;
        
        
        UIView *tableBackground = [[UIView alloc] init];
        
        tableBackground.backgroundColor =
        [UIColor colorWithWhite:0.0 alpha:0.6];
        
        tableBackground.frame =
        CGRectMake(10,
                   tableY,
                   tableWidth,
                   cellHeight +
                   (tableRows.count * cellHeight));
        
        [container addSubview:tableBackground];
        
        
        
        CGFloat innerY = 0;
        
        
        for (int i = 0; i < tableHeaders.count; i++) {
            
            UILabel *headerLabel =
            [self createFormattedLabel:
             tableHeaders[i]
                             textColor:textColor
                              maxWidth:colWidth-8];
            
            
            headerLabel.font =
            [UIFont boldSystemFontOfSize:14];
            
            
            headerLabel.textAlignment =
            UITextAlignmentCenter;
            
            
            headerLabel.backgroundColor =
            [UIColor colorWithWhite:0.85 alpha:0.8];
            
            
            headerLabel.frame =
            CGRectMake(i * colWidth,
                       innerY,
                       colWidth,
                       cellHeight);
            
            
            [tableBackground addSubview:headerLabel];
        }
        
        
        innerY += cellHeight;
        
        
        
        NSInteger rowIndex = 0;
        
        
        for (NSArray *row in tableRows) {
            
            
            BOOL even =
            rowIndex % 2 == 0;
            
            
            UIView *rowView =
            [[UIView alloc] init];
            
            
            rowView.backgroundColor =
            even ?
            [UIColor colorWithWhite:1 alpha:0.0] :
            [UIColor colorWithWhite:0.9 alpha:0.35];
            
            
            rowView.frame =
            CGRectMake(0,
                       innerY,
                       tableWidth,
                       cellHeight);
            
            
            [tableBackground addSubview:rowView];
            
            
            
            for (int i = 0;
                 i < row.count && i < tableHeaders.count;
                 i++) {
                
                
                UILabel *cellLabel =
                [self createFormattedLabel:
                 row[i]
                                 textColor:textColor
                                  maxWidth:colWidth-8];
                
                
                cellLabel.textAlignment =
                UITextAlignmentCenter;
                
                
                cellLabel.font =
                [UIFont systemFontOfSize:13];
                
                
                cellLabel.frame =
                CGRectMake(i * colWidth + 4,
                           0,
                           colWidth - 8,
                           cellHeight);
                
                
                [rowView addSubview:cellLabel];
                
                
                
                if (i < tableHeaders.count - 1) {
                    
                    UIView *divider =
                    [[UIView alloc] init];
                    
                    divider.backgroundColor =
                    [UIColor colorWithWhite:0.8 alpha:0.5];
                    
                    
                    divider.frame =
                    CGRectMake((i+1)*colWidth,
                               0,
                               1,
                               cellHeight);
                    
                    
                    [rowView addSubview:divider];
                }
            }
            
            
            innerY += cellHeight;
            
            rowIndex++;
        }
        
        
        currentY =
        tableY + tableBackground.frame.size.height + 10;
    }
    
    maxWidth = floorf(maxWidth);
    
    container.frame = CGRectMake(0,
                                 0,
                                 maxWidth,
                                 ceilf(currentY));
    return container;
}

+ (UILabel *)createLabel:(NSString *)text
                    font:(UIFont *)font
               textColor:(UIColor *)textColor
                maxWidth:(CGFloat)maxWidth {
    
    UILabel *label = [[UILabel alloc] init];
    
    label.text = text;
    label.font = font;
    label.textColor = textColor;
    label.numberOfLines = 0;
    label.backgroundColor = [UIColor clearColor];
    label.lineBreakMode = UILineBreakModeWordWrap;
    
    CGSize constraint = CGSizeMake(maxWidth, CGFLOAT_MAX);
    
    CGSize size = [text sizeWithFont:font
                   constrainedToSize:constraint
                       lineBreakMode:UILineBreakModeWordWrap];
    
    
    label.frame = CGRectMake(
                             0,
                             0,
                             maxWidth,
                             ceilf(size.height)
                             );
    
    
    return label;
}
+ (UILabel *)createFormattedLabel:(NSString *)text
                        textColor:(UIColor *)textColor
                         maxWidth:(CGFloat)maxWidth {
    
    UILabel *label = [[UILabel alloc] init];
    
    label.numberOfLines = 0;
    label.backgroundColor = [UIColor clearColor];
    label.lineBreakMode = UILineBreakModeWordWrap;
    
    
    NSMutableAttributedString *attr =
    [[NSMutableAttributedString alloc] initWithString:text];
    
    
    UIFont *normal =
    [UIFont systemFontOfSize:15.0f];
    
    UIFont *bold =
    [UIFont boldSystemFontOfSize:15.0f];
    
    UIFont *italic =
    [UIFont italicSystemFontOfSize:15.0f];
    
    
    [attr addAttribute:NSFontAttributeName
                 value:normal
                 range:NSMakeRange(0, attr.length)];
    
    [attr addAttribute:NSForegroundColorAttributeName
                 value:textColor
                 range:NSMakeRange(0, attr.length)];
    
    
    NSString *string = [attr string];
    
    
    NSRange boldRange;
    
    while ((boldRange =
            [string rangeOfString:@"**"]).location != NSNotFound) {
        
        
        NSRange second =
        [string rangeOfString:@"**"
                      options:0
                        range:NSMakeRange(
                                          boldRange.location + 2,
                                          string.length - boldRange.location - 2)];
        
        if (second.location == NSNotFound)
            break;
        
        
        NSRange content =
        NSMakeRange(
                    boldRange.location + 2,
                    second.location - boldRange.location - 2);
        
        
        [attr addAttribute:NSFontAttributeName
                     value:bold
                     range:content];
        
        
        [attr deleteCharactersInRange:
         NSMakeRange(second.location,2)];
        
        [attr deleteCharactersInRange:
         NSMakeRange(boldRange.location,2)];
        
        
        string = [attr string];
    }
    
    
    
    string = [attr string];
    
    
    while ((boldRange =
            [string rangeOfString:@"*"]).location != NSNotFound) {
        
        
        NSRange second =
        [string rangeOfString:@"*"
                      options:0
                        range:NSMakeRange(
                                          boldRange.location + 1,
                                          string.length - boldRange.location - 1)];
        
        
        if(second.location == NSNotFound)
            break;
        
        
        NSRange content =
        NSMakeRange(
                    boldRange.location + 1,
                    second.location - boldRange.location - 1);
        
        
        [attr addAttribute:NSFontAttributeName
                     value:italic
                     range:content];
        
        
        [attr deleteCharactersInRange:
         NSMakeRange(second.location,1)];
        
        [attr deleteCharactersInRange:
         NSMakeRange(boldRange.location,1)];
        
        
        string=[attr string];
    }
    
    
    
    string=[attr string];
    
    NSRange codeStart;
    
    while ((codeStart =
            [string rangeOfString:@"`"]).location != NSNotFound) {
        
        
        NSRange codeEnd =
        [string rangeOfString:@"`"
                      options:0
                        range:NSMakeRange(
                                          codeStart.location+1,
                                          string.length-codeStart.location-1)];
        
        
        if(codeEnd.location==NSNotFound)
            break;
        
        
        NSRange codeRange =
        NSMakeRange(
                    codeStart.location+1,
                    codeEnd.location-codeStart.location-1);
        
        
        
        [attr addAttribute:NSFontAttributeName
                     value:[UIFont fontWithName:@"Courier"
                                           size:14]
                     range:codeRange];
        
        
        [attr deleteCharactersInRange:
         NSMakeRange(codeEnd.location,1)];
        
        [attr deleteCharactersInRange:
         NSMakeRange(codeStart.location,1)];
        
        
        string=[attr string];
    }
    
    
    
    label.attributedText = attr;
    
    
    CGSize size =
    [attr boundingRectWithSize:
     CGSizeMake(maxWidth, CGFLOAT_MAX)
                       options:
     NSStringDrawingUsesLineFragmentOrigin
                       context:nil].size;
    
    
    label.frame =
    CGRectMake(0,
               0,
               maxWidth,
               ceilf(size.height));
    
    
    return label;
}

+ (void)linkButtonTapped:(id)sender {
    MarkdownLinkButton *button = (MarkdownLinkButton *)sender;
    if (button.url && button.url.length > 0) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:button.url]];
    }
}

+ (CGFloat)heightForMarkdown:(NSString *)markdown
                    maxWidth:(CGFloat)maxWidth {
    if (!markdown || markdown.length == 0) {
        return 20;
    }
    
    UIView *tempView = [self renderMarkdown:markdown maxWidth:maxWidth textColor:[UIColor blackColor]];
    return tempView.frame.size.height + 16;
}
+ (CGFloat)realWidthForMarkdown:(NSString *)markdown
                       maxWidth:(CGFloat)maxWidth {
    
    if (!markdown || markdown.length == 0) {
        return 20;
    }
    
    NSArray *lines = [markdown componentsSeparatedByString:@"\n"];
    
    CGFloat maxLineWidth = 0;
    
    UIFont *font = [UIFont systemFontOfSize:15.0f];
    
    for (NSString *line in lines) {
        
        CGSize size = [line sizeWithFont:font];
        
        if (size.width > maxLineWidth) {
            maxLineWidth = size.width;
        }
    }
    
    
    if (maxLineWidth < 40) {
        maxLineWidth = 40;
    }
    
    
    if (maxLineWidth > maxWidth) {
        maxLineWidth = maxWidth;
    }
    
    
    return ceilf(maxLineWidth);
}
+ (NSAttributedString *)parseQuoteWithMarkdown:(NSString *)quoteText
                                     textColor:(UIColor *)textColor
                                      maxWidth:(CGFloat)maxWidth {
    
    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:quoteText];
    
    UIFont *normal = [UIFont systemFontOfSize:15.0f];
    UIFont *bold = [UIFont boldSystemFontOfSize:15.0f];
    UIFont *italic = [UIFont italicSystemFontOfSize:15.0f];
    
    [attr addAttribute:NSFontAttributeName value:normal range:NSMakeRange(0, attr.length)];
    [attr addAttribute:NSForegroundColorAttributeName value:textColor range:NSMakeRange(0, attr.length)];
    
    NSString *string = [attr string];
    
    NSRange boldRange;
    while ((boldRange = [string rangeOfString:@"**"]).location != NSNotFound) {
        NSRange second = [string rangeOfString:@"**" options:0 range:NSMakeRange(boldRange.location + 2, string.length - boldRange.location - 2)];
        if (second.location == NSNotFound) break;
        NSRange content = NSMakeRange(boldRange.location + 2, second.location - boldRange.location - 2);
        [attr addAttribute:NSFontAttributeName value:bold range:content];
        [attr deleteCharactersInRange:NSMakeRange(second.location, 2)];
        [attr deleteCharactersInRange:NSMakeRange(boldRange.location, 2)];
        string = [attr string];
    }
    
    string = [attr string];
    while ((boldRange = [string rangeOfString:@"*"]).location != NSNotFound) {
        NSRange second = [string rangeOfString:@"*" options:0 range:NSMakeRange(boldRange.location + 1, string.length - boldRange.location - 1)];
        if (second.location == NSNotFound) break;
        NSRange content = NSMakeRange(boldRange.location + 1, second.location - boldRange.location - 1);
        [attr addAttribute:NSFontAttributeName value:italic range:content];
        [attr deleteCharactersInRange:NSMakeRange(second.location, 1)];
        [attr deleteCharactersInRange:NSMakeRange(boldRange.location, 1)];
        string = [attr string];
    }
    
    string = [attr string];
    NSRange codeStart;
    while ((codeStart = [string rangeOfString:@"`"]).location != NSNotFound) {
        NSRange codeEnd = [string rangeOfString:@"`" options:0 range:NSMakeRange(codeStart.location + 1, string.length - codeStart.location - 1)];
        if (codeEnd.location == NSNotFound) break;
        NSRange codeRange = NSMakeRange(codeStart.location + 1, codeEnd.location - codeStart.location - 1);
        [attr addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"Courier" size:14] range:codeRange];
        [attr deleteCharactersInRange:NSMakeRange(codeEnd.location, 1)];
        [attr deleteCharactersInRange:NSMakeRange(codeStart.location, 1)];
        string = [attr string];
    }
    
    return attr;
}
@end
