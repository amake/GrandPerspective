#import <Cocoa/Cocoa.h>

@class FileItem;
@class DirectoryView;
@class StartupControl;
@class TreeNavigator;
@class FileItemHashingOptions;

@interface DirectoryViewControl : NSWindowController {

  IBOutlet NSComboBox *colorMappingChoice;
  IBOutlet NSTextField *itemNameLabel;
  IBOutlet NSTextField *itemSizeLabel;
  IBOutlet DirectoryView *mainView;
  IBOutlet NSButton *upButton;
  IBOutlet NSButton *downButton;

  FileItem  *itemTreeRoot;
  TreeNavigator  *treeNavigator;
  FileItemHashingOptions  *hashingOptions;
  NSMutableString  *invisiblePathName;
}

- (IBAction) colorMappingChanged:(id)sender;
- (IBAction) upAction:(id)sender;
- (IBAction) downAction:(id)sender;

- (id) initWithItemTree:(FileItem*)itemTreeRoot;
- (FileItem*) itemTree;

@end
