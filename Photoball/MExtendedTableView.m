#import "MExtendedTableView.h"
#import <QuartzCore/QuartzCore.h>

@implementation MExtendedTableView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self sharedInitializer];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
       [self sharedInitializer];
    }
    return self;
}

- (void)sharedInitializer
{
    self.emptyView = nil;
    self.backgroundColor = [UIColor blackColor];
}

- (bool) tableViewHasRows
{
    // TODO: This only supports the first section so far
    return [self numberOfRowsInSection:0] == 0;
}

- (void) updateEmptyPage
{
    const CGRect rect = (CGRect){CGPointZero,self.frame.size};
    self.emptyView.frame  = rect;
    self.emptyView.backgroundColor = [UIColor blackColor];
    
    const bool shouldShowEmptyView = self.tableViewHasRows;
    const bool emptyViewShown      = _emptyView.superview != nil;
    
    if (shouldShowEmptyView == emptyViewShown) return;
    
    CATransition *animation = [CATransition animation];
    [animation setDuration:0.5];
    [animation setType:kCATransitionFade];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]];
    [[self layer] addAnimation:animation forKey:kCATransitionReveal];
    
    if (shouldShowEmptyView)
    {
        [self addSubview:_emptyView];
        self.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    else
    {
        [_emptyView removeFromSuperview];
        self.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    }
}

- (void) setEmptyView:(UIView *)newView
{
    if (newView == _emptyView) return;
    if (newView == nil) return;
    _emptyView = newView;
    [self updateEmptyPage];
}

#pragma mark UIView

- (void) layoutSubviews
{
    [super layoutSubviews];
    [self updateEmptyPage];
}

- (UIView*) hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    // Prevent any interaction when the empty view is shown
    const bool emptyViewShown = _emptyView.superview != nil;
    return emptyViewShown ? nil : [super hitTest:point withEvent:event];
}

#pragma mark UITableView

- (void) reloadData
{
    [super reloadData];
    [self updateEmptyPage];
}

- (UIView*)emptyViewWithTitle:(NSString*)title
{
    UIView *view = [[UIView alloc] initWithFrame:self.bounds];
    view.backgroundColor = [UIColor whiteColor];
    UILabel *msgLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    msgLabel.font = [UIFont fontWithName:@"OpenSans" size:16];
    msgLabel.backgroundColor = [UIColor clearColor];
    msgLabel.textColor = [UIColor lightGrayColor];
    //msgLabel.shadowColor = [UIColor blackColor];
    msgLabel.text = title;
    msgLabel.textAlignment = NSTextAlignmentCenter;
    [msgLabel sizeToFit];
    float offsetX = self.frame.size.width/2.f - msgLabel.frame.size.width/2.f;
    msgLabel.frame = CGRectMake(offsetX, self.frame.size.height/2.f, msgLabel.frame.size.width, msgLabel.frame.size.height);
    [view addSubview:msgLabel];
    return view;
}

@end
