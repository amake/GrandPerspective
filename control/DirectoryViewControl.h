#import <Cocoa/Cocoa.h>

// Deletion options
extern NSString  *DeleteNothing;
extern NSString  *OnlyDeleteFiles;
extern NSString  *DeleteFilesAndFolders;

// Notifications when opening and closing views
extern NSString  *ViewWillOpenEvent;
extern NSString  *ViewWillCloseEvent;

@class DirectoryView;
@class ItemPathModel;
@class ItemPathModelView;
@class DirectoryViewControlSettings;
@class DirectoryViewDisplaySettings;
@class TreeContext;
@class AnnotatedTreeContext;

@interface DirectoryViewControl : NSWindowController {

  // Main window
  IBOutlet NSTextField  *itemPathField;
  IBOutlet NSTextField  *itemSizeField;
  IBOutlet DirectoryView  *mainView;
  
  ItemPathModelView  *pathModelView;
  TreeContext  *treeContext;
  
  // The "initialSettings" field is only used between initialization and subsequent creation of the
  // window. It's subsequently dynamically created as needed.
  DirectoryViewControlSettings  *initialSettings;

  DirectoryViewDisplaySettings  *displaySettings;

  BOOL  canDeleteFiles;
  BOOL  canDeleteFolders;
  BOOL  confirmFileDeletion;
  BOOL  confirmFolderDeletion;

  // The (absolute) path of the scan tree.
  NSString  *scanPathName;
  
  // The part of the (absolute) path that is outside the visible tree.
  NSString  *invisiblePathName;
  
  // The size of the view when it is not zoomed.
  NSSize  unzoomedViewSize;
}

- (IBAction) openFile:(id)sender;
- (IBAction) previewFile:(id)sender;
- (IBAction) revealFileInFinder:(id)sender;
- (IBAction) deleteFile:(id)sender;
- (IBAction) showInfo:(id)sender;

- (instancetype) initWithAnnotatedTreeContext:(AnnotatedTreeContext *)treeContext;
- (instancetype) initWithAnnotatedTreeContext:(AnnotatedTreeContext *)treeContext
                                    pathModel:(ItemPathModel *)itemPathModel
                                     settings:(DirectoryViewControlSettings *)settings NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readwrite, copy) NSString *comments;

@property (nonatomic, readonly, strong) NSString *nameOfActiveMask;

@property (nonatomic, readonly, strong) ItemPathModelView *pathModelView;

@property (nonatomic, readonly, strong) DirectoryView *directoryView;

/* Returns a newly created object that represents the current settings of the view. It can
 * subsequently be safely modified. This will not affect the view.
 */
@property (nonatomic, readonly, strong) DirectoryViewControlSettings *directoryViewControlSettings;

@property (nonatomic, readonly, strong) TreeContext *treeContext;
@property (nonatomic, readonly, strong) AnnotatedTreeContext *annotatedTreeContext;

/* Returns YES iff the action is currently enabled. 
 * 
 * Only works for a subset of of actions, e.g. openFile: and deleteFile:. See implementation for
 * complete list, which can be extended when needed.
 */
- (BOOL) validateAction:(SEL)action;

/* Returns YES iff the selection is currently locked, which means that it does not change when the
 * mouse position changes.
 */
@property (nonatomic, getter=isSelectedFileLocked, readonly) BOOL selectedFileLocked;

+ (NSArray *)fileDeletionTargetNames;

- (void) showInformativeAlert:(NSAlert *)alert;

@end
