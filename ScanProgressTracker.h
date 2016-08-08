#import "ProgressTracker.h"

// The number of levels that's taken into account in the progress estimate.
#define NUM_SIGNIFANT_SCAN_LEVELS 8

/* Basic progress tracker for the ScanTask. It estimates progress based on the
 * number of sub-folders it has to scan for a given parent folder and the number
 * of sub-folders scanned so far. It assumes that each sub-folder requires the
 * same time, which is the main reason why it is not very accurate.
 */
@interface ScanProgressTracker : ProgressTracker {

  int  numSubFolders[NUM_SIGNIFANT_SCAN_LEVELS];
  int  numSubFoldersProcessed[NUM_SIGNIFANT_SCAN_LEVELS];
}

/* Called by scanning task to indicate how many sub-folders the current folder
 * has. It should be called before descending into any of these sub-folders.
 */
- (void) setNumSubFolders: (int)numSubFolders;

@end
