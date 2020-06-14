#import <Cocoa/Cocoa.h>

#import "TreeLayoutTraverser.h"

@class FileItem;
@class FileItemTest;
@class FilteredTreeGuide;
@class TreeLayoutBuilder;

@interface OverlayDrawer : NSObject <TreeLayoutTraverser> {
  FilteredTreeGuide  *treeGuide;

  // Only set and used used during drawOverlay invocation
  CGContextRef cgContext;
}

- (instancetype) init;

/* Draws the part of the overlay that is visible in the tree.
 */
- (void) drawOverlay:(FileItemTest *)fileItemTest
      startingAtTree:(FileItem *)treeRoot
  usingLayoutBuilder:(TreeLayoutBuilder *)layoutBuilder
              bounds:(NSRect)bounds;

@end

