
#import <UIKit/UIKit.h>

@class ChatSession;

@interface MasterDataSource : NSObject <UITableViewDataSource>

- (ChatSession *)chatSessionAtIndexPath:(NSIndexPath *)indexPath;
@property(nonatomic, weak) id deleteDelegate;

@end
