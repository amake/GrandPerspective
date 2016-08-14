#import "ReadProgressTracker.h"

#define READ_BUFFER_SIZE  4096


@implementation ReadProgressTracker

- (id) init {
  if (self = [super init]) {
    totalLines = 0;
    processedLines = 0;
  }

  return self;
}

- (void) startingTaskOnInputData: (NSData *)inputData {
  // Determine the total number of lines in the input data
  char  buffer[READ_BUFFER_SIZE];
  unsigned  pos = 0;

  // For better performance on large input data, read only complete blocks in
  // the main loop.
  unsigned  numBlocks = [inputData length] / READ_BUFFER_SIZE;
  unsigned  maxpos = numBlocks * READ_BUFFER_SIZE;
  while (pos < maxpos) {
    [inputData getBytes: (void *)buffer
                  range: NSMakeRange(pos, READ_BUFFER_SIZE)];
    int  i = READ_BUFFER_SIZE;
    while (i--) {
      // Note: Even though input is in UTF-8, which can contain multi-byte
      // characters, the nature of the encoding ensures that each byte
      // corresponding to an ASCII character is indeed one.
      if (buffer[i]=='\n') {
        totalLines++;
      }
    }

    pos += READ_BUFFER_SIZE;
  }

  // Read the last, partially filled, block, if any.
  int  i = [inputData length] - pos;
  if (i > 0) {
    [inputData getBytes: (void *)buffer range: NSMakeRange(pos, i)];
    while (i--) {
      if (buffer[i]=='\n') {
        totalLines++;
      }
    }
  }

  NSLog(@"totalLines = %ld", (long)totalLines);
}


- (void) processingFolder: (DirectoryItem *)dirItem
           processedLines: (NSInteger)numProcessed {
  [mutex lock];

  // For efficiency, call internal method that assumes mutex has been locked.
  [self _processingFolder: dirItem];

  NSAssert(numProcessed <= totalLines,
           @"More lines processed than expected (%ld > %ld).",
           (long)numProcessed,
           (long)totalLines);
  processedLines = numProcessed;

  [mutex unlock];
}


- (float) estimatedProgress {
  if (totalLines == 0) {
    return 0;
  } else {
    return 100.0 * processedLines / totalLines;
  }
}

@end
