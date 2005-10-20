#import <Cocoa/Cocoa.h>

@class TreeLayoutBuilder;
@class ItemPathManager;
@class ItemPathDrawer;
@class Item;
@class FileItem;

@interface TreeNavigator : NSObject {
  ItemPathManager  *pathManager;
  ItemPathDrawer  *pathDrawer;
  
  BOOL  pathLocked;
}

- (id) initWithTree:(Item*)itemTreeRoot;

// Returns all file items from root until (inclusive) root in view
- (NSArray*) invisibleItemPath;

// Returns all file item in view path (excluding root in view)
- (NSArray*) visibleItemPath;

- (FileItem*) itemPathEndPoint;

// Returns "YES" if the visible item path has changed
- (BOOL) clearVisibleItemPath;

// Returns "YES" if the visible item path has changed
- (BOOL) buildVisibleItemPathToPoint:(NSPoint)point 
           usingLayoutBuilder:(TreeLayoutBuilder*)layoutBuilder
           bounds:(NSRect)bounds;

- (BOOL) isVisibleItemPathLocked;
- (BOOL) toggleVisibleItemPathLock;

- (void) drawVisibleItemPathUsingLayoutBuilder:(TreeLayoutBuilder*)layoutBuilder
           bounds:(NSRect)bounds;

- (FileItem*) visibleItemTree;

- (BOOL) canMoveTreeViewUp;
- (BOOL) canMoveTreeViewDown;
- (void) moveTreeViewUp;
- (void) moveTreeViewDown;

@end
