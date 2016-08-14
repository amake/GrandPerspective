#import "ProgressTracker.h"

@interface ReadProgressTracker : ProgressTracker {
  // The total number of lines in the input file
  NSInteger  totalLines;

  // The number of lines processed sofar.
  NSInteger  processedLines;
}

/* This method should be called by the task, from its background thread, before
 * it starts processing the input data.
 */
- (void) startingTaskOnInputData: (NSData *)inputData;

- (void) processingFolder: (DirectoryItem *)dirItem
           processedLines: (NSInteger)numProcessed;

@end
