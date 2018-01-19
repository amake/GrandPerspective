#import "TreeContext.h"

#import "DirectoryItem.h"
#import "CompoundItem.h"

#import "ItemPathModel.h"
#import "ItemPathModelView.h"

#import "FilterSet.h"


NSString  *FreeSpace = @"free";
NSString  *UsedSpace = @"used";
NSString  *MiscUsedSpace = @"misc used";
NSString  *FreedSpace = @"freed";

NSString  *FileItemDeletedEvent = @"fileItemDeleted";
NSString  *FileItemDeletedHandledEvent = @"fileItemDeletedHandled";


#define IDLE      100
#define READING   101
#define WRITING   102


@interface TreeContext (PrivateMethods)

/* Returns the item that owns the selected file item, i.e. the one directly
 * above it in the tree. This can be a virtual item.
 */
- (Item *)itemContainingSelectedFileItem:(ItemPathModelView *)pathModelView;

// Signals that an item in the tree has been replaced (by another one, of the
// same size). The item itself is not part of the notification, but can be 
// recognized because its parent directory has been cleared.
- (void) postFileItemDeleted;
- (void) fileItemDeletedHandled:(NSNotification *)notification;

/* Recursively updates the freed space count after the given item has been
 * deleted.
 */
- (void) updateFreedSpaceForDeletedItem:(Item *)item;

@end


@implementation TreeContext

// Overrides designated initialiser
- (id) init {
  NSAssert(NO, @"Use initWithVolumePath:scanPath:fileSizeMeasure:... instead.");
  return nil;
}


- (id) initWithVolumePath: (NSString *)volumePath
          fileSizeMeasure: (NSString *)fileSizeMeasureVal
               volumeSize: (unsigned long long) volumeSizeVal 
                freeSpace: (unsigned long long) freeSpaceVal
                filterSet: (FilterSet *)filterSetVal {
  return [self initWithVolumePath: volumePath
                  fileSizeMeasure: fileSizeMeasureVal
                       volumeSize: volumeSizeVal 
                        freeSpace: freeSpaceVal
                        filterSet: filterSetVal 
                         scanTime: [NSDate date]];
}

- (id) initWithVolumePath: (NSString *)volumePath
          fileSizeMeasure: (NSString *)fileSizeMeasureVal
               volumeSize: (unsigned long long) volumeSizeVal 
                freeSpace: (unsigned long long) freeSpaceVal
                filterSet: (FilterSet *)filterSetVal
                 scanTime: (NSDate *)scanTimeVal {
  if (self = [super init]) {
    volumeTree = [[DirectoryItem alloc] initWithLabel: volumePath
                                               parent: nil
                                                flags: 0
                                         creationTime: 0
                                     modificationTime: 0
                                           accessTime: 0];
    
    usedSpaceItem = [[DirectoryItem alloc] initWithLabel: UsedSpace
                                                  parent: volumeTree
                                                   flags: FILE_IS_NOT_PHYSICAL
                                            creationTime: 0
                                        modificationTime: 0
                                              accessTime: 0];
    
    fileSizeMeasure = [fileSizeMeasureVal retain];
    volumeSize = volumeSizeVal;
    freeSpace = freeSpaceVal;
    freedSpace = 0;
    freedFiles = 0;
    
    scanTime = [scanTimeVal retain];

    // Ensure filter set is always set
    filterSet = 
      [ ((filterSetVal != nil) ? filterSetVal : [FilterSet filterSet])
          retain];

    // Listen to self
    [[NSNotificationCenter defaultCenter] 
        addObserver: self selector: @selector(fileItemDeletedHandled:)
        name: FileItemDeletedHandledEvent object: self];
        
    mutex = [[NSLock alloc] init];
    lock = [[NSConditionLock alloc] initWithCondition: IDLE];
    numReaders = 0;
    numWaitingReaders = 0;
    numWaitingWriters = 0;
  }
  
  return self;
}


- (void) dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver: self];

  [volumeTree release];
  [usedSpaceItem release];
  [scanTree release];
  
  [fileSizeMeasure release];
  [scanTime release];
  [filterSet release];
  
  [replacedItem release];
  [replacingItem release];
  
  [mutex release];
  [lock release];

  [super dealloc];
}


- (void) setScanTree:(DirectoryItem *)scanTreeVal {
  NSAssert(scanTree == nil, @"scanTree should be nil.");
  NSAssert([scanTreeVal parentDirectory] == [self scanTreeParent], 
             @"Invalid parent.");

  scanTree = [scanTreeVal retain];

  ITEM_SIZE  miscUsedSize = volumeSize;
  ITEM_SIZE  actualFreeSpace = freeSpace;
  BOOL  miscUsedSizeAnomaly = FALSE;
  if ([scanTree itemSize] <= volumeSize) {
    miscUsedSize -= [scanTree itemSize];

    if (freeSpace <= miscUsedSize) {
      miscUsedSize -= freeSpace;
    }
    else {
      NSLog(@"Scanned tree size plus free space is larger than volume size.");
      miscUsedSizeAnomaly = TRUE;

      // Adapt actual free space, so that size of volumeTree still adds up to
      // volume size.
      actualFreeSpace = miscUsedSize;
      miscUsedSize = 0;
    }
  } 
  else {
    NSLog(@"Scanned tree size is larger than volume size.");
    miscUsedSizeAnomaly = TRUE;

    // Set actual free space and misc used size both to zero to minimize
    // difference between claimed volume size and size of scanned items, which
    // appears to be larger.
    actualFreeSpace = 0;
    miscUsedSize = 0;
  }

  if (miscUsedSizeAnomaly) {
    NSLog(@"Volume size=%qu (%@), Free space=%qu (%@), Scanned size=%qu (%@)",
          volumeSize, [FileItem stringForFileItemSize: volumeSize],
          freeSpace, [FileItem stringForFileItemSize: freeSpace],
          [scanTree itemSize], [FileItem stringForFileItemSize: [scanTree itemSize]]);
  }

  FileItem*  freeSpaceItem = [[[FileItem alloc] initWithLabel: FreeSpace
                                                       parent: volumeTree
                                                         size: actualFreeSpace
                                                        flags: FILE_IS_NOT_PHYSICAL
                                                 creationTime: 0
                                             modificationTime: 0
                                                   accessTime: 0
                               ] autorelease];

  miscUsedSpaceItem = [[[FileItem alloc] initWithLabel: MiscUsedSpace
                                                parent: usedSpaceItem
                                                  size: miscUsedSize
                                                 flags: FILE_IS_NOT_PHYSICAL
                                          creationTime: 0
                                      modificationTime: 0
                                            accessTime: 0
                        ] autorelease];

  [usedSpaceItem setDirectoryContents: 
                   [CompoundItem compoundItemWithFirst: miscUsedSpaceItem
                                   second: scanTree]];
    
  [volumeTree setDirectoryContents: 
                [CompoundItem compoundItemWithFirst: freeSpaceItem
                                second: usedSpaceItem]];
}


- (DirectoryItem *)scanTreeParent {
  return usedSpaceItem;
}

- (DirectoryItem *)volumeTree {
  return volumeTree;
}

- (DirectoryItem *)scanTree {
  return scanTree;
}

- (unsigned long long) volumeSize {
  return volumeSize;
}

/* The free space of the volume at the time of the scan (as claimed by the
 * system). The free space in the volume tree may be less. The latter is
 * reduced if not doing so would cause the size of scanned files plus the free
 * space to be more than the volume size.
 */
- (unsigned long long) freeSpace {
  return freeSpace;
}

- (unsigned long long) miscUsedSpace {
  return [miscUsedSpaceItem itemSize];
}

- (unsigned long long) freedSpace {
  return freedSpace;
}

- (unsigned long long) freedFiles {
  return freedFiles;
}


- (NSString *)fileSizeMeasure {
  return fileSizeMeasure;
}


- (NSDate *)scanTime {
  return scanTime;
}

- (NSString *)stringForScanTime { 
  static NSDateFormatter *format = nil;
  if (format == nil) {
    format = [[NSDateFormatter alloc] init];
    [format setTimeStyle:NSDateFormatterMediumStyle];
    [format setDateStyle:NSDateFormatterMediumStyle];
  }
  return [format stringFromDate:scanTime];
}


- (FilterSet *)filterSet {
  return filterSet;
}


- (void) deleteSelectedFileItem:(ItemPathModelView *)pathModelView {
  NSAssert(replacedItem == nil, @"Replaced item not nil.");
  NSAssert(replacingItem == nil, @"Replacing item not nil.");
  
  replacedItem = [[pathModelView selectedFileItemInTree] retain]; 
  replacingItem = [[FileItem alloc] initWithLabel: FreedSpace
                                           parent: [replacedItem parentDirectory]
                                             size: [replacedItem itemSize]
                                            flags: FILE_IS_NOT_PHYSICAL
                                     creationTime: 0
                                 modificationTime: 0
                                       accessTime: 0];

  Item  *containingItem = [self itemContainingSelectedFileItem: pathModelView];
  
  [self obtainWriteLock];
  if ([containingItem isVirtual]) {
    CompoundItem  *compoundItem = (CompoundItem *)containingItem;
    
    if ([compoundItem getFirst] == replacedItem) {
      [compoundItem replaceFirst: replacingItem];
    }
    else if ([compoundItem getSecond] == replacedItem) {
      [compoundItem replaceSecond: replacingItem];
    }
    else {
      NSAssert(NO, @"Selected item not found.");
    }
  } 
  else {
    DirectoryItem  *dirItem = (DirectoryItem *)containingItem;
  
    NSAssert([dirItem isDirectory], @"Expected a DirectoryItem.");
    NSAssert([dirItem getContents] == replacedItem, 
               @"Selected item not found.");
    
    [dirItem replaceDirectoryContents: replacingItem];
  } 
  [self releaseWriteLock];
  
  [self updateFreedSpaceForDeletedItem: replacedItem];

  [self postFileItemDeleted];
}

- (FileItem *)replacedFileItem {
  NSAssert(replacedItem != nil, @"replacedFileItem is nil.");
  return replacedItem;
}

- (FileItem *)replacingFileItem {
  NSAssert(replacingItem != nil, @"replacingFileItem is nil.");
  return replacingItem;
}


- (void) obtainReadLock {
  BOOL  wait = NO;

  [mutex lock];
  if (numReaders > 0) {
    // Already in READING state
    numReaders++;
  }
  else if ([lock tryLockWhenCondition: IDLE]) {
    // Was in IDLE state, start reading
    numReaders++;
    [lock unlockWithCondition: READING];
  }
  else {
    // Currently in WRITE state, so will have to wait.
    numWaitingReaders++;
    wait = YES;
  }
  [mutex unlock];
  
  if (wait) {
    [lock lockWhenCondition: READING];
    // We are now allowed to read.
   
    [mutex lock];
    numWaitingReaders--;
    numReaders++;
    [mutex unlock];
     
    // Give up lock, allowing other readers to wake up as well.
    [lock unlockWithCondition: READING];
  }
}

- (void) releaseReadLock {
  [mutex lock];
  numReaders--;
  
  if (numReaders == 0) {
    [lock lockWhenCondition: READING]; // Immediately succeeds.
    
    if (numWaitingReaders > 0) {
      // Although there is no need for waiting readers in the READING state,
      // this can happen if waiting readers are not woken up quickly enough.
      [lock unlockWithCondition: READING];
    }
    else if (numWaitingWriters > 0) {
      [lock unlockWithCondition: WRITING];
    }
    else {
      [lock unlockWithCondition: IDLE];
    }
  }
  
  [mutex unlock];
}

- (void) obtainWriteLock {
  BOOL  wait = NO;

  [mutex lock];
  if ([lock tryLockWhenCondition: IDLE]) {
    // Was in IDLE state, start writing
    
    // Note: Not releasing lock, to ensure that no other thread starts reading
    // or writing.
    
    // Note: Although the condition of the lock is still IDLE, that does not
    // matter as long as the lock is being held. The condition only matters 
    // when the is (being) unlocked. The TreeContext is now already considered 
    // to be in WRITING state.
  }
  else {
    // Currently in READING or WRITING state 
    numWaitingWriters++;
    wait = YES;
  }
  [mutex unlock];
  
  if (wait) {
    [lock lockWhenCondition: WRITING];
    // We are now in the WRITING state.
   
    [mutex lock];
    numWaitingWriters--;
    [mutex unlock];
    
    // Note: Not releasing lock, to ensure that no other thread starts reading
    // or writing.
  }
}

- (void) releaseWriteLock {
  [mutex lock]; 

  if (numWaitingReaders > 0) {
    [lock unlockWithCondition: READING];
  }
  else if (numWaitingWriters > 0) {
    [lock unlockWithCondition: WRITING];
  }
  else {
    [lock unlockWithCondition: IDLE];
  }
  
  [mutex unlock];
}

@end // TreeContext


@implementation TreeContext (PrivateMethods)

- (Item *)itemContainingSelectedFileItem:(ItemPathModelView *)pathModelView {
  FileItem  *selectedItem = [pathModelView selectedFileItemInTree];
  
  // Get the items in the path (from the underlying path model). 
  NSArray  *itemsInPath = [[pathModelView pathModel] itemPath];
  NSUInteger  i = [itemsInPath count] - 1;
  while ([itemsInPath objectAtIndex: i] != selectedItem) {
    NSAssert(i > 0, @"Item not found.");
    i--;
  }

  // Found the item. Return the one just above it in the path. 
  return [itemsInPath objectAtIndex: i-1];
}


- (void) postFileItemDeleted {
  NSNotificationCenter  *nc = [NSNotificationCenter defaultCenter];

  [nc postNotificationName: FileItemDeletedEvent object: self];
  [nc postNotificationName: FileItemDeletedHandledEvent object: self];
}

- (void) fileItemDeletedHandled:(NSNotification *)notification {
  [replacedItem release];
  replacedItem = nil;
  
  [replacingItem release];
  replacingItem = nil; 
}

- (void) updateFreedSpaceForDeletedItem:(Item *)item; {
  if ( [item isVirtual] ) {
    [self updateFreedSpaceForDeletedItem: [((CompoundItem *)item) getFirst]];
    [self updateFreedSpaceForDeletedItem: [((CompoundItem *)item) getSecond]];
  }
  else {
    FileItem *fileItem = (FileItem *)item;
    
    // Note: Deletion of hard-linked items is included in the freedSpace
    // accounting, even though the free space on the harddrive won't be 
    // increased until all instances have been deleted. The reason is that
    // not doing can result in strange anonalies. For example, deleting a
    // directory that contains one or more hard-linked files increases the
    // freedSpace count by less than the size of the "freed space" block that
    // replaces all files that have been deleted.

    if ( [fileItem isDirectory] ) {
      [self updateFreedSpaceForDeletedItem:
              [((DirectoryItem *)item) getContents]];
    }
    else {
      if ([fileItem isPhysical] ) {
        // The item is physical so we freed up some space. (Non-physical items,
        // including already freed space, should not be counted)
        freedSpace += [item itemSize];
        freedFiles++;
      }
    }
  }
}

@end // TreeContext (PrivateMethods)

