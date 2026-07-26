#import <UIKit/UIKit.h>

@interface ModesViewController : UITableViewController

@property (nonatomic, assign) BOOL deepThinkEnabled;
@property (nonatomic, assign) BOOL searchEnabled;

@property (nonatomic, assign) BOOL allowSearch;

@property (nonatomic, copy) void (^onChange)(BOOL deepThink, BOOL search);

@end
