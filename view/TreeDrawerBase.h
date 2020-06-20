#import <Foundation/Foundation.h>

#import "TreeLayoutTraverser.h"

NS_ASSUME_NONNULL_BEGIN

@class DirectoryItem;
@class FileItem;
@class PlainFileItem;
@class FilteredTreeGuide;
@class TreeLayoutBuilder;

@interface TreeDrawerBase : NSObject <TreeLayoutTraverser> {
  FilteredTreeGuide  *treeGuide;

  DirectoryItem  *scanTree;

  FileItem  *visibleTree;
  BOOL  insideVisibleTree;

  BOOL  abort;
}

- (instancetype) initWithScanTree:(DirectoryItem *)scanTree NS_DESIGNATED_INITIALIZER;

/* Draws the visible tree. Drawing typically also starts there, but can start at the volume tree
 * root when the entire volume is drawn.
 *
 * Note: The tree starting at "treeRoot" should be immutable.
 */
- (NSImage *)drawImageOfVisibleTree:(FileItem *)visibleTree
                     startingAtTree:(FileItem *)treeRoot
                 usingLayoutBuilder:(TreeLayoutBuilder *)layoutBuilder
                             inRect:(NSRect)bounds;

/* Any outstanding request to abort Drawing is cancelled.
 */
- (void) clearAbortFlag;

/* Cancels any ongoing drawing task. Note: It is possible that the ongoing task is just finishing,
 * in which case it may still finish normally. Therefore, -clearAbortFlag should be invoked before
 * initiating a new drawing task, otherwise the next drawing task will be aborted immediately.
 */
- (void) abortDrawing;

@end

@interface TreeDrawerBase (ProtectedMethods)

- (void)drawVisibleTreeAtRect:(NSRect) rect;
- (void)drawUsedSpaceAtRect:(NSRect) rect;
- (void)drawFreeSpaceAtRect:(NSRect) rect;
- (void)drawFreedSpaceAtRect:(NSRect) rect;
- (void)drawFile:(PlainFileItem *)fileItem atRect:(NSRect) rect depth:(int) depth;
- (void)skippingFileItem:(FileItem *)fileItem atRect:(NSRect) rect;

@end

NS_ASSUME_NONNULL_END
