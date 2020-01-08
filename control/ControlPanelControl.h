#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class ColorLegendTableViewControl;
@class ColorListCollection;
@class DirectoryItem;
@class DirectoryViewControl;
@class DirectoryViewDisplaySettings;
@class FileItemMappingCollection;
@class FilterPopUpControl;
@class FilterRepository;
@class ItemInFocusControls;
@class TreeDrawerSettings;

extern NSString  *DisplaySettingsChangedEvent;

@interface ControlPanelControl : NSWindowController {
  IBOutlet NSTabView  *tabView;

  // "Display" panel
  IBOutlet NSPopUpButton  *colorMappingPopUp;
  IBOutlet NSPopUpButton  *colorPalettePopUp;
  IBOutlet NSPopUpButton  *maskPopUp;
  IBOutlet NSTableView  *colorLegendTable;
  IBOutlet NSButton  *maskCheckBox;
  IBOutlet NSButton  *showEntireVolumeCheckBox;
  IBOutlet NSButton  *showPackageContentsCheckBox;

  // "Info" panel
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

  // "Focus" panel
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

  // Other fields

  ItemInFocusControls  *visibleFolderFocusControls;
  ItemInFocusControls  *selectedItemFocusControls;

  FileItemMappingCollection  *colorMappings;
  ColorListCollection  *colorPalettes;
  ColorLegendTableViewControl  *colorLegendControl;

  FilterPopUpControl  *maskPopUpControl;
  FilterRepository  *filterRepository;

  DirectoryViewControl  *observedDirectoryView;
}

+ (ControlPanelControl *)singletonInstance;

// Invoke when a display setting is changed that does not require special handling by the control
- (IBAction) displaySettingChanged:(id)sender;

- (IBAction) maskChanged:(id)sender;

- (void) mainWindowChanged:(nullable id)sender;

// Ensures the window is shown (and in front) with the info panel visible.
- (void) showInfoPanel;

// Returns the current display settings. This is always a new instance.
- (DirectoryViewDisplaySettings *)displaySettings;

// Converts a description of the display settings to an object that realizes these.
- (TreeDrawerSettings *)instantiateDisplaySettings:(DirectoryViewDisplaySettings *)displaySettings
                                           forTree:(DirectoryItem *)tree;

@end

NS_ASSUME_NONNULL_END
