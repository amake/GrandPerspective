#import <Cocoa/Cocoa.h>

#import "TaskExecutor.h"

@class TreeWriter;

@interface WriteTaskExecutor : NSObject <TaskExecutor> {
  TreeWriter  *treeWriter;
  
  NSLock  *taskLock;
}

/* Returns a dictionary with info about the progress of the write task that is currently being
 * executed (or nil if there is none). The keys in the dictionary are those used by ProgressTracker.
 */
@property (nonatomic, readonly, copy) NSDictionary *progressInfo;

/* Abstract method that should create the tree writer to use.
 */
- (TreeWriter *)createTreeWriter;

@end

@interface RawWriteTaskExecutor : WriteTaskExecutor {
}

/* Creates a RawTreeWriter.
 */
- (TreeWriter *)createTreeWriter;

@end

@interface XmlWriteTaskExecutor : WriteTaskExecutor {
}

/* Creates an XmlTreeWriter.
 */
- (TreeWriter *)createTreeWriter;

@end
