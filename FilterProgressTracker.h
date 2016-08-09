#import "Item.h"
#import "ProgressTracker.h"

/* Basic progress tracker for the FilterTask. It estimates progress based on
 * the number of files processed so-far given the total number of files to
 * process. As it works on an existing tree, the estimates are quite accurate.
 * The main inaccuracies are caused when the filter causes large folders of the
 * input tree to be skipped.
 */
@interface FilterProgressTracker : ProgressTracker {
  // The number of files in the input tree at each level
  FILE_COUNT  numFiles[NUM_PROGRESS_ESTIMATE_LEVELS];

  // The number of processed files in the input tree at each level
  FILE_COUNT  numFilesProcessed[NUM_PROGRESS_ESTIMATE_LEVELS];
}
@end
