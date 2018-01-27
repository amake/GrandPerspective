#import "TreeFilter.h"

#import "TreeConstants.h"
#import "PlainFileItem.h"
#import "ScanTreeRoot.h"
#import "CompoundItem.h"
#import "TreeContext.h"
#import "FilterSet.h"
#import "FilteredTreeGuide.h"
#import "TreeBalancer.h"

#import "TreeVisitingProgressTracker.h"


@interface TreeFilter (PrivateMethods)

- (void) filterItemTree:(DirectoryItem *)oldDirItem
                   into:(DirectoryItem *)newDirItem;

- (void) flattenAndFilterSiblings:(Item *)item
                   directoryItems:(NSMutableArray *)dirItems
                        fileItems:(NSMutableArray *)fileItems;

- (void) flattenAndFilterSiblings: (Item *)item;

@end // @interface TreeFilter (PrivateMethods)


@implementation TreeFilter

- (id) initWithFilterSet:(FilterSet *)filterSetVal {
  if (self = [super init]) {
    filterSet = [filterSetVal retain];

    treeGuide = [[FilteredTreeGuide alloc] initWithFileItemTest: [filterSet fileItemTest]];
    treeBalancer = [[TreeBalancer alloc] init];
    
    abort = NO;
    
    progressTracker = [[TreeVisitingProgressTracker alloc] init];

    tmpDirItems = nil;
    tmpFileItems = nil;
  }

  return self;
}

- (void) dealloc {
  [filterSet release];
  [treeGuide release];
  [treeBalancer release];

  [progressTracker release];
  
  [super dealloc];
}


- (BOOL) packagesAsFiles {
  return [treeGuide packagesAsFiles];
}

- (void) setPackagesAsFiles:(BOOL) flag {
  [treeGuide setPackagesAsFiles: flag];
}


- (TreeContext *)filterTree: (TreeContext *)oldTree {
  TreeContext  *filterResult =
    [[[TreeContext alloc] initWithVolumePath: [[oldTree volumeTree] systemPath]
                             fileSizeMeasure: [oldTree fileSizeMeasure]
                                  volumeSize: [oldTree volumeSize]
                                   freeSpace: [oldTree freeSpace]
                                   filterSet: filterSet] autorelease];

  DirectoryItem  *oldScanTree = [oldTree scanTree];
  DirectoryItem  *scanTree = [ScanTreeRoot allocWithZone: [Item zoneForTree]];
  [[scanTree initWithLabel: [oldScanTree label]
                    parent: [filterResult scanTreeParent]
                     flags: [oldScanTree fileItemFlags]
              creationTime: [oldScanTree creationTime]
          modificationTime: [oldScanTree modificationTime]
                accessTime: [oldScanTree accessTime]
    ] autorelease];

  [progressTracker startingTask];
  
  [self filterItemTree: oldScanTree into: scanTree];

  [progressTracker finishedTask];

  [filterResult setScanTree: scanTree];
                 
  return abort ? nil : filterResult;
}

- (void) abort {
  abort = YES;
}


- (NSDictionary *) progressInfo {
  return [progressTracker progressInfo];
}

@end


@implementation TreeFilter (PrivateMethods)

- (void) filterItemTree:(DirectoryItem *)oldDir into:(DirectoryItem *)newDir {
  NSMutableArray  *dirs = [[NSMutableArray alloc] initWithCapacity: INITIAL_DIRS_CAPACITY];
  NSMutableArray  *files = [[NSMutableArray alloc] initWithCapacity: INITIAL_FILES_CAPACITY];
  
  [treeGuide descendIntoDirectory: newDir];
  [progressTracker processingFolder: oldDir];

  [self flattenAndFilterSiblings: [oldDir getContents] directoryItems: dirs fileItems: files];

  if (!abort) { // Break recursion when task has been aborted.
    NSUInteger  i;
  
    // Collect all file items that passed the test
    for (i = [files count]; i-- > 0; ) {
      PlainFileItem  *oldFile = [files objectAtIndex: i];
      PlainFileItem  *newFile = (PlainFileItem *)[oldFile duplicateFileItem: newDir];
      
      [files replaceObjectAtIndex: i withObject: newFile];
    }
  
    // Filter the contents of all directory items
    for (i = [dirs count]; i-- > 0; ) {
      DirectoryItem  *oldSubDir = [dirs objectAtIndex: i];
      DirectoryItem  *newSubDir = (DirectoryItem *)[oldSubDir duplicateFileItem: newDir];
      
      [self filterItemTree: oldSubDir into: newSubDir];
    
      if (! abort) {
        // Check to prevent inserting corrupt tree when filtering was aborted.
        
        [dirs replaceObjectAtIndex: i withObject: newSubDir];
      }
    }
  
    [newDir setDirectoryContents: 
      [CompoundItem compoundItemWithFirst: [treeBalancer createTreeForItems: files]
                                   second: [treeBalancer createTreeForItems: dirs]]];
  }
  
  [treeGuide emergedFromDirectory: newDir];
  [progressTracker processedFolder: oldDir];
  
  [dirs release];
  [files release];
}


- (void) flattenAndFilterSiblings:(Item *)item
                   directoryItems:(NSMutableArray *)dirItems
                        fileItems:(NSMutableArray *)fileItems {
  if (item == nil) {
    // All done.
    return;
  }

  NSAssert(tmpDirItems==nil && tmpFileItems==nil, @"Helper arrays already in use?");
  
  tmpDirItems = dirItems;
  tmpFileItems = fileItems;
  
  [self flattenAndFilterSiblings: item];
  
  tmpDirItems = nil;
  tmpFileItems = nil;
}

- (void) flattenAndFilterSiblings: (Item *)item {
  if (abort) {
    return;
  }

  if ([item isVirtual]) {
    [self flattenAndFilterSiblings: [((CompoundItem*)item) getFirst]];
    [self flattenAndFilterSiblings: [((CompoundItem*)item) getSecond]];
  }
  else {
    FileItem  *fileItem = (FileItem *)item;
    
    if ( [treeGuide includeFileItem: fileItem] ) {
      if ( [fileItem isDirectory] ) {
        [tmpDirItems addObject: fileItem];
      }
      else {
        [tmpFileItems addObject: fileItem];
      }
    }
    else {
      if ( [fileItem isDirectory] ) {
        [progressTracker skippedFolder: (DirectoryItem *)fileItem];
      }
    }
  }
}

@end
