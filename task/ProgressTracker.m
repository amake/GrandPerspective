#import "ProgressTracker.h"

#import "DirectoryItem.h"


NSString  *NumFoldersProcessedKey = @"numFoldersProcessed";
NSString  *NumFoldersSkippedKey = @"numFoldersSkipped";
NSString  *CurrentFolderPathKey = @"currentFolderPath";
NSString  *EstimatedProgressKey = @"estimatedProgress";


@implementation ProgressTracker

- (id) init {
  if (self = [super init]) {
    mutex = [[NSLock alloc] init];
    directoryStack = [[NSMutableArray alloc] initWithCapacity: 16];
  }

  return self;
}

- (void) dealloc {
  [mutex release];
  [directoryStack release];
  
  [super dealloc];

}

- (void) startingTask {
  [mutex lock];
  numFoldersProcessed = 0;
  numFoldersSkipped = 0;
  level = 0;
  [directoryStack removeAllObjects];
  [mutex unlock];
}

- (void) finishedTask {
  [mutex lock];
  [directoryStack removeAllObjects];
  [mutex unlock];
}


- (void) processingFolder:(DirectoryItem *)dirItem {
  [mutex lock];
  [self _processingFolder: dirItem];
  [mutex unlock];
}

- (void) processedFolder:(DirectoryItem *)dirItem {
  [mutex lock];
  [self _processedFolder: dirItem];
  [mutex unlock];
}

- (void) skippedFolder:(DirectoryItem *)dirItem {
  [mutex lock];
  [self _skippedFolder: dirItem];
  [mutex unlock];
}


- (NSDictionary *)progressInfo {
  NSDictionary  *dict;

  [mutex lock];
  dict = [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithUnsignedInteger: numFoldersProcessed],
            NumFoldersProcessedKey,
            [NSNumber numberWithUnsignedInteger: numFoldersSkipped],
            NumFoldersSkippedKey,
            [[directoryStack lastObject] path],
            CurrentFolderPathKey,
            [NSNumber numberWithFloat: [self estimatedProgress]],
            EstimatedProgressKey,
            nil];
  [mutex unlock];

  return dict;
}

- (NSUInteger) numFoldersProcessed {
  return numFoldersProcessed;
}

@end // @implementation ProgressTracker


@implementation ProgressTracker (ProtectedMethods)

- (void) _processingFolder:(DirectoryItem *)dirItem {
  if ([directoryStack count] == 0) {
    // Find the root of the tree
    DirectoryItem  *root = dirItem;
    DirectoryItem  *parent = nil;
    while ((parent = [root parentDirectory]) != nil) {
      root = parent;
    }

    if (root != dirItem) {
      // Add the root of the tree to the stack. This ensures that -path can be
      // called for any FileItem in the stack, even after the tree has been
      // released externally (e.g. because the task constructing it has been
      // aborted).
      [directoryStack addObject: root];
    }
  }

  [directoryStack addObject: dirItem];
  level++;
}

- (void) _processedFolder:(DirectoryItem *)dirItem {
  NSAssert([directoryStack lastObject] == dirItem, @"Inconsistent stack.");
  [directoryStack removeLastObject];
  numFoldersProcessed++;
  level--;
}

- (void) _skippedFolder:(DirectoryItem *)dirItem {
  numFoldersSkipped++;
}

/* Default implementation, fixed to zero. Without more detailed knowledge about
 * the task, it is not feasible to estimate progress accurately.
 */
- (float) estimatedProgress {
  return 0.0;
}

@end
