#import <Cocoa/Cocoa.h>

#import "TreeDrawerBase.h"

@class FileItem;
@class FileItemTest;

@interface OverlayDrawer : TreeDrawerBase {
  // Only set and used used during drawOverlay invocation
  CGContextRef cgContext;
}

/* Draws the part of the overlay that is visible in the tree.
 */
- (NSImage *)drawOverlayImageOfVisibleTree:(FileItem *)visibleTree
                            startingAtTree:(FileItem *)treeRoot
                        usingLayoutBuilder:(TreeLayoutBuilder *)layoutBuilder
                                   onTopOf:(NSImage *)sourceImage
                               overlayTest:(FileItemTest *)overlayTest;

@end

