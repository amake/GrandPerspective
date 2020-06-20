#import <Cocoa/Cocoa.h>

#import "TreeDrawerBase.h"

@class FileItemTest;

@interface OverlayDrawer : TreeDrawerBase {
  UInt32  overlayColor;
}

/* Draws the part of the overlay that is visible in the tree.
 */
- (NSImage *)drawOverlayImageOfVisibleTree:(FileItem *)visibleTree
                            startingAtTree:(FileItem *)treeRoot
                        usingLayoutBuilder:(TreeLayoutBuilder *)layoutBuilder
                                    inRect:(NSRect) bounds
                               overlayTest:(FileItemTest *)overlayTest;

@end

