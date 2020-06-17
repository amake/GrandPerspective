#import "TaskExecutor.h"

NS_ASSUME_NONNULL_BEGIN

@class OverlayDrawer;

@interface OverlayDrawTaskExecutor : NSObject <TaskExecutor> {
  OverlayDrawer  *overlayDrawer;
}

@end

NS_ASSUME_NONNULL_END
