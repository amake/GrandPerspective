#import <Foundation/Foundation.h>

#import "TreeLayoutTraverser.h"

@class FileItem;
@class ItemPathModelView;
@class TreeLayoutBuilder;

@interface SelectedItemLocator : NSObject <TreeLayoutTraverser> {
  // All variables below are temporary variables used while building the path. They are not
  // retained, as they are only used during a single recursive invocation.

  NSArray  *path;
  unsigned int  pathIndex;
  NSRect  itemLocation;
}

- (NSRect) locationForItemAtEndOfPath:(NSArray *)itemPath
                       startingAtTree:(FileItem *)treeRoot
                   usingLayoutBuilder:(TreeLayoutBuilder *)layoutBuilder
                               bounds:(NSRect)bounds;

@end
