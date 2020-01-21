#import "TreeBuilder.h"

#import "AlertMessage.h"
#import "TreeConstants.h"
#import "PlainFileItem.h"
#import "DirectoryItem.h"
#import "ScanTreeRoot.h"
#import "CompoundItem.h"
#import "TreeContext.h"
#import "FilterSet.h"
#import "FilteredTreeGuide.h"
#import "TreeBalancer.h"
#import "NSURL.h"
#import "ControlConstants.h"

#import "ScanProgressTracker.h"
#import "UniformTypeInventory.h"


NSString  *LogicalFileSizeName = @"logical";
NSString  *PhysicalFileSizeName = @"physical";
NSString  *TallyFileSizeName = @"tally";


/* Use smaller bounds given the extra scan cost needed to determine the number of directories
 * at each level used for tracking progress.
 */
#define  NUM_SCAN_PROGRESS_ESTIMATE_LEVELS MIN(6, NUM_PROGRESS_ESTIMATE_LEVELS)

#define  AUTORELEASE_PERIOD  1024

/* Helper class that is used to temporarily store additional info for directories that are being
 * scanned. It stores the info that is not maintained by the DirectoryItem class yet is needed
 * while its contents are still being scanned.
 */
@interface ScanStackFrame : NSObject {
@public
  DirectoryItem  *dirItem;

  // The url for the directory file item
  NSURL  *url;

  // Arrays containing the immediate children
  NSMutableArray<DirectoryItem *>  *dirs;
  NSMutableArray<PlainFileItem *>  *files;
}

- (void) initWithDirectoryItem:(DirectoryItem *)dirItemVal URL:(NSURL *)urlVal;

/* Remove any sub-directories that should not be included according to the treeGuide. This
 * filtering needs to be done after all items inside this directory have been scanned, as the
 * filtering may be based on the (recursive) size of the items.
 */
- (void) filterSubDirectories:(FilteredTreeGuide *)treeGuide;

@end // @interface ScanStackFrame

@interface TreeBuilder ()

// Re-declare to allow writing internally
@property (nonatomic, readwrite, strong) NSAlert *informativeAlert;

@end

@interface TreeBuilder (PrivateMethods)

- (TreeContext *)treeContextForVolumeContaining:(NSString *)path;
- (void) addToStack:(DirectoryItem *)dirItem URL:(NSURL *)url;
- (ScanStackFrame *)unwindStackToURL:(NSURL *)url;

- (BOOL) buildTreeForDirectory:(DirectoryItem *)dirItem atPath:(NSString *)path;

- (BOOL) visitHardLinkedItemAtURL:(NSURL *)url;

- (int) determineNumSubFoldersFor:(NSURL *)url;

- (AlertMessage *)createAlertMessage:(DirectoryItem *)scanTree;

@end // @interface TreeBuilder (PrivateMethods)


@implementation ScanStackFrame

// Overrides super's designated initialiser.
- (instancetype) init {
  if (self = [super init]) {
    // Multiplying sizes specified in TreeConstants.h. As these arrays are being re-used, it is
    // better to make them initially larger to avoid unnecessary resizing.
    dirs = [[NSMutableArray alloc] initWithCapacity: INITIAL_DIRS_CAPACITY * 32];
    files = [[NSMutableArray alloc] initWithCapacity: INITIAL_FILES_CAPACITY * 32];
  }
  return self;
}

// "Constructor" intended for repeated usage. It assumes init has already been invoked
- (void) initWithDirectoryItem:(DirectoryItem *)dirItemVal URL:(NSURL *)urlVal {
  if (dirItem != dirItemVal) {
    [dirItem release];
  }
  dirItem = [dirItemVal retain];

  if (url != urlVal) {
    [url release];
  }
  url = [urlVal retain];

  // Clear data from previous usage
  [dirs removeAllObjects];
  [files removeAllObjects];
}

- (void) dealloc {
  [dirs release];
  [files release];

  [url release];
  [dirItem release];
  
  [super dealloc];
}

- (DirectoryItem *) directoryItem {
  return dirItem;
}

- (void) filterSubDirectories:(FilteredTreeGuide *)treeGuide {
  for (NSUInteger i = dirs.count; i-- > 0; ) {
    DirectoryItem  *dirChildItem = dirs[i];

    if (! [treeGuide includeFileItem: dirChildItem] ) {
      // The directory did not pass the test, so exclude it.
      [dirs removeObjectAtIndex: i];
    }
  }
}

@end // @implementation ScanStackFrame


@implementation TreeBuilder

+ (NSArray *)fileSizeMeasureNames {
  static NSArray  *fileSizeMeasureNames = nil;

  if (fileSizeMeasureNames == nil) {
    fileSizeMeasureNames = [@[LogicalFileSizeName, PhysicalFileSizeName, TallyFileSizeName] retain];
  }
  
  return fileSizeMeasureNames;
}

- (instancetype) init {
  return [self initWithFilterSet: nil];
}


- (instancetype) initWithFilterSet:(FilterSet *)filterSetVal {
  if (self = [super init]) {
    filterSet = [filterSetVal retain];

    treeGuide = [[FilteredTreeGuide alloc] initWithFileItemTest: [filterSet fileItemTest]];

    treeBalancer = [[TreeBalancer alloc] init];
    typeInventory = [[UniformTypeInventory defaultUniformTypeInventory] retain];
    
    hardLinkedFileNumbers = [[NSMutableSet alloc] initWithCapacity: 32];
    abort = NO;
    
    progressTracker =
      [[ScanProgressTracker alloc] initWithMaxLevel: NUM_SCAN_PROGRESS_ESTIMATE_LEVELS];
    
    dirStack = [[NSMutableArray alloc] initWithCapacity: 16];
    
    [self setFileSizeMeasure: LogicalFileSizeName];
    
    NSUserDefaults *args = [NSUserDefaults standardUserDefaults];
    debugLogEnabled = [args boolForKey: @"logAll"] || [args boolForKey: @"logScanning"];

    _alertMessage = nil;
  }
  return self;
}


- (void) dealloc {
  [filterSet release];

  [treeGuide release];
  [treeBalancer release];
  [typeInventory release];
  
  [hardLinkedFileNumbers release];
  [fileSizeMeasureName release];
  
  [progressTracker release];
  
  [dirStack release];

  [_alertMessage release];
  
  [super dealloc];
}


- (BOOL) packagesAsFiles {
  return [treeGuide packagesAsFiles];
}

- (void) setPackagesAsFiles:(BOOL)flag {
  [treeGuide setPackagesAsFiles: flag];
}


- (NSString *)fileSizeMeasure {
  return fileSizeMeasureName;
}

- (void) setFileSizeMeasure:(NSString *)measure {
  if ([measure isEqualToString: LogicalFileSizeName]) {
    fileSizeMeasure = LogicalFileSize;
  }
  else if ([measure isEqualToString: PhysicalFileSizeName]) {
    fileSizeMeasure = PhysicalFileSize;
  }
  else if ([measure isEqualToString: TallyFileSizeName]) {
    fileSizeMeasure = TallyFileSize;
  }
  else {
    NSAssert(NO, @"Invalid file size measure.");
  }
  
  if (measure != fileSizeMeasureName) {
    [fileSizeMeasureName release];
    fileSizeMeasureName = [measure retain];
  }
}


- (void) abort {
  abort = YES;
}

- (TreeContext *)buildTreeForPath:(NSString *)path {
  TreeContext  *treeContext = [self treeContextForVolumeContaining: path];

  // Determine relative path
  NSString  *volumePath = [[treeContext volumeTree] systemPathComponent];
  NSString  *relativePath =
    volumePath.length < path.length ? [path substringFromIndex: volumePath.length] : @"";
  if (relativePath.absolutePath) {
    // Strip leading slash.
    relativePath = [relativePath substringFromIndex: 1];
  }

  NSFileManager  *manager = [NSFileManager defaultManager];
  if (relativePath.length > 0) {
    NSLog(@"Scanning volume %@ [%@], starting at %@", volumePath,
          [manager displayNameAtPath: volumePath], relativePath);
  }
  else {
    NSLog(@"Scanning entire volume %@ [%@].", volumePath,
          [manager displayNameAtPath: volumePath]);
  }
  
  // Get the properties
  NSURL  *treeRootURL = [NSURL fileURLWithPath: path];
  FileItemOptions  flags = 0;
  if ([treeRootURL isPackage]) {
    flags |= FileItemIsPackage;
  }
  if ([treeRootURL isHardLinked]) {
    flags |= FileItemIsHardlinked;
  }

  totalPhysicalSize = 0;
  numOverestimatedFiles = 0;
  [_alertMessage release];
  _alertMessage = nil;

  DirectoryItem  *scanTree = [ScanTreeRoot allocWithZone: [Item zoneForTree]];
  [[scanTree initWithLabel: relativePath
                    parent: [treeContext scanTreeParent]
                     flags: flags
              creationTime: [treeRootURL creationTime]
          modificationTime: [treeRootURL modificationTime]
                accessTime: [treeRootURL accessTime]
    ] autorelease];

  [progressTracker startingTask];

  BOOL  ok = [self buildTreeForDirectory: scanTree atPath: path];

  [progressTracker finishedTask];
  
  if (! ok) {
    return nil;
  }

  [treeContext setScanTree: scanTree];
  _alertMessage = [[self createAlertMessage: scanTree] retain];

  return treeContext;
}


- (NSDictionary *)progressInfo {
  // To be safe, do not return info when aborted. Auto-releasing parts of constructed tree could
  // invalidate path construction done by progressTracker. Even though it does not look that could
  // happen with current code, it could after some refactoring.
  return abort ? nil : [progressTracker progressInfo];
}

@end // @implementation TreeBuilder


@implementation TreeBuilder (PrivateMethods)

- (TreeContext *)treeContextForVolumeContaining:(NSString *)path {
  NSURL  *url = [NSURL fileURLWithPath: path];

  if (! [url isDirectory]) {
    // This may happen when the directory has been deleted (which can happen when rescanning)
    NSLog(@"Path to scan %@ is not a directory.", path);
    return nil;
  }

  NSError  *error = nil;
  NSURL  *volumeRoot;
  [url getResourceValue: &volumeRoot forKey: NSURLVolumeURLKey error: &error];
  if (error != nil) {
    NSLog(@"Failed to determine volume root of %@: %@", url, error.description);
  }

  NSNumber  *freeSpace;
  [volumeRoot getResourceValue: &freeSpace forKey: NSURLVolumeAvailableCapacityKey error: &error];
  if (error != nil) {
    NSLog(@"Failed to determine free space for %@: %@", volumeRoot, error.description);
  }

  NSNumber  *volumeSize;
  [volumeRoot getResourceValue: &volumeSize forKey: NSURLVolumeTotalCapacityKey error: &error];
  if (error != nil) {
    NSLog(@"Failed to determine capacity of %@: %@", volumeRoot, error.description);
  }

  return [[[TreeContext alloc] initWithVolumePath: volumeRoot.path
                                  fileSizeMeasure: fileSizeMeasureName
                                       volumeSize: volumeSize.unsignedLongLongValue
                                        freeSpace: freeSpace.unsignedLongLongValue
                                        filterSet: filterSet] autorelease];
}

- (void) addToStack:(DirectoryItem *)dirItem URL:(NSURL *)url {
  // Expand stack if required
  if (dirStackTopIndex + 1 == (int)dirStack.count) {
    [dirStack addObject: [[[ScanStackFrame alloc] init] autorelease]];
  }
  
  // Add the item to the stack. Overwriting the previous entry.
  [dirStack[++dirStackTopIndex] initWithDirectoryItem: dirItem URL: url];
  
  [treeGuide descendIntoDirectory: dirItem];
  [progressTracker processingFolder: dirItem];
  if (debugLogEnabled) {
    NSLog(@"Scanning %@", url);
  }
  if (dirStackTopIndex < NUM_SCAN_PROGRESS_ESTIMATE_LEVELS) {
    [progressTracker setNumSubFolders: [self determineNumSubFoldersFor: url]];
  }
}

- (ScanStackFrame *)unwindStackToURL:(NSURL *)url {
  ScanStackFrame  *topDir = (ScanStackFrame *)dirStack[dirStackTopIndex];
  while (! [topDir->url isEqual: url]) {
    // Pop directory from stack. Its contents have been fully scanned so finalize its contents.
    [topDir filterSubDirectories: treeGuide];
    
    DirectoryItem  *dirItem = topDir->dirItem;
    
    [dirItem setDirectoryContents:
      [CompoundItem compoundItemWithFirst: [treeBalancer createTreeForItems: topDir->files]
                                   second: [treeBalancer createTreeForItems: topDir->dirs]]];

    [treeGuide emergedFromDirectory: dirItem];
    [progressTracker processedFolder: dirItem];

    if (dirStackTopIndex == 0) {
      return nil;
    }

    topDir = (ScanStackFrame *)dirStack[--dirStackTopIndex];
  }

  return topDir;
}

- (BOOL) visitItemAtURL:(NSURL *)url parent:(ScanStackFrame *)parent {
  FileItemOptions  flags = 0;
  BOOL  visitDescendants = YES;
  BOOL  isDirectory = [url isDirectory];

  if ([url isHardLinked]) {
    flags |= FileItemIsHardlinked;

    if (![self visitHardLinkedItemAtURL: url]) {
      // Do not visit descendants if the item was a directory
      visitDescendants = !isDirectory;

      return visitDescendants;
    }
  }
  
  NSString  *lastPathComponent = url.lastPathComponent;

  if (isDirectory) {
    if ([url isPackage]) {
      flags |= FileItemIsPackage;
    }
    
    DirectoryItem  *dirChildItem =
      [[DirectoryItem allocWithZone: [parent zone]] initWithLabel: lastPathComponent
                                                           parent: parent->dirItem
                                                            flags: flags
                                                     creationTime: [url creationTime]
                                                 modificationTime: [url modificationTime]
                                                       accessTime: [url accessTime]];

    // Explicitly check if the path is the System Data volume. We do not want to scan its contents
    // to prevent its contents from being scanned twice (as they also appear inside the root via
    // firmlinks). Ideally, we use a more generic mechanism for this, similar to how hardlinks are
    // handled, but there does not yet seem to be an API to support this.
    BOOL isDataVolume = (
                         [lastPathComponent isEqualToString: @"Data"] &&
                         [[dirChildItem path] isEqualToString: @"/System/Volumes/Data"]
                        );

    // Only add directories that should be scanned (this does not necessarily mean that it has
    // passed the filter test already)
    if ( !isDataVolume && [treeGuide shouldDescendIntoDirectory: dirChildItem] ) {
      [parent->dirs addObject: dirChildItem];
      [self addToStack: dirChildItem URL: url];
    } else {
      NSLog(@"Skipping scan of %@", url);
      [progressTracker skippedFolder: dirChildItem];
      visitDescendants = NO;
    }

    [dirChildItem release];
  }
  else { // A file node.
    NSNumber  *physicalFileSize;
    [url getResourceValue: &physicalFileSize forKey: NSURLTotalFileAllocatedSizeKey error: nil];
    ITEM_SIZE  fileSize;

    switch (fileSizeMeasure) {
      case LogicalFileSize: {
        NSNumber  *logicalFileSize;
        [url getResourceValue: &logicalFileSize forKey: NSURLTotalFileSizeKey error: nil];

        fileSize = logicalFileSize.unsignedLongLongValue;
        totalPhysicalSize += physicalFileSize.unsignedLongLongValue;

        if (fileSize > physicalFileSize.unsignedLongLongValue) {
          if (debugLogEnabled) {
            NSLog(@"Warning: logical file size larger than physical file size for %@ (%llu > %llu)",
                  url, fileSize, physicalFileSize.unsignedLongLongValue);
          }
          numOverestimatedFiles++;
        }
        break;
      }
      case PhysicalFileSize:
        fileSize = physicalFileSize.unsignedLongLongValue;
        break;
      case TallyFileSize:
        fileSize = 1;
    }

    UniformType  *fileType =
      [typeInventory uniformTypeForExtension: lastPathComponent.pathExtension];

    PlainFileItem  *fileChildItem =
      [[PlainFileItem allocWithZone: [parent zone]] initWithLabel: lastPathComponent
                                                           parent: parent->dirItem
                                                             size: fileSize
                                                             type: fileType
                                                            flags: flags
                                                     creationTime: [url creationTime]
                                                 modificationTime: [url modificationTime]
                                                       accessTime: [url accessTime]];

    // Only add file items that pass the filter test.
    if ( [treeGuide includeFileItem: fileChildItem] ) {
      [parent->files addObject: fileChildItem];
    }

    [fileChildItem release];
  }

  return visitDescendants;
}

- (BOOL) buildTreeForDirectory:(DirectoryItem *)dirItem atPath:(NSString *)path {
  NSDirectoryEnumerator  *directoryEnumerator =
    [[NSFileManager defaultManager] enumeratorAtURL: [NSURL fileURLWithPath: path]
                         includingPropertiesForKeys: @[
                                                       NSURLNameKey,
                                                       NSURLIsDirectoryKey,
                                                       NSURLParentDirectoryURLKey,
                                                       NSURLCreationDateKey,
                                                       NSURLContentModificationDateKey,
                                                       NSURLContentAccessDateKey,
                                                       NSURLLinkCountKey,
                                                       NSURLIsPackageKey,
                                                       NSURLTotalFileSizeKey,
                                                       NSURLTotalFileAllocatedSizeKey
                                                      ]
                                            options: 0
                                       errorHandler: nil];

  NSAutoreleasePool  *autoreleasePool = nil;
  int  i = 0;
  dirStackTopIndex = -1;

  @try {
    for (NSURL *fileURL in directoryEnumerator) {
      NSURL  *parentURL = nil;
      [fileURL getParentURL: &parentURL];

      if (dirStackTopIndex == -1) {
        // Init first element of stack using URL as returned by getParentURL. This is done instead
        // constructing the URL from the path using NSURL fileURLWithPath: as the latter can
        // generate a different URL (see Bug #80), which in turn will cause an unwind failure.
        [self addToStack: dirItem URL: parentURL];
      }

      ScanStackFrame  *parent = [self unwindStackToURL: parentURL];
      NSAssert1(parent != nil, @"Unwind failure at %@", fileURL);

      if (![self visitItemAtURL: fileURL parent: parent]) {
        [directoryEnumerator skipDescendants];
      }
      if (++i == AUTORELEASE_PERIOD) {
        [autoreleasePool release];
        autoreleasePool = [[NSAutoreleasePool alloc] init];
        i = 0;
      }
      if (abort) {
        return NO;
      }
    }
    [self unwindStackToURL: nil]; // Force full unwind
  }
  @finally {
    [autoreleasePool release];
  }

  return YES;
}


/* Returns YES if item should be included in the tree. It returns NO when the item is hard-linked
 * and has already been encountered.
 */
- (BOOL) visitHardLinkedItemAtURL:(NSURL *)url {
  NSError  *error = nil;
  NSFileManager  *fileManager = [NSFileManager defaultManager];
  NSDictionary  *fileAttributes = [fileManager attributesOfItemAtPath: url.path error: &error];
  NSAssert2(
    error==nil, @"Error getting attributes for %@: %@",
    url, [error description]
  );
  NSNumber  *fileNumber = fileAttributes[NSFileSystemFileNumber];

  if (fileNumber == nil) {
    // Workaround for bug #2243134
    NSLog(
      @"Failed to get file number for the hard-linked file: %@\nCannot establish if the file has been included already, but including it anyway (possibly overestimating the amount of used disk space).",
      url.path
    );
    return YES;
  }

  if ([hardLinkedFileNumbers containsObject: fileNumber]) {
    // The item has already been encountered. Ignore it now so that it is only counted once.

    return NO;
  }

  [hardLinkedFileNumbers addObject: fileNumber];
  return YES;
}

- (int) determineNumSubFoldersFor:(NSURL *)url {
  NSDirectoryEnumerator  *directoryEnumerator =
    [[NSFileManager defaultManager] enumeratorAtURL: url
                         includingPropertiesForKeys: @[NSURLIsDirectoryKey]
                                            options: NSDirectoryEnumerationSkipsSubdirectoryDescendants
                                       errorHandler: nil];
  int  numSubDirs = 0;
  for (NSURL *fileURL in directoryEnumerator) {
    if ([fileURL isDirectory]) {
      numSubDirs++;
    }
  }

  return numSubDirs;
}

- (AlertMessage *)createAlertMessage:(DirectoryItem *)scanTree {
  if (fileSizeMeasure == LogicalFileSize) {
    if ([scanTree itemSize] > totalPhysicalSize) {
      AlertMessage  *alert = [[[AlertMessage alloc] init] autorelease];
      alert.messageText = NSLocalizedString
        (@"The reported total size is larger than the actual size on disk", @"Alert message");
      NSString *fmt = NSLocalizedString
        (@"The actual (physical) size is %.1f%% of the reported (logical) size. Consider rescanning using the Physical file size measure",
         @"Alert message");
      float percentage = (100.0 * totalPhysicalSize) / [scanTree itemSize];
      alert.informativeText = [NSString stringWithFormat: fmt, percentage];
      return alert;
    }

    if (numOverestimatedFiles > 0) {
      AlertMessage  *alert = [[[AlertMessage alloc] init] autorelease];
      alert.messageText = NSLocalizedString
        (@"The reported size of some files is larger than their actual size on disk",
         @"Alert message");
      NSString *fmt = NSLocalizedString
        (@"For %d files the reported (logical) size is larger than their actual (physical) size. Consider rescanning using the Physical file size measure",
         @"Alert message");
      alert.informativeText = [NSString stringWithFormat: fmt, numOverestimatedFiles];
      return alert;
    }
  }
  return nil;
}

@end // @implementation TreeBuilder (PrivateMethods)
