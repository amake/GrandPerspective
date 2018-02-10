#import <Cocoa/Cocoa.h>


@class AsynchronousTaskManager;
@class ProgressPanelControl;

/* Wraps around an AsynchronousTaskManager to show a progress panel whenever as task is run in the
 * background.
 */
@interface VisibleAsynchronousTaskManager : NSObject {

  AsynchronousTaskManager  *taskManager;
  ProgressPanelControl  *progressPanelControl;

}

- (instancetype) initWithProgressPanel:(ProgressPanelControl *)panelControl NS_DESIGNATED_INITIALIZER;

- (void) dispose;

- (void) abortTask;

- (void) asynchronouslyRunTaskWithInput:(id)input
                               callback:(NSObject *)callback
                               selector:(SEL)selector;

@end
