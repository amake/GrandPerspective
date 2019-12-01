#import "TreeWriter.h"

#import "DirectoryItem.h"
#import "CompoundItem.h"

#import "ApplicationError.h"

#import "TreeVisitingProgressTracker.h"

// Formatting string used in XML (RFC 3339)
NSString  *DateTimeFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'";

// Localized error messages
#define WRITING_LAST_DATA_FAILED \
NSLocalizedString(@"Failed to write last data to file.", @"Error message")
#define WRITING_BUFFER_FAILED \
NSLocalizedString(@"Failed to write entire buffer.", @"Error message")

#define  BUFFER_SIZE  4096 * 16

@implementation TreeWriter

- (instancetype) init {
  if (self = [super init]) {
    abort = NO;
    error = nil;

    progressTracker = [[TreeVisitingProgressTracker alloc] init];

    dataBuffer = malloc(BUFFER_SIZE);
  }
  return self;
}

- (void) dealloc {
  [error release];

  [progressTracker release];

  free(dataBuffer);

  [super dealloc];
}

- (BOOL) writeTree:(AnnotatedTreeContext *)tree toFile:(NSString *)filename {
  NSAssert(file == NULL, @"File not NULL");

  [progressTracker startingTask];

  file = fopen( filename.UTF8String, "w");
  if (file == NULL) {
    return NO;
  }

  dataBufferPos = 0;

  [self writeTree: tree];

  if (error==nil && dataBufferPos > 0) {
    // Write remaining characters in buffer
    NSUInteger  numWritten = fwrite( dataBuffer, 1, dataBufferPos, file );

    if (numWritten != dataBufferPos) {
      NSLog(@"Failed to write last data: %lu bytes written out of %lu.",
            (unsigned long)numWritten, (unsigned long)dataBufferPos);

      error = [[ApplicationError alloc] initWithLocalizedDescription: WRITING_LAST_DATA_FAILED];
    }
  }

  fclose(file);
  file = NULL;

  [progressTracker finishedTask];

  return (error==nil) && !abort;
}

- (void) writeTree:(AnnotatedTreeContext *)tree {
  NSAssert(NO, @"This method should be overridden.");
}

- (void) abort {
  abort = YES;
}

- (BOOL) aborted {
  return (error==nil) && abort;
}

- (NSError *)error {
  return error;
}

- (NSDictionary *)progressInfo {
  return [progressTracker progressInfo];
}

@end // @implementation TreeWriter


@implementation TreeWriter (ProtectedMethods)

+ (NSDateFormatter *)nsTimeFormatter {
  static NSDateFormatter *timeFmt = nil;
  if (timeFmt == nil) {
    timeFmt = [[NSDateFormatter alloc] init];
    timeFmt.locale = [NSLocale localeWithLocaleIdentifier: @"en_US_POSIX"];
    timeFmt.dateFormat = DateTimeFormat;
    timeFmt.timeZone = [NSTimeZone timeZoneForSecondsFromGMT: 0];
  }
  return timeFmt;
}

+ (NSString *)stringForTime:(CFAbsoluteTime)time {
  if (time == 0) {
    return nil;
  } else {
    return [[self nsTimeFormatter] stringFromDate:
            [NSDate dateWithTimeIntervalSinceReferenceDate: time]];
  }
}

- (void) appendString:(NSString *)s {
  if (error != nil) {
    // Don't write anything when an error has occurred.
    //
    // Note: Still keep writing if "only" the abort flag is set. This way, an
    // external "abort" of the write operation still results in valid XML.
    return;
  }

  NSData  *newData = [s dataUsingEncoding: NSUTF8StringEncoding];
  const void  *newDataBytes = newData.bytes;
  NSUInteger  numToAppend = newData.length;
  NSUInteger  newDataPos = 0;

  while (numToAppend > 0) {
    NSUInteger  numToCopy = ( (dataBufferPos + numToAppend <= BUFFER_SIZE)
                             ? numToAppend
                             : BUFFER_SIZE - dataBufferPos );

    memcpy( dataBuffer + dataBufferPos, newDataBytes + newDataPos, numToCopy );
    dataBufferPos += numToCopy;
    newDataPos += numToCopy;
    numToAppend -= numToCopy;

    if (dataBufferPos == BUFFER_SIZE) {
      NSUInteger  numWritten = fwrite( dataBuffer, 1, BUFFER_SIZE, file );

      if (numWritten != BUFFER_SIZE) {
        NSLog(@"Failed to write entire buffer, %lu bytes written", (unsigned long)numWritten);

        error = [[ApplicationError alloc] initWithLocalizedDescription: WRITING_BUFFER_FAILED];
        abort = YES;

        return; // Do not attempt anymore writes to file.
      }

      dataBufferPos = 0;
    }
  }
}

- (void) dumpItemContents:(Item *)item {
  if (abort) {
    return;
  }

  if ([item isVirtual]) {
    [self dumpItemContents: ((CompoundItem *)item).first];
    [self dumpItemContents: ((CompoundItem *)item).second];
  }
  else {
    FileItem  *fileItem = (FileItem *)item;

    if ([fileItem isPhysical]) {
      // Only include actual files.

      if ([fileItem isDirectory]) {
        [self appendFolderElement: (DirectoryItem *)fileItem];
      }
      else {
        [self appendFileElement: fileItem];
      }
    }
  }
}

- (void) appendFolderElement:(DirectoryItem *)dirItem {
  NSAssert(NO, @"This method should be overridden.");
}

- (void) appendFileElement:(FileItem *)fileItem {
  NSAssert(NO, @"This method should be overridden.");
}

@end // @implementation TreeWriter (ProtectedMethods)
