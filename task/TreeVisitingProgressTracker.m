#import "TreeVisitingProgressTracker.h"

@interface TreeVisitingProgressTracker (PrivateMethods)

- (void) processedOrSkippedFolder: (DirectoryItem *)dirItem;

@end

@implementation TreeVisitingProgressTracker

- (void) _processingFolder: (DirectoryItem *)dirItem {
  [super _processingFolder: dirItem];

  if (level <= NUM_PROGRESS_ESTIMATE_LEVELS) {
    numFiles[level - 1] = [dirItem numFiles];
    numFilesProcessed[level - 1] = 0;
  }
}

- (void) _processedFolder: (DirectoryItem *)dirItem {
  [super _processedFolder: dirItem];
  [self processedOrSkippedFolder: dirItem];
}

- (void) _skippedFolder: (DirectoryItem *)dirItem {
  [super _skippedFolder: dirItem];
  [self processedOrSkippedFolder: dirItem];
}

- (float) estimatedProgress {
  if (level == 0) {
    // Abort to avoid dividing by uninitialized numFiles[0]
    return 0;
  }

  NSUInteger i = 0;
  NSUInteger max_i = MIN(level, NUM_PROGRESS_ESTIMATE_LEVELS - 1);
  FILE_COUNT totalFilesProcessed = 0;
  while (i < max_i) {
    totalFilesProcessed += numFilesProcessed[i];
    i++;
  }
  float progress = 100.0 * totalFilesProcessed / numFiles[0];
  NSAssert(progress >= 0, @"Progress should be positive");
  NSAssert(progress <= 100, @"Progress should be less than 100");

  return progress;
}

@end


@implementation TreeVisitingProgressTracker (PrivateMethods)

- (void) processedOrSkippedFolder: (DirectoryItem *)dirItem {
  if (level > 0 && level <= NUM_PROGRESS_ESTIMATE_LEVELS) {
    numFilesProcessed[level - 1] += [dirItem numFiles];

    NSAssert(numFilesProcessed[level - 1] <= numFiles[level - 1],
             @"More files processed than expected.");
  }
}

@end
