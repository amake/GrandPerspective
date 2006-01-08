#import <Cocoa/Cocoa.h>

@class Item;
@class FileItem;

@interface ItemPathModel : NSObject<NSCopying> {
  // Contains the FileItems from the root until the end of the path. It may
  // also be used to store the intermediate virtual items. This can be
  // useful, for instance, when the path needs to be drawn in the tree view.
  NSMutableArray  *path;

  // The index in the path array where the subtree starts (always a FileItem)
  unsigned  visibleTreeRootIndex;
  
  // The index in the path array where the visible file path ends (always a 
  // FileItem).
  //
  // Note: It is not necessarily always the last item in the array, as one
  // or more virtual items may still follow (in particular while the path is 
  // currently being extended).
  unsigned lastFileItemIndex;
  
  // Controls if "visibleItemPathChanged" notifications are being (temporarily)
  // supressed. If it is set to "nil", they are posted as they occur. Otherwise
  // it will suppress notifications, but remember the state of the path when
  // the last notification was posted by remembering the endpoint. As soon as
  // it is switched back to nil, it will check if the path has indeed changed,
  // and if so, fire a notification. 
  Item*  lastNotifiedPathEndPoint;
}

- (id) initWithTree:(FileItem*)itemTreeRoot;

// Returns the file items in the invisble part of the path until (inclusive)
// root in view
- (NSArray*) invisibleFileItemPath;

// Returns the file items in the visible part of the path (excluding root in 
// view)
- (NSArray*) visibleFileItemPath;

// Returns all items in the invisble part of the path  until (inclusive) root 
// in view
- (NSArray*) invisibleItemPath;

// Returns all items in the visible part of the path (excluding root in view)
- (NSArray*) visibleItemPath;

// Returns all items in the path
- (NSArray*) itemPath;

// Returns the last file item in the path
- (FileItem*) fileItemPathEndPoint;


- (void) suppressItemPathChangedNotifications:(BOOL)option;

- (BOOL) clearVisibleItemPath;
- (void) extendVisibleItemPath:(Item*)nextItem;

- (FileItem*) itemTree;
- (FileItem*) visibleItemTree;

- (BOOL) canMoveTreeViewUp;
- (BOOL) canMoveTreeViewDown;
- (void) moveTreeViewUp;
- (void) moveTreeViewDown;

@end
