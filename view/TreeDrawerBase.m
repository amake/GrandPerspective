#import "TreeDrawerBase.h"

#import "DirectoryItem.h"
#import "FilteredTreeGuide.h"
#import "TreeLayoutBuilder.h"
#import "TreeContext.h"

@implementation TreeDrawerBase

// Overrides designated initialiser
- (instancetype) init {
  NSAssert(NO, @"Use initWithScanTree: instead.");

  #pragma clang diagnostic push
  #pragma clang diagnostic ignored "-Wnonnull"
  return [self initWithScanTree: nil];
  #pragma clang diagnostic pop
}

- (instancetype) initWithScanTree:(DirectoryItem *)scanTreeVal {
  if (self = [super init]) {
    scanTree = [scanTreeVal retain];
    treeGuide = [[FilteredTreeGuide alloc] init];

    abort = NO;
  }
  return self;
}

- (void) dealloc {
  [treeGuide release];
  [scanTree release];

  NSAssert(visibleTree == nil, @"visibleTree should be nil.");
  [visibleTree release]; // For sake of completeness. Can be omitted.

  [super dealloc];
}


- (NSImage *)drawImageOfVisibleTree:(FileItem *)visibleTreeVal
                     startingAtTree:(FileItem *)treeRoot
                 usingLayoutBuilder:(TreeLayoutBuilder *)layoutBuilder
                             inRect:(NSRect)bounds {
  insideVisibleTree = NO;
  NSAssert(visibleTree == nil, @"visibleTree should be nil.");
  visibleTree = [visibleTreeVal retain];

  [layoutBuilder layoutItemTree: treeRoot inRect: bounds traverser: self];

  [visibleTree release];
  visibleTree = nil;

  // It is the responsibility of the subclass to wrap this invocation and ensure that an image is
  // created.
  return nil;
}

- (void) clearAbortFlag {
  abort = NO;
}

- (void) abortDrawing {
  abort = YES;
}


- (BOOL) descendIntoItem:(Item *)item atRect:(NSRect)rect depth:(int)depth {
  if ( [item isVirtual] ) {
    return YES;
  }

  FileItem  *file = (FileItem *)item;

  if ( file == visibleTree ) {
    insideVisibleTree = YES;

    [self drawVisibleTreeAtRect: rect];

    // Check if any ancestors are masked
    FileItem  *ancestor = file;
    while (ancestor != scanTree) {
      ancestor = ancestor.parentDirectory;
      if (! [treeGuide includeFileItem: ancestor]) {
        return NO;
      }
    }
  }

  if ( !insideVisibleTree ) {
    // Not yet inside the visible tree (implying that the entire volume is shown). Ensure that the
    // special "volume" items are drawn, and only descend towards the visible tree.

    if ( file.isDirectory ) {
      if ( !file.isPhysical && [file.label isEqualToString: UsedSpace] ) {
        [self drawUsedSpaceAtRect: rect];
      }

      if ( [file isAncestorOfFileItem: visibleTree] ) {
        [treeGuide descendIntoDirectory: (DirectoryItem *)file];
        return YES;
      }
      else {
        return NO;
      }
    }
    else {
      if ( !file.isPhysical && [file.label isEqualToString: FreeSpace] ) {
        [self drawFreeSpaceAtRect: rect];
      }

      return NO;
    }
  }

  // Inside the visible tree. Check if the item is masked
  file = [treeGuide includeFileItem: file];
  if (file == nil) {
    return NO;
  }

  if ( file.isDirectory ) {
    // Descend unless drawing has been aborted

    if ( !abort ) {
      [treeGuide descendIntoDirectory: (DirectoryItem *)file];
      return YES;
    }
    else {
      return NO;
    }
  }

  // It's a plain file
  if ( file.isPhysical ) {
    [self drawFile:(PlainFileItem *)file atRect: rect depth: depth];
  }
  else {
    if ( [file.label isEqualToString: FreedSpace] ) {
      [self drawFreedSpaceAtRect: rect];
    }
  }

  if (item == visibleTree) {
    // Note: emergedFromItem: will not be invoked, so unset the flag here.
    insideVisibleTree = NO;
  }

  // Do not descend into the item.
  //
  // Note: This is not just an optimisation but needs to be done. Even though the item is seen as a
  // file by the TreeDrawer, it may actually be a package whose contents are hidden. The
  // TreeLayoutBuilder should not descend into the directory in this case.
  return NO;
}

- (void) emergedFromItem:(Item *)item {
  if ( !item.isVirtual ) {
    if (item == visibleTree) {
      insideVisibleTree = NO;
    }

    if ( ((FileItem *)item).isDirectory ) {
      [treeGuide emergedFromDirectory: (DirectoryItem *)item];
    }
  }
}

@end

@implementation TreeDrawerBase (ProtectedMethods)

// Provide default empty implementation
- (void)drawVisibleTreeAtRect:(NSRect) rect {}
- (void)drawUsedSpaceAtRect:(NSRect) rect {}
- (void)drawFreeSpaceAtRect:(NSRect) rect {}
- (void)drawFreedSpaceAtRect:(NSRect) rect {}
- (void)drawFile:(PlainFileItem *)fileItem atRect:(NSRect) rect depth:(int) depth {}

@end
