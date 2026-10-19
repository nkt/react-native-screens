#import "RNSContainedModalContentController.h"
#import "RNSContainedModalContentView.h"
#import "RNSContainedModalPresentationManager.h"

@implementation RNSContainedModalContentController {
  RNSContainedModalPresentationManager *_Nonnull _presentationManager;

  BOOL _needsPresentationUpdate;
}

- (instancetype)init
{
  if (self = [super init]) {
    // Native over-context style. The provider component view is a tight wrapper
    // around the context controller's view, so UIKit's transition container -
    // attached to the context view's superview with the superview's bounds and
    // a flexible autoresizing mask - is born confined to the provider and
    // tracks it through scroll, resize and rotation with no intervention.
    self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;

    _presentationManager = [RNSContainedModalPresentationManager new];
  }
  return self;
}

- (RNSContainedModalContentView *)contentView
{
  return static_cast<RNSContainedModalContentView *>(self.view);
}

#pragma mark - UIKit callbacks

- (void)loadView
{
  self.view = [RNSContainedModalContentView new];
}

- (void)viewDidLayoutSubviews
{
  [super viewDidLayoutSubviews];

  [self.delegate modalControllerViewDidLayoutSubviews:self];
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];

  [self.delegate modalControllerViewDidAppear:self];
}

- (void)viewDidDisappear:(BOOL)animated
{
  [super viewDidDisappear:animated];

  // A disappearance with the presentation relationship still intact is a
  // suspension (an ancestor left the window); UIKit restores it automatically
  // on re-attach, so only a severed relationship means the presentation is
  // actually gone and the state machine must re-sync.
  if (self.presentingViewController == nil) {
    [_presentationManager handleExternalDismiss];
  }

  [self.delegate modalControllerViewDidDisappear:self];
}

#pragma mark - Presentation Setup

- (void)updatePresentationState
{
  id<RNSContainedModalPresentationProvider> presentationProvider = self.presentationProvider;

  if (presentationProvider == nil) {
    return;
  }

  [_presentationManager updatePresentationIfNeededWithProvider:presentationProvider controller:self];
}

#pragma mark - Signals

- (void)setNeedsPresentationUpdate
{
  _needsPresentationUpdate = YES;
}

#pragma mark - Updates

- (void)flushPendingUpdates
{
  if (!_needsPresentationUpdate) {
    return;
  }
  _needsPresentationUpdate = NO;
  [self updatePresentationState];
}

@end
