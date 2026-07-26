
#import "MasterDataSource.h"
#import "DataManager.h"
#import "ChatSession.h"

@implementation MasterDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [DataManager sharedManager].chatSessions.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    ChatSession *session = [self chatSessionAtIndexPath:indexPath];
    cell.textLabel.text = session.title ?: @"Новый чат";
    
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:session.updatedAt];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterShortStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    cell.detailTextLabel.text = [formatter stringFromDate:date];
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

- (ChatSession *)chatSessionAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *sessions = [DataManager sharedManager].chatSessions;
    if (indexPath.row < sessions.count) {
        return sessions[indexPath.row];
    }
    return nil;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.deleteDelegate respondsToSelector:
         @selector(tableView:commitEditingStyle:forRowAtIndexPath:)]) {
        
        [self.deleteDelegate tableView:tableView
                    commitEditingStyle:editingStyle
                     forRowAtIndexPath:indexPath];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"Удалить";
}

@end
