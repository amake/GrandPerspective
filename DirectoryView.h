#import <Cocoa/Cocoa.h>

@class TreeLayoutBuilder;
@class DirectoryViewDrawer;
@class TreeNavigator;
@class FileItemHashing;

@interface DirectoryView : NSView {

  TreeLayoutBuilder  *treeLayoutBuilder;
  DirectoryViewDrawer  *treeDrawer;
  TreeNavigator  *treeNavigator;

}

- (void) setTreeNavigator:(TreeNavigator*)navigator;

- (void) setFileItemHashing:(FileItemHashing*)fileItemHashing;
- (FileItemHashing*) fileItemHashing;

@end
