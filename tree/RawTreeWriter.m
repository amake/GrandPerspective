#import "RawTreeWriter.h"

#import "PlainFileItem.h"
#import "DirectoryItem.h"
#import "CompoundItem.h"

#import "UniformType.h"

#import "TreeContext.h"
#import "AnnotatedTreeContext.h"

#import "TreeVisitingProgressTracker.h"


#define  AUTORELEASE_PERIOD  1024

@implementation RawTreeWriter

- (instancetype) init {
  if (self = [super init]) {
    autoreleasePool = nil;
  }
  return self;
}

- (void) dealloc {
  NSAssert(autoreleasePool == nil, @"autoreleasePool should be nil");

  [super dealloc];
}

- (void) writeTree:(AnnotatedTreeContext *)annotatedTree options:(id)optionsVal {
  options = optionsVal;

  TreeContext  *tree = [annotatedTree treeContext];
  [self appendFolderElement: [tree scanTree]];

  [autoreleasePool release];
  autoreleasePool = nil;
}

@end


@implementation RawTreeWriter (ProtectedMethods)

- (void) appendFolderElement:(DirectoryItem *)dirItem {
  [progressTracker processingFolder: dirItem];

  [self dumpItemContents: dirItem.contents];

  [progressTracker processedFolder: dirItem];
  if ([progressTracker numFoldersProcessed] % AUTORELEASE_PERIOD == 0) {
    // Flush auto-release pool to prevent high memory usage while writing is in progress.
    [autoreleasePool release];
    autoreleasePool = [[NSAutoreleasePool alloc] init];
  }
}

- (void) appendFileElement:(PlainFileItem *)fileItem {
  RawTreeColumnFlags  columnFlag = 0x01;
  BOOL  isFirst = YES;

  while (columnFlag <= ColumnAccessTime) {
    if ([options isColumnShown: columnFlag]) {
      if (!isFirst) {
        [self appendString: @"\t"];
      }

      switch (columnFlag) {
        case ColumnPath:
          [self appendString: [fileItem path]];
          break;
        case ColumnName:
          [self appendString: [fileItem label]];
          break;
        case ColumnSize:
          [self appendString: [NSString stringWithFormat: @"%qu", [fileItem itemSize]]];
          break;
        case ColumnType:
          [self appendString: [[fileItem uniformType] uniformTypeIdentifier]];
          break;
        case ColumnCreationTime:
          [self appendString: [TreeWriter stringForTime: [fileItem creationTime]]];
          break;
        case ColumnModificationTime:
          [self appendString: [TreeWriter stringForTime: [fileItem modificationTime]]];
          break;
        case ColumnAccessTime:
          [self appendString: [TreeWriter stringForTime: [fileItem accessTime]]];
          break;
      }

      isFirst = NO;
    }

    columnFlag <<= 1;
  }

  [self appendString: @"\n"];
}

@end
