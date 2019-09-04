#import <UIKit/UIKit.h>

@interface MExtendedTableView : UITableView

@property (retain,nonatomic) IBOutlet UIView *emptyView;

@property (nonatomic,readonly) bool tableViewHasRows;

- (UIView*)emptyViewWithTitle:(NSString*)title;

@end
