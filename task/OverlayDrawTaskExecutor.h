#import "TaskExecutor.h"

NS_ASSUME_NONNULL_BEGIN

@class OverlayDrawer;
@class DirectoryItem;

@interface OverlayDrawTaskExecutor : NSObject <TaskExecutor> {
  OverlayDrawer  *overlayDrawer;
}

- (instancetype) initWithScanTree:(DirectoryItem *)scanTree NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
