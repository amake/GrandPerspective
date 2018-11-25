#import <Cocoa/Cocoa.h>

// Deletion options
extern NSString  *DeleteNothing;
extern NSString  *OnlyDeleteFiles;
extern NSString  *DeleteFilesAndFolders;

// Notifications when opening and closing views
extern NSString  *ViewWillOpenEvent;
extern NSString  *ViewWillCloseEvent;

@class DirectoryItem;
@class DirectoryView;
@class ItemPathModel;
@class ItemPathModelView;
@class FileItemMappingCollection;
@class ColorListCollection;
@class ColorLegendTableViewControl;
@class DirectoryViewControlSettings;
@class TreeContext;
@class AnnotatedTreeContext;
@class ItemInFocusControls;
@class Filter;
@class NamedFilter;
@class FilterRepository;
@class FilterPopUpControl;

@interface DirectoryViewControl : NSWindowController {

  // Main window
  IBOutlet NSTextField  *itemPathField;
  IBOutlet NSTextField  *itemSizeField;
  IBOutlet DirectoryView  *mainView;
  
  IBOutlet NSDrawer  *drawer;
  
  // "Display" drawer panel
  IBOutlet NSPopUpButton  *colorMappingPopUp;
  IBOutlet NSPopUpButton  *colorPalettePopUp;
  IBOutlet NSPopUpButton  *maskPopUp;
  IBOutlet NSTableView  *colorLegendTable;
  IBOutlet NSButton  *maskCheckBox;
  IBOutlet NSButton  *showEntireVolumeCheckBox;
  IBOutlet NSButton  *showPackageContentsCheckBox;

  // "Info" drawer panel
  IBOutlet NSImageView  *volumeIconView;
  IBOutlet NSTextField  *volumeNameField;
  IBOutlet NSTextView  *scanPathTextView;
  IBOutlet NSTextField  *filterNameField;
  IBOutlet NSTextView  *commentsTextView;
  IBOutlet NSTextField  *scanTimeField;
  IBOutlet NSTextField  *fileSizeMeasureField;
  IBOutlet NSTextField  *volumeSizeField;
  IBOutlet NSTextField  *miscUsedSpaceField;
  IBOutlet NSTextField  *treeSizeField;
  IBOutlet NSTextField  *freeSpaceField;
  IBOutlet NSTextField  *freedSpaceField;
  IBOutlet NSTextField  *numScannedFilesField;
  IBOutlet NSTextField  *numDeletedFilesField;
  
  // "Focus" drawer panel
  IBOutlet NSTextField  *visibleFolderTitleField;
  IBOutlet NSTextView  *visibleFolderPathTextView;
  IBOutlet NSTextField  *visibleFolderExactSizeField;
  IBOutlet NSTextField  *visibleFolderSizeField;

  IBOutlet NSTextField  *selectedItemTitleField;
  IBOutlet NSTextView  *selectedItemPathTextView;
  IBOutlet NSTextField  *selectedItemExactSizeField;
  IBOutlet NSTextField  *selectedItemSizeField;

  IBOutlet NSTextField  *selectedItemTypeIdentifierField;

  IBOutlet NSTextField  *selectedItemCreationTimeField;
  IBOutlet NSTextField  *selectedItemModificationTimeField;
  IBOutlet NSTextField  *selectedItemAccessTimeField;
  
  ItemInFocusControls  *visibleFolderFocusControls;
  ItemInFocusControls  *selectedItemFocusControls;

  ItemPathModelView  *pathModelView;
  TreeContext  *treeContext;
  
  FilterRepository  *filterRepository;

  // The "initialSettings" and "initialComments" fields are only used between initialization and
  // subsequent creation of the window. The are subsequently owned and managed by various GUI
  // components.
  DirectoryViewControlSettings  *initialSettings;
  NSString  *initialComments;

  BOOL  canDeleteFiles;
  BOOL  canDeleteFolders;
  BOOL  confirmFileDeletion;
  BOOL  confirmFolderDeletion;

  FileItemMappingCollection  *colorMappings;
  ColorListCollection  *colorPalettes;
  ColorLegendTableViewControl  *colorLegendControl;
  FilterPopUpControl  *maskPopUpControl;
  
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
- (IBAction) toggleDrawer:(id)sender;

- (IBAction) maskCheckBoxChanged:(id)sender;

- (IBAction) colorMappingChanged:(id)sender;
- (IBAction) colorPaletteChanged:(id)sender;
- (IBAction) maskChanged:(id)sender;
- (IBAction) showEntireVolumeCheckBoxChanged:(id)sender;
- (IBAction) showPackageContentsCheckBoxChanged:(id)sender;

- (instancetype) initWithAnnotatedTreeContext:(AnnotatedTreeContext *)treeContext;
- (instancetype) initWithAnnotatedTreeContext:(AnnotatedTreeContext *)treeContext
                                    pathModel:(ItemPathModel *)itemPathModel
                                     settings:(DirectoryViewControlSettings *)settings;
- (instancetype) initWithAnnotatedTreeContext:(AnnotatedTreeContext *)treeContext
                                    pathModel:(ItemPathModel *)itemPathModel
                                     settings:(DirectoryViewControlSettings *)settings
                             filterRepository:(FilterRepository *)filterRepository NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly, strong) Filter *mask;
@property (nonatomic, readonly, strong) NamedFilter *namedMask;

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
