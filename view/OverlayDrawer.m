#import "OverlayDrawer.h"

#import "Item.h"
#import "FileItem.h"
#import "FilteredTreeGuide.h"
#import "TreeLayoutBuilder.h"

@implementation OverlayDrawer

- (instancetype) init {
  if (self = [super init]) {
    treeGuide = [[FilteredTreeGuide alloc] init];
  }
  return self;
}

- (void) dealloc {
  [treeGuide release];

  [super dealloc];
}

- (void) drawOverlay:(FileItemTest *)selectedTest
      startingAtTree:(FileItem *)treeRoot
  usingLayoutBuilder:(TreeLayoutBuilder *)layoutBuilder
              bounds:(NSRect)bounds {
  [treeGuide setFileItemTest: selectedTest];

  cgContext = [NSGraphicsContext.currentContext graphicsPort];
  CGContextSaveGState(cgContext);

  [layoutBuilder layoutItemTree: treeRoot inRect: bounds traverser: self];

  CGContextRestoreGState(cgContext);
  cgContext = nil;
}

- (BOOL) descendIntoItem:(Item *)item atRect:(NSRect)rect depth:(int)depth {
  if ( [item isVirtual] ) {
    return YES;
  }

  FileItem  *itemToUse = [treeGuide includeFileItem: (FileItem *)item];

  if (itemToUse != nil) {
    // The file item passed the test

    if ([itemToUse isDirectory]) {
      [treeGuide descendIntoDirectory: (DirectoryItem *)itemToUse];

      // Recurse over dir contents
      return YES;
    } else {
      // Plain file that passed the test. Highlight it
      CGContextSetBlendMode(cgContext, kCGBlendModeColorDodge);
      CGContextSetRGBFillColor(cgContext, 0.5, 0.5, 0.5, 1.0);
      CGContextFillRect(cgContext, rect);
    }
  } else {
    // File item that failed the test. Darken it
    CGContextSetBlendMode(cgContext, kCGBlendModeColorBurn);
    CGContextSetRGBFillColor(cgContext, 0.9, 0.9, 0.9, 1.0);
    CGContextFillRect(cgContext, rect);
  }

  return NO;
}

- (void) emergedFromItem:(Item *)item {
  if ( ! [item isVirtual] ) {
    if ( [((FileItem *)item) isDirectory] ) {
      [treeGuide emergedFromDirectory: (DirectoryItem *)item];
    }
  }
}

@end
