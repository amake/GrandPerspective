#import <Cocoa/Cocoa.h>


extern NSString  *NumFoldersProcessedKey;
extern NSString  *NumFoldersSkippedKey;
extern NSString  *CurrentFolderPathKey;
extern NSString  *EstimatedProgressKey;


@class DirectoryItem;


/* The number of recursion levels to take into account in the progress estimates. There's
 * diminishing returns for each extra level, so it makes sense to bound it. This constant is not
 * actually used for the base class, but used by various of its subclasses.
 */
#define NUM_PROGRESS_ESTIMATE_LEVELS 8


/* Maintains progress statistics when processing a folder hierarchy.
 *
 * Note: This class is thread-safe.
 */
@interface ProgressTracker : NSObject {

  // Lock protecting the progress statistics (which can be retrieved from a thread different than
  // the one carrying out the task).
  NSLock  *mutex;
  
  // The number of folders that have been processed so far.
  NSUInteger  numFoldersProcessed;

  // The number of folders that have been skipped so far.
  NSUInteger  numFoldersSkipped;
  
  // The recursion level.
  NSUInteger  level;
   
  // The stack of directories that are being processed.
  NSMutableArray  *directoryStack;
}

/* Called to signal that a new task is about to be carried out. The progress statistics are reset.
 */
- (void) startingTask;

/* Called to signal that the task has finished.
 */
- (void) finishedTask;


/* Called to signal that a new folder is being processed.
 */
- (void) processingFolder: (DirectoryItem *)dirItem;

/* Called to signal that a folder has been processed completely.
 */
- (void) processedFolder: (DirectoryItem *)dirItem;

/* Called to signal that a folder is skipped. I.e. it is encountered, but not processed.
 */
- (void) skippedFolder: (DirectoryItem *)dirItem;

/* Returns a dictionary with progress statistics. This thread-safe and can be invoked from a
 * different thread than the one that carries out the task.
 */
@property (nonatomic, readonly, copy) NSDictionary *progressInfo;

/* Returns the number of folders processed sofar. This method is not thread-safe and should only be
 * invoked from the thread that does the processing.
 */
@property (nonatomic, readonly) NSUInteger numFoldersProcessed;

@end

@interface ProgressTracker (ProtectedMethods)

/* Invoked by processingFolder. Can be overridden. It can be assumed that the caller will have
 * obtained the mutex lock.
 */
- (void) _processingFolder:(DirectoryItem *)dirItem;

/* Invoked by processedFolder. Can be overridden. It can be assumed that the caller will have
 * obtained the mutex lock.
 */
- (void) _processedFolder:(DirectoryItem *)dirItem;

/* Invoked by skippedFolder. Can be overridden. It can be assumed that the caller will have obtained
 * the mutex lock.
 */
- (void) _skippedFolder:(DirectoryItem *)dirItem;

/* The estimated progress. It ranges from 0 (no progress yet) to 100 (done).
 *
 * It is meant to be overridden and should only be used by the base class in response to a call to
 * progressInfo:. It can be assumed that the caller will have obtained the mutex lock, so this does
 * not need to be obtained here.
 */
@property (nonatomic, readonly) float estimatedProgress;

@end
