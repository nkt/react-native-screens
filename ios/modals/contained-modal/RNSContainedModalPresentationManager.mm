#import "RNSContainedModalPresentationManager.h"
#import "RNSContainedModalContentController.h"
#import "RNSContainedModalPresentationState.h"

@implementation RNSContainedModalPresentationManager {
  RNSContainedModalPresentationState _state;
}

- (instancetype)init
{
  if (self = [super init]) {
    _state = RNSContainedModalPresentationStateDismissed;
  }
  return self;
}

- (void)updatePresentationIfNeededWithProvider:(id<RNSContainedModalPresentationProvider>)provider
                                    controller:(RNSContainedModalContentController *)controller
{
  BOOL shouldBeOpen = provider.isOpen;

  if (shouldBeOpen) {
    [self presentIfNeededWithProvider:provider controller:controller];
  } else {
    [self dismissIfNeededWithProvider:provider controller:controller];
  }
}

- (void)presentIfNeededWithProvider:(id<RNSContainedModalPresentationProvider>)provider
                         controller:(RNSContainedModalContentController *)controller
{
  if (_state != RNSContainedModalPresentationStateDismissed) {
    return;
  }

  // A present call on a view that is not in a window is silently dropped by
  // UIKit (its completion never fires), so stay dismissed - the pending update
  // is flushed again from `didMoveToWindow` once the host attaches.
  if (provider.hostWindow == nil) {
    return;
  }

  UIViewController *presentationSourceViewController = provider.presentationSourceViewController;
  if (presentationSourceViewController == nil) {
    return;
  }

  // One open modal per provider: UIKit silently drops a present call on a view
  // controller that is already presenting (no exception, completion never
  // fires), so reject the request deterministically instead. The request is
  // not queued.
  if (presentationSourceViewController.presentedViewController != nil) {
    [controller.delegate modalControllerDidRejectPresentation:controller];
    return;
  }

  _state = RNSContainedModalPresentationStatePresenting;

  __weak auto weakSelf = self;
  [presentationSourceViewController presentViewController:controller
                                                 animated:YES
                                               completion:^{
                                                 auto strongSelf = weakSelf;
                                                 if (!strongSelf) {
                                                   return;
                                                 }

                                                 strongSelf->_state = RNSContainedModalPresentationStatePresented;
                                                 [strongSelf updatePresentationIfNeededWithProvider:provider
                                                                                         controller:controller];
                                               }];
}

- (void)dismissIfNeededWithProvider:(id<RNSContainedModalPresentationProvider>)provider
                         controller:(RNSContainedModalContentController *)controller
{
  if (_state != RNSContainedModalPresentationStatePresented) {
    return;
  }

  UIViewController *presentingViewController = controller.presentingViewController;
  if (presentingViewController == nil) {
    _state = RNSContainedModalPresentationStateDismissed;
    return;
  }

  _state = RNSContainedModalPresentationStateDismissing;

  __weak auto weakSelf = self;
  [presentingViewController dismissViewControllerAnimated:YES
                                               completion:^{
                                                 auto strongSelf = weakSelf;
                                                 if (!strongSelf) {
                                                   return;
                                                 }

                                                 strongSelf->_state = RNSContainedModalPresentationStateDismissed;
                                                 [strongSelf updatePresentationIfNeededWithProvider:provider
                                                                                         controller:controller];
                                               }];
}

- (BOOL)handleExternalDismiss
{
  if (_state == RNSContainedModalPresentationStateDismissing || _state == RNSContainedModalPresentationStateDismissed) {
    return NO;
  }

  _state = RNSContainedModalPresentationStateDismissed;
  return YES;
}

@end
