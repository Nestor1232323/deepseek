#import "ModesViewController.h"

@interface ModesViewController ()

@property NSArray *items;

@end


@implementation ModesViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.items = @[
                   @"DeepThink",
                   @"Search"
                   ];
    
    self.contentSizeForViewInPopover = CGSizeMake(220, 87);
}


- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
    
    return self.items.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell =
    [tableView dequeueReusableCellWithIdentifier:@"ModeCell"];
    
    if (!cell) {
        cell = [[UITableViewCell alloc]
                initWithStyle:UITableViewCellStyleDefault
                reuseIdentifier:@"ModeCell"];
    }
    
    
    cell.textLabel.text = self.items[indexPath.row];
    
    
    BOOL checked = NO;
    
    if (indexPath.row == 0) {
        checked = self.deepThinkEnabled;
    }
    
    if (indexPath.row == 1) {
        
        checked = self.searchEnabled;
        
        if (!self.allowSearch) {
            
            cell.textLabel.textColor = [UIColor lightGrayColor];
            cell.accessoryType = UITableViewCellAccessoryNone;
            
            return cell;
        }
    }
    
    cell.accessoryType =
    checked ?
    UITableViewCellAccessoryCheckmark :
    UITableViewCellAccessoryNone;
    
    
    return cell;
}


- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    if (indexPath.row == 1 && !self.allowSearch) {
        return;
    }
    
    
    if (indexPath.row == 0) {
        
        self.deepThinkEnabled =
        !self.deepThinkEnabled;
    }
    
    
    if (indexPath.row == 1) {
        
        self.searchEnabled =
        !self.searchEnabled;
    }
    
    
    [tableView reloadData];
    
    
    if (self.onChange) {
        
        self.onChange(
                      self.deepThinkEnabled,
                      self.searchEnabled
                      );
    }
}
@end
