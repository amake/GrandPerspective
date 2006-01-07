#import <Cocoa/Cocoa.h>

@class TreeLayoutBuilder;
@class DirectoryTreeDrawer;
@class ItemPathDrawer;
@class ItemPathModel;
@class FileItemHashing;

@interface DirectoryView : NSView {

  TreeLayoutBuilder  *treeLayoutBuilder;
  DirectoryTreeDrawer  *treeDrawer;
  ItemPathDrawer  *pathDrawer;
  
  ItemPathModel  *itemPathModel;

  // If it is set to "false", the path changes by following the mouse pointer 
  // when its in the mainView. 
  BOOL  visibleItemPathLocked;
  
  BOOL  trackingRectEnabled;
  NSTrackingRectTag  trackingRectTag;
}

- (void) setItemPathModel:(ItemPathModel*)itemPath;

- (void) setFileItemHashing:(FileItemHashing*)fileItemHashing;
- (FileItemHashing*) fileItemHashing;

- (BOOL) isVisibleItemPathLocked;

@end
