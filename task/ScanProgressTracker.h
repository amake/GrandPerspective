#import "ProgressTracker.h"

/* Basic progress tracker for the ScanTask. It estimates progress based on the
 * number of sub-folders it has to scan for a given parent folder and the number
 * of sub-folders scanned so far. It assumes that each sub-folder requires the
 * same time, which is the main reason why it is not very accurate.
 */
@interface ScanProgressTracker : ProgressTracker {
  // The number of sub-folders at each level.
  NSUInteger  numSubFolders[NUM_PROGRESS_ESTIMATE_LEVELS];

  // The number of sub-folders processed sofar at each level.
  NSUInteger  numSubFoldersProcessed[NUM_PROGRESS_ESTIMATE_LEVELS];
}

/* Called by the scanning task to indicate how many sub-folders the current
 * folder has. It should be called before descending into any of these
 * sub-folders.
 */
- (void) setNumSubFolders: (NSUInteger)numSubFolders;

@end
