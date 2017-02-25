#import "SelectedItemLocator.h"

#import "FileItem.h"
#import "ItemPathModel.h"
#import "ItemPathModelView.h"
#import "TreeLayoutBuilder.h"


@implementation SelectedItemLocator

- (NSRect) locationForSelectedItem: (ItemPathModelView *)pathModelView
                    startingAtTree: (FileItem *)treeRoot
                usingLayoutBuilder: (TreeLayoutBuilder *)layoutBuilder
                            bounds: (NSRect)bounds {
  itemLocation = NSZeroRect;

  NSAssert(path == nil, @"path should be nil");
  path = [[pathModelView pathModel] itemPath];
    // Not retaining it. It is only needed during this method.

  // Align the path with the tree, as the path may contain invisible items
  // not part of the tree.
  pathIndex = 0;
  while ([path objectAtIndex: pathIndex] != treeRoot) {
    pathIndex++;

    NSAssert(pathIndex < [path count], @"treeRoot not found in path.");
  }

  targetItem = [pathModelView selectedFileItemInTree];

  [layoutBuilder layoutItemTree: treeRoot inRect: bounds traverser: self];

  path = nil;

  return itemLocation;
}

- (BOOL) descendIntoItem: (Item *)item
                  atRect: (NSRect) rect
                   depth: (int) depth {
  if (pathIndex >= [path count] || [path objectAtIndex: pathIndex] != item) {
    return NO;
  }

  pathIndex++;
  itemLocation = rect;

  return (item != targetItem);
}

- (void) emergedFromItem: (Item *)item {
  // void
}

@end
