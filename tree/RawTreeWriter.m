#import "RawTreeWriter.h"

#import "DirectoryItem.h"
#import "CompoundItem.h"

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

- (void) writeTree:(AnnotatedTreeContext *)annotatedTree {
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

- (void) appendFileElement:(FileItem *)fileItem {
  [self appendString: [NSString stringWithFormat: @"%@\t%qu\n",
                       [fileItem path],
                       [fileItem itemSize]]];
}

@end
