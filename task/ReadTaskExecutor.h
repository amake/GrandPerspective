#import <Cocoa/Cocoa.h>

#import "TaskExecutor.h"

@class TreeReader;


extern NSString  *ReadTaskAbortedEvent;

@interface ReadTaskExecutor : NSObject <TaskExecutor> {
  TreeReader  *treeReader;
  
  NSLock  *taskLock;
}

/* Returns a dictionary with info about the progress of the read task that is currently being
 * executed (or nil if there is none). The keys in the dictionary are those used by ProgressTracker.
 */
@property (nonatomic, readonly, copy) NSDictionary *progressInfo;

@end
