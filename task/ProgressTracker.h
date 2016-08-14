#import <Cocoa/Cocoa.h>


extern NSString  *NumFoldersProcessedKey;
extern NSString  *NumFoldersSkippedKey;
extern NSString  *CurrentFolderPathKey;
extern NSString  *EstimatedProgressKey;


@class DirectoryItem;


/* Maintains progress statistics when processing a folder hierarchy.
 *
 * Note: This class is thread-safe.
 */
@interface ProgressTracker : NSObject {

  // Lock protecting the progress statistics (which can be retrieved from a
  // thread different than the one carrying out the task).
  NSLock  *mutex;
  
  // The number of folders that have been processed so far.
  int  numFoldersProcessed;

  // The number of folders that have been skipped so far.
  int  numFoldersSkipped;
   
  // The stack of directories that are being processed.
  NSMutableArray  *directoryStack;
}

/* Called to signal that a new task is about to be carried out. The progress
 * statistics are reset.
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

/* Called to signal that a folder is skipped. I.e. it is encountered, but not
 * processed.
 */
- (void) skippedFolder: (DirectoryItem *)dirItem;

/* Returns a dictionary with progress statistics.
 */
- (NSDictionary *)progressInfo;

@end

@interface ProgressTracker (ProtectedMethods)

/* The estimated progress. It ranges from 0 (no progress yet) to 100 (done).
 */
- (float) estimatedProgress;

@end
