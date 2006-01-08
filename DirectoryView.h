#import <Cocoa/Cocoa.h>

@class TreeLayoutBuilder;
@class ItemTreeDrawer;
@class ItemPathDrawer;
@class ItemPathBuilder;
@class ItemPathModel;
@class FileItemHashing;

@interface DirectoryView : NSView {

  TreeLayoutBuilder  *treeLayoutBuilder;
  ItemTreeDrawer  *treeDrawer;
  ItemPathDrawer  *pathDrawer;
  ItemPathBuilder  *pathBuilder;
  
  ItemPathModel  *pathModel;

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
- (void) setVisibleItemPathLocking:(BOOL)value;

@end
