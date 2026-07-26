
#import <UIKit/UIKit.h>
#import "DetailPresenter.h"
@class ChatSession;

@interface DetailViewController : UIViewController

@property (strong, nonatomic) id detailItem; 
@property (strong, nonatomic) IBOutlet UITableView *chatTableView;
@property (strong, nonatomic) IBOutlet UIView *inputBar;
@property (strong, nonatomic) IBOutlet UITextField *messageTextField;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *sendButton;
@property (weak, nonatomic) IBOutlet UIToolbar *inputToolbar;
@property IBOutlet UIBarButtonItem *modesButton;
- (DetailPresenter *)presenter;
- (void)showModelSelection;   
- (void)dismissModelSelection; 
- (void)resetForNewChat;

@end
