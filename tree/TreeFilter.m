#import "TreeFilter.h"

#import "TreeConstants.h"
#import "PlainFileItem.h"
#import "DirectoryItem.h"
#import "CompoundItem.h"
#import "TreeContext.h"
#import "FilteredTreeGuide.h"
#import "TreeBalancer.h"

@interface TreeFilter (PrivateMethods)

- (void) filterItemTree: (DirectoryItem *)oldDirItem 
           into: (DirectoryItem *)newDirItem;

- (void) flattenAndFilterSiblings: (Item *)item
           directoryItems: (NSMutableArray *)dirItems
                fileItems: (NSMutableArray *)fileItems;

- (void) flattenAndFilterSiblings: (Item *)item;

@end // @interface TreeFilter (PrivateMethods)


@implementation TreeFilter

- (id) initWithFilteredTreeGuide: (FilteredTreeGuide *)treeGuideVal {
  if (self = [super init]) {
    treeGuide = [treeGuideVal retain];    
    treeBalancer = [[TreeBalancer alloc] init];
    
    abort = NO;
    
    statsLock = [[NSLock alloc] init];
    directoryStack = [[NSMutableArray alloc] initWithCapacity: 16];

    tmpDirItems = nil;
    tmpFileItems = nil;
  }

  return self;
}

- (void) dealloc {
  [treeGuide release];
  [treeBalancer release];

  [statsLock release];
  [directoryStack release];
  
  [super dealloc];
}

- (TreeContext *)filterTree: (TreeContext *)oldTree {
  TreeContext  *filterResult = 
    [oldTree contextAfterFiltering: [treeGuide fileItemTest]];

  [statsLock lock];
  numFoldersProcessed = 0;
  [directoryStack removeAllObjects];
  [statsLock unlock];
  
  [self filterItemTree: [oldTree scanTree] into: [filterResult scanTree]];
          
  [filterResult postInit];
                 
  return abort ? nil : filterResult;
}

- (void) abort {
  abort = YES;
}


- (NSDictionary *) treeFilterProgressInfo {
  NSDictionary  *dict;

  [statsLock lock];
  dict = [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithInt: numFoldersProcessed],
            NumFoldersProcessedKey,
            [[directoryStack lastObject] path],
            CurrentFolderPathKey,
            nil];
  [statsLock unlock];

  return dict;
}

@end


@implementation TreeFilter (PrivateMethods)

- (void) filterItemTree: (DirectoryItem *)oldDir 
           into: (DirectoryItem *)newDir {
  NSMutableArray  *dirs = 
    [[NSMutableArray alloc] initWithCapacity: INITIAL_DIRS_CAPACITY];
  NSMutableArray  *files = 
    [[NSMutableArray alloc] initWithCapacity: INITIAL_FILES_CAPACITY];
  
  [treeGuide descendIntoDirectory: newDir];

  [statsLock lock];
  [directoryStack addObject: newDir];
  [statsLock unlock];

  [self flattenAndFilterSiblings: [oldDir getContents] 
          directoryItems: dirs fileItems: files];

  if (!abort) { // Break recursion when task has been aborted.
    int  i;
  
    // Collect all file items that passed the test
    for (i = [files count]; --i >= 0; ) {
      PlainFileItem  *oldFile = [files objectAtIndex: i];
      PlainFileItem  *newFile = 
        (PlainFileItem *)[oldFile duplicateFileItem: newDir];
      
      [files replaceObjectAtIndex: i withObject: newFile];
    }
  
    // Filter the contents of all directory items
    for (i = [dirs count]; --i >= 0; ) {
      DirectoryItem  *oldSubDir = [dirs objectAtIndex: i];
      DirectoryItem  *newSubDir = 
        (DirectoryItem *)[oldSubDir duplicateFileItem: newDir];
      
      [self filterItemTree: oldSubDir into: newSubDir];
    
      if (! abort) {
        // Check to prevent inserting corrupt tree when filtering was aborted.
        
        [dirs replaceObjectAtIndex: i withObject: newSubDir];
      }
    }
  
    [newDir setDirectoryContents: 
      [CompoundItem 
         compoundItemWithFirst: [treeBalancer createTreeForItems: files] 
                        second: [treeBalancer createTreeForItems: dirs]]];
  }
  
  [treeGuide emergedFromDirectory: newDir];
  
  [statsLock lock];
  NSAssert([directoryStack lastObject] == newDir, @"Inconsistent stack.");
  [directoryStack removeLastObject];
  numFoldersProcessed++;
  [statsLock unlock];

  [dirs release];
  [files release];
}


- (void) flattenAndFilterSiblings: (Item *)item
           directoryItems:(NSMutableArray *)dirItems
                fileItems:(NSMutableArray *)fileItems {
  if (item == nil) {
    // All done.
    return;
  }

  NSAssert(tmpDirItems==nil && tmpFileItems==nil, 
             @"Helper arrays already in use?");
  
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
  }
}

@end