#import "ScanProgressTracker.h"

#import "DirectoryItem.h"

@interface ScanProgressTracker (PrivateMethods)

- (void) processedOrSkippedFolder:(DirectoryItem *)dirItem;

@end

@implementation ScanProgressTracker

// Override super's designated initialiser
- (instancetype) init {
  return [self initWithMaxLevel: NUM_PROGRESS_ESTIMATE_LEVELS];
}

// Designated initialiser
- (instancetype) initWithMaxLevel:(int)maxLevelsVal {
  if (self = [super init]) {
    maxLevels = maxLevelsVal;

    numSubFolders = (NSUInteger *) malloc(maxLevels * sizeof(NSUInteger));
    numSubFoldersProcessed = (NSUInteger *) malloc(maxLevels * sizeof(NSUInteger));
  }
  return self;
}

- (void) dealloc {
  free(numSubFolders);
  free(numSubFoldersProcessed);

  [super dealloc];
}

- (void) setNumSubFolders:(NSUInteger)num {
  [mutex lock];

  if (level <= maxLevels) {
    if (num > 0) {
      numSubFolders[level - 1] = num;
    } else {
      // Make both equal (and non-zero), to simplify calculation by estimatedProgress.
      numSubFoldersProcessed[level - 1] = numSubFolders[level - 1];
    }
  }

  [mutex unlock];
}

- (void) _processingFolder:(DirectoryItem *)dirItem {
  [super _processingFolder: dirItem];

  if (level <= maxLevels) {
    // Set to non-zero until actually set by setNumSubFolders, to simplify calculation by
    // estimatedProgress.
    numSubFolders[level - 1] = 1;
    numSubFoldersProcessed[level - 1] = 0;
  }
}

- (void) _processedFolder:(DirectoryItem *)dirItem {
  [super _processedFolder: dirItem];
  [self processedOrSkippedFolder: dirItem];
}

- (void) _skippedFolder:(DirectoryItem *)dirItem {
  [super _skippedFolder: dirItem];
  [self processedOrSkippedFolder: dirItem];
}

- (float) estimatedProgress {
  float progress = 0;
  float fraction = 100;
  NSUInteger i = 0;
  NSUInteger max_i = MIN(level, maxLevels);
  while (i < max_i) {
    progress += fraction * numSubFoldersProcessed[i] / numSubFolders[i];
    fraction /= numSubFolders[i];
    i++;
  }

  return progress;
}

@end


@implementation ScanProgressTracker (PrivateMethods)

- (void) processedOrSkippedFolder:(DirectoryItem *)dirItem {
  if (level > 0 && level <= maxLevels) {
    if (numSubFoldersProcessed[level - 1] < numSubFolders[level - 1]) {
      numSubFoldersProcessed[level - 1] += 1;
    } else {
      // This can happen if a new folder is created while the scan is in progress. Ignore it to
      // avoid overestimation of progress.
      NSLog(@"More sub-folders processed than expected at %@", [[dirItem parentDirectory] path]);
    }
  }
}

@end
