#pragma once

#import <Foundation/Foundation.h>
#import "RNSContainedModalProviders.h"

@class RNSContainedModalContentController;

NS_ASSUME_NONNULL_BEGIN

@interface RNSContainedModalPresentationManager : NSObject

- (void)updatePresentationIfNeededWithProvider:(id<RNSContainedModalPresentationProvider>)provider
                                    controller:(RNSContainedModalContentController *)controller;

/**
 * Transitions the manager into the dismissed state in response to a dismissal
 * this manager did not itself initiate (e.g. the presentation was torn down
 * from outside while the manager considered it presented).
 *
 * @return NO if the manager was already dismissed or is mid programmatic
 *         dismissal. YES otherwise.
 */
- (BOOL)handleExternalDismiss;

@end

NS_ASSUME_NONNULL_END
