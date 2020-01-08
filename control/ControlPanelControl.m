#import "ControlPanelControl.h"

// From tree
#import "DirectoryItem.h"
#import "ItemPathModel.h"
#import "PlainFileItem.h"
#import "TreeContext.h"

// From filter
#import "Filter.h"
#import "FilterRepository.h"
#import "FilterSet.h"

// From view
#import "TreeDrawerSettings.h"
#import "ItemPathModelView.h"

// From util
#import "UniqueTagsTransformer.h"
#import "ColorListCollection.h" // TODO: Move to util
#import "UniformType.h"

// From mapping
#import "FileItemMappingCollection.h"
#import "FileItemMappingScheme.h"

// From control
#import "ColorLegendTableViewControl.h"
#import "DirectoryViewControl.h"
#import "DirectoryViewControlSettings.h"
#import "DirectoryViewDisplaySettings.h"
#import "FilterPopUpControl.h"
#import "MainMenuControl.h"
#import "PreferencesPanelControl.h"

NSString  *CommentsChangedEvent = @"commentsChanged";
NSString  *DisplaySettingsChangedEvent = @"displaySettingsChanged";

/* Manages a group of related controls in the Focus panel.
 */
@interface ItemInFocusControls : NSObject {
  NSTextView  *pathTextView;
  NSTextField  *titleField;
  NSTextField  *exactSizeField;
  NSTextField  *sizeField;
}

@property (nonatomic) BOOL usesTallyFileSize;

- (instancetype) initWithPathTextView:(NSTextView *)textView
                           titleField:(NSTextField *)titleField
                       exactSizeField:(NSTextField *)exactSizeField
                            sizeField:(NSTextField *)sizeField NS_DESIGNATED_INITIALIZER;

/* Clears the controls.
 */
- (void) clear;

/* Show the details of the given item.
 */
- (void) showFileItem:(FileItem *)item treeContext:(TreeContext *)treeContext;

/* Show the details of the given item. The provided "pathString" and "sizeString" will be used (if
 * -showFileItem:treeContext: is invoked instead, these will be constructed before invoking this
 * method). Invoking this method directly is useful in cases where these have been constructed
 * already (to avoid having to do so twice).
 */
- (void) showFileItem:(FileItem *)item
             itemPath:(NSString *)pathString
           sizeString:(NSString *)sizeString;

/* Abstract method. Override to return title for the given item.
 */
- (NSString *)titleForFileItem:(FileItem *)item;

@end


/* Manages the "Item in view" controls in the Focus panel.
 */
@interface FolderInViewFocusControls : ItemInFocusControls {
}
@end


/* Manages the "Selected item" controls in the Focus panel.
 */
@interface SelectedItemFocusControls : ItemInFocusControls {
  NSTextField  *creationTimeField;
  NSTextField  *modificationTimeField;
  NSTextField  *accessTimeField;
}

- (instancetype) initWithPathTextView:(NSTextView *)textView
                           titleField:(NSTextField *)titleField
                       exactSizeField:(NSTextField *)exactSizeField
                            sizeField:(NSTextField *)sizeField
                    creationTimeField:(NSTextField *)creationTimeField
                modificationTimeField:(NSTextField *)modificationTimeField
                      accessTimeField:(NSTextField *)accessTimeField NS_DESIGNATED_INITIALIZER;

@end

@interface ControlPanelControl (PrivateMethods)

+ (NSString *)exactSizeStringForFileItem:(FileItem *)item;

- (void) fireDisplaySettingsChanged;

- (void) fileSizeUnitSystemChanged;

- (void) observeDirectoryView:(DirectoryViewControl *)dirViewControl;

- (void) updateDisplayPanel:(DirectoryViewControl *)dirViewControl;
- (void) updateInfoPanel:(DirectoryViewControl *)dirViewControl;
- (void) updateFocusPanel:(DirectoryViewControl *)dirViewControl;

- (void) visibleTreeChanged:(NSNotification *)notification;
- (void) selectedItemChanged:(NSNotification *)notification;
- (void) fileItemDeleted:(NSNotification *)notification;

- (void) maskRemoved:(NSNotification *)notification;
- (void) maskUpdated:(NSNotification *)notification;

@end

@implementation ControlPanelControl

- (id)init {
  NSAssert(singletonInstance == nil, @"Can only create one ControlPanelControl.");

  if ([super initWithWindow: nil]) {
    colorMappings = [[FileItemMappingCollection defaultFileItemMappingCollection] retain];
    colorPalettes = [[ColorListCollection defaultColorListCollection] retain];
    filterRepository = [[FilterRepository defaultInstance] retain];
  }

  return self;
}

- (void)dealloc {
  [visibleFolderFocusControls release];
  [selectedItemFocusControls release];
  [maskPopUpControl release];
  [colorLegendControl release];

  [colorMappings release];
  [colorPalettes release];
  [filterRepository release];

  [observedDirectoryView release];

  [super dealloc];
}

static ControlPanelControl  *singletonInstance = nil;

+ (ControlPanelControl *)singletonInstance {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    singletonInstance = [[self alloc] init];
  });
  return singletonInstance;
}

- (NSString *)windowNibName {
  return @"ControlPanel";
}

- (void)windowDidLoad {
  [super windowDidLoad];

  //----------------------------------------------------------------
  // Configure the "Display" panel

  UniqueTagsTransformer  *tagMaker = [UniqueTagsTransformer defaultUniqueTagsTransformer];

  [colorMappingPopUp removeAllItems];
  [tagMaker addLocalisedNames: [colorMappings allKeys]
                      toPopUp: colorMappingPopUp
                       select: nil // displaySettings.colorMappingKey
                        table: @"Names"];

  [colorPalettePopUp removeAllItems];
  [tagMaker addLocalisedNames: [colorPalettes allKeys]
                      toPopUp: colorPalettePopUp
                       select: nil // displaySettings.colorPaletteKey
                        table: @"Names"];

  maskPopUpControl = [[FilterPopUpControl alloc] initWithPopUpButton: maskPopUp
                                                    filterRepository: filterRepository];
  NSNotificationCenter  *nc = [maskPopUpControl notificationCenter];
  [nc addObserver: self
         selector: @selector(maskRemoved:)
             name: SelectedFilterRemoved
           object: maskPopUpControl];
  [nc addObserver: self
         selector: @selector(maskUpdated:)
             name: SelectedFilterUpdated
           object: maskPopUpControl];

  //----------------------------------------------------------------
  // Configure the "Info" panel

  [scanPathTextView setDrawsBackground: NO];
  [scanPathTextView.enclosingScrollView setDrawsBackground: NO];

  // Workaround a bug in the appkit. When the text is empty, it apparently does not take the color
  // as specified in Interface Builder.
  // See also: https://stackoverflow.com/questions/3643020/changing-text-color-of-nstextview-in-interface-builder-wont-work
  commentsTextView.textColor = NSColor.controlTextColor;

  //----------------------------------------------------------------
  // Configure the "Focus" panel

  visibleFolderFocusControls =
    [[FolderInViewFocusControls alloc]
        initWithPathTextView: visibleFolderPathTextView
                  titleField: visibleFolderTitleField
              exactSizeField: visibleFolderExactSizeField
                   sizeField: visibleFolderSizeField];

  selectedItemFocusControls =
    [[SelectedItemFocusControls alloc]
        initWithPathTextView: selectedItemPathTextView
                  titleField: selectedItemTitleField
              exactSizeField: selectedItemExactSizeField
                   sizeField: selectedItemSizeField
           creationTimeField: selectedItemCreationTimeField
       modificationTimeField: selectedItemModificationTimeField
             accessTimeField: selectedItemAccessTimeField];

  //----------------------------------------------------------------

  NSUserDefaults  *userDefaults = [NSUserDefaults standardUserDefaults];

  [userDefaults addObserver: self
                 forKeyPath: FileSizeUnitSystemKey
                    options: 0
                    context: nil];

  // Do not unnecessarily steal focus from the main window, as this prevents the latter from
  // letting selected item follow the mouse.
  ((NSPanel *)self.window).becomesKeyOnlyIfNeeded = YES;

  [self mainWindowChanged: nil];
}

- (void) observeValueForKeyPath:(NSString *)keyPath
                       ofObject:(id)object
                         change:(NSDictionary *)change
                        context:(void *)context {
  if (object == [NSUserDefaults standardUserDefaults]) {
    if ([keyPath isEqualToString: FileSizeUnitSystemKey]) {
      [self fileSizeUnitSystemChanged];
    }
  }
}

- (void) showInfoPanel {
  [self showWindow: self];

  [tabView selectFirstTabViewItem: self];
}

- (void) hidePanel {
  [self close];
}

// Invoked because the controller is the delegate for the window.
- (void) windowDidResignKey:(NSNotification *)notification {
  // Although it is not always the case that the comments changed when key focus was resigned,
  // there's not really any gain in checking this before firing the event. In practise, key status
  // is only obtained when the user clicks inside the comments text view to start editing. When
  // it is resigned without making any changes, there's no harm in the event being fired.
  [[NSNotificationCenter defaultCenter] postNotificationName: CommentsChangedEvent
                                                      object: self];
}

- (IBAction) displaySettingChanged:(id)sender {
  [self fireDisplaySettingsChanged];
}

- (IBAction) maskChanged:(id)sender {
  // Automatically enable the mask
  maskCheckBox.state = NSOnState;

  [self fireDisplaySettingsChanged];
}

- (void) mainWindowChanged:(id)sender {
  if (!self.isWindowLoaded) {
    return;
  }

  DirectoryViewControl  *dirViewControl =
    [NSApplication sharedApplication].mainWindow.windowController;
  if (dirViewControl == nil) {
    [[self window] setIsVisible: NO];

    return;
  }

  [self updateInfoPanel: dirViewControl];
  [self updateDisplayPanel: dirViewControl];
  [self updateFocusPanel: dirViewControl];

  [self observeDirectoryView: dirViewControl];
}


- (IBAction) showPackageContentsCheckBoxChanged:(id)sender {
  [self fireDisplaySettingsChanged];

  // If the selected item is a package, its info will have changed.
  [self selectedItemChanged: nil];
}

- (NSString *)comments {
  return commentsTextView.string;
}

- (DirectoryViewDisplaySettings *)displaySettings {
  UniqueTagsTransformer  *tagMaker = [UniqueTagsTransformer defaultUniqueTagsTransformer];

  NSString  *colorMappingKey = [tagMaker nameForTag: colorMappingPopUp.selectedItem.tag];
  NSString  *colorPaletteKey = [tagMaker nameForTag: colorPalettePopUp.selectedItem.tag];
  NSString  *maskName = [tagMaker nameForTag: maskPopUp.selectedItem.tag];

  DirectoryViewDisplaySettings *ds = [DirectoryViewDisplaySettings alloc];

  return [[ds initWithColorMappingKey: colorMappingKey
                      colorPaletteKey: colorPaletteKey
                             maskName: maskName
                          maskEnabled: maskCheckBox.state==NSOnState
                     showEntireVolume: showEntireVolumeCheckBox.state==NSOnState
                  showPackageContents: showPackageContentsCheckBox.state==NSOnState] autorelease];
}

- (TreeDrawerSettings *)instantiateDisplaySettings:(DirectoryViewDisplaySettings *)displaySettings
                                           forTree:(DirectoryItem *)tree {
  NSUserDefaults  *userDefaults = [NSUserDefaults standardUserDefaults];

  NSObject <FileItemMappingScheme>
    *mapping = [colorMappings fileItemMappingSchemeForKey: displaySettings.colorMappingKey];
  NSObject <FileItemMapping>  *mapper = nil;
  if (mapping != nil) {
    mapper = [mapping fileItemMappingForTree: tree];
  }

  NSColorList  *palette = [colorPalettes colorListForKey: displaySettings.colorPaletteKey];
  float  gradient = [userDefaults floatForKey: DefaultColorGradient];

  FileItemTest  *maskTest = nil;
  if (displaySettings.fileItemMaskEnabled) {
    Filter  *maskFilter = [filterRepository filterForName: displaySettings.maskName];
    if (maskFilter != nil) {
      NSMutableArray  *unboundTests = [NSMutableArray arrayWithCapacity: 8];
      maskTest = [maskFilter createFileItemTestUnboundTests: unboundTests];
      [MainMenuControl reportUnboundTests: unboundTests];
    }
  }

  TreeDrawerSettings *tds = [TreeDrawerSettings alloc];
  return [[tds initWithColorMapper: mapper
                      colorPalette: palette
                     colorGradient: gradient
                          maskTest: maskTest
               showPackageContents: displaySettings.showPackageContents] autorelease];
}

@end // @implementation ControlPanelControl

@implementation ControlPanelControl (PrivateMethods)

+ (NSString *)exactSizeStringForFileItem:(FileItem *)item {
  NSString  *format = NSLocalizedString(@"%qu bytes", @"Exact file size (in bytes)");

  return [NSString stringWithFormat: format, item.itemSize];
}

- (void)fireDisplaySettingsChanged {
  [[NSNotificationCenter defaultCenter] postNotificationName: DisplaySettingsChangedEvent
                                                      object: self];
}

/* Update all fields that report file size values.
 */
- (void) fileSizeUnitSystemChanged {
  DirectoryViewControl  *dirViewControl =
    [NSApplication sharedApplication].mainWindow.windowController;

  [self updateInfoPanel: dirViewControl];
  [self updateSelectionInFocusPanel: nil];

  [visibleFolderFocusControls showFileItem: dirViewControl.pathModelView.visibleTree
                               treeContext: dirViewControl.treeContext];
}

- (void) observeDirectoryView:(DirectoryViewControl *)dirViewControl {
  NSNotificationCenter  *nc = [NSNotificationCenter defaultCenter];

  if (observedDirectoryView != nil) {
    [nc removeObserver: self
                  name: SelectedItemChangedEvent
                object: observedDirectoryView.pathModelView];
    [nc removeObserver: self
                  name: VisibleTreeChangedEvent
                object: observedDirectoryView.pathModelView];
    [nc removeObserver: self
                  name: FileItemDeletedEvent
                object: observedDirectoryView.treeContext];

    [observedDirectoryView release];
  }

  [nc addObserver: self
         selector: @selector(selectedItemChanged:)
             name: SelectedItemChangedEvent
           object: dirViewControl.pathModelView];
  [nc addObserver: self
         selector: @selector(visibleTreeChanged:)
             name: VisibleTreeChangedEvent
           object: dirViewControl.pathModelView];
  [nc addObserver: self
         selector: @selector(fileItemDeleted:)
             name: FileItemDeletedEvent
           object: dirViewControl.treeContext];

  observedDirectoryView = [dirViewControl retain];
}

- (void) updateDisplayPanel:(DirectoryViewControl *)dirViewControl {
  DirectoryViewDisplaySettings  *displaySettings =
    [dirViewControl directoryViewControlSettings].displaySettings;

  UniqueTagsTransformer  *tagMaker = [UniqueTagsTransformer defaultUniqueTagsTransformer];

  [colorMappingPopUp selectItemWithTag: [tagMaker tagForName: displaySettings.colorMappingKey]];
  [colorPalettePopUp selectItemWithTag: [tagMaker tagForName: displaySettings.colorPaletteKey]];

  [colorLegendControl release];
  colorLegendControl =
    [[ColorLegendTableViewControl alloc] initWithDirectoryView: dirViewControl.directoryView
                                                     tableView: colorLegendTable];

  maskCheckBox.state = displaySettings.fileItemMaskEnabled ? NSOnState : NSOffState;
  [maskPopUpControl selectFilterNamed: displaySettings.maskName];

  if ([dirViewControl.treeContext usesTallyFileSize]) {
    // Never show the entire volume when using the tally file size measure. It does not make sense.
    showEntireVolumeCheckBox.state = NSOffState;
    showEntireVolumeCheckBox.enabled = NO;
  } else {
    showEntireVolumeCheckBox.state = displaySettings.showEntireVolume ? NSOnState : NSOffState;
  }

  showPackageContentsCheckBox.state = displaySettings.showPackageContents ? NSOnState : NSOffState;
}

- (void) updateInfoPanel:(DirectoryViewControl *)dirViewControl {
  NSBundle  *mainBundle = [NSBundle mainBundle];
  NSUserDefaults  *userDefaults = [NSUserDefaults standardUserDefaults];

  FileItem  *volumeTree = dirViewControl.pathModelView.volumeTree;
  FileItem  *scanTree = dirViewControl.pathModelView.scanTree;

  NSString  *volumeName = [volumeTree systemPath];
  NSImage  *volumeIcon = [[NSWorkspace sharedWorkspace] iconForFile: volumeName];
  volumeIconView.image = volumeIcon;
  volumeNameField.stringValue = [[NSFileManager defaultManager] displayNameAtPath: volumeName];

  scanPathTextView.string = [scanTree path];
  commentsTextView.string = dirViewControl.comments;

  TreeContext  *treeContext = dirViewControl.treeContext;
  FilterSet  *filterSet = [treeContext filterSet];
  filterNameField.stringValue = ( ([filterSet fileItemTest] != nil)
    ? filterSet.description
    : NSLocalizedString(@"None", @"The filter name when there is no filter.") ) ;

  scanTimeField.stringValue = [treeContext stringForScanTime];
  fileSizeMeasureField.stringValue = [NSString stringWithFormat: @"%@ (%@)",
    [mainBundle localizedStringForKey: [treeContext fileSizeMeasure]
                                value: nil
                                table: @"Names"],
    [mainBundle localizedStringForKey: [userDefaults stringForKey: FileSizeUnitSystemKey]
                                value: nil
                                table: @"Names"]];

  volumeSizeField.stringValue = [FileItem stringForFileItemSize: volumeTree.itemSize];
  if ([dirViewControl.treeContext usesTallyFileSize]) {
    treeSizeField.stringValue = @"-";
    miscUsedSpaceField.stringValue = @"-";
    freeSpaceField.stringValue = @"-";
    freedSpaceField.stringValue = @"-";
  } else {
    treeSizeField.stringValue = [FileItem stringForFileItemSize: scanTree.itemSize];
    miscUsedSpaceField.stringValue = [FileItem stringForFileItemSize: treeContext.miscUsedSpace];
    freeSpaceField.stringValue = [FileItem stringForFileItemSize: treeContext.freeSpace];
    freedSpaceField.stringValue = [FileItem stringForFileItemSize: treeContext.freedSpace];
  }
  numScannedFilesField.stringValue = [NSString stringWithFormat: @"%qu", scanTree.numFiles];
  numDeletedFilesField.stringValue = [NSString stringWithFormat: @"%qu", treeContext.freedFiles];
}

- (void) updateFocusPanel:(DirectoryViewControl *)dirViewControl {
  BOOL usesTallyFileSize = [dirViewControl.treeContext usesTallyFileSize];

  visibleFolderFocusControls.usesTallyFileSize = usesTallyFileSize;
  selectedItemFocusControls.usesTallyFileSize = usesTallyFileSize;

  [self visibleTreeChanged: nil];
  [self selectedItemChanged: nil];
}

- (void) updateSelectionInFocusPanel:(NSString *)itemSizeString {
  DirectoryViewControl  *dirViewControl =
    [NSApplication sharedApplication].mainWindow.windowController;

  FileItem  *selectedItem = dirViewControl.pathModelView.selectedFileItem;

  // Construct size string unless provided (which can be used to avoid repeated construction)
  if (itemSizeString == nil) {
    itemSizeString = [dirViewControl.treeContext stringForFileItemSize: selectedItem.itemSize];
  }

  if ( selectedItem != nil ) {
    NSString  *itemPath;

    if (! [selectedItem isPhysical]) {
      itemPath = [[NSBundle mainBundle] localizedStringForKey: [selectedItem label]
                                                        value: nil table: @"Names"];
    }
    else {
      itemPath = [selectedItem path];
    }

    [selectedItemFocusControls showFileItem: selectedItem
                                   itemPath: itemPath
                                 sizeString: itemSizeString];
  }
  else {
    [selectedItemFocusControls clear];
  }

  // Update the file type fields in the Focus panel
  if ( selectedItem != nil &&
       [selectedItem isPhysical] &&
       ![selectedItem isDirectory] ) {
    UniformType  *type = [ ((PlainFileItem *)selectedItem) uniformType];

    selectedItemTypeIdentifierField.stringValue = [type uniformTypeIdentifier];
    selectedItemTypeIdentifierField.toolTip =
      [type description] != nil ? [type description] : [type uniformTypeIdentifier];
  }
  else {
    selectedItemTypeIdentifierField.stringValue = @"";
    [selectedItemTypeIdentifierField setToolTip: nil];
  }
}

- (void) visibleTreeChanged:(NSNotification *)notification {
  DirectoryViewControl  *dirViewControl =
    [NSApplication sharedApplication].mainWindow.windowController;

  [visibleFolderFocusControls showFileItem: dirViewControl.pathModelView.visibleTree
                               treeContext: dirViewControl.treeContext];
}

- (void) selectedItemChanged:(NSNotification *)notification {
  [self updateSelectionInFocusPanel: nil]; // TODO: Take size from notification
}

- (void) fileItemDeleted:(NSNotification *)notification {
  DirectoryViewControl  *dirViewControl =
    [NSApplication sharedApplication].mainWindow.windowController;
  TreeContext  *treeContext = dirViewControl.treeContext;

  freedSpaceField.stringValue = [FileItem stringForFileItemSize: [treeContext freedSpace]];
  numDeletedFilesField.stringValue = [NSString stringWithFormat: @"%qu", [treeContext freedFiles]];
}

- (void) maskRemoved:(NSNotification *)notification {
  maskCheckBox.state = NSOffState;

  [self fireDisplaySettingsChanged];
}

- (void) maskUpdated:(NSNotification *)notification {
  [self fireDisplaySettingsChanged];
}

@end // @implementation ControlPanelControl (PrivateMethods)

@implementation ItemInFocusControls

// Overrides designated initialiser
- (instancetype) init {
  NSAssert(NO, @"Use initWithPathTextView:... instead");
  return [self initWithPathTextView: nil titleField: nil exactSizeField: nil sizeField: nil];
}

- (instancetype) initWithPathTextView:(NSTextView *)pathTextViewVal
                           titleField:(NSTextField *)titleFieldVal
                       exactSizeField:(NSTextField *)exactSizeFieldVal
                            sizeField:(NSTextField *)sizeFieldVal {
  if (self = [super init]) {
    pathTextView = [pathTextViewVal retain];
    titleField = [titleFieldVal retain];
    exactSizeField = [exactSizeFieldVal retain];
    sizeField = [sizeFieldVal retain];
  }

  return self;
}

- (void) dealloc {
  [titleField release];
  [pathTextView release];
  [exactSizeField release];
  [sizeField release];

  [super dealloc];
}


- (void) clear {
  titleField.stringValue = [self titleForFileItem: nil];
  pathTextView.string = @"";
  exactSizeField.stringValue = @"";
  sizeField.stringValue = @"";
}

- (void) showFileItem:(FileItem *)item treeContext:(TreeContext *)treeContext  {
  NSString  *sizeString = [treeContext stringForFileItemSize: item.itemSize];
  NSString  *itemPath =
    ( [item isPhysical]
      ? [item path]
      : [[NSBundle mainBundle] localizedStringForKey: [item label] value: nil table: @"Names"] );

  [self showFileItem: item itemPath: itemPath sizeString: sizeString];
}

- (void) showFileItem:(FileItem *)item
             itemPath:(NSString *)pathString
           sizeString:(NSString *)sizeString {
  titleField.stringValue = [self titleForFileItem: item];

  pathTextView.string = pathString;
  if (self.usesTallyFileSize) {
    exactSizeField.stringValue = @"";
    sizeField.stringValue = sizeString;
  } else {
    exactSizeField.stringValue = [ControlPanelControl exactSizeStringForFileItem: item];
    sizeField.stringValue = [NSString stringWithFormat: @"(%@)", sizeString];
  }

  // Use the color of the size fields to show if the item is hard-linked.
  NSColor *sizeFieldColor = [item isHardLinked] ? [NSColor darkGrayColor] : titleField.textColor;
  exactSizeField.textColor = sizeFieldColor;
  sizeField.textColor = sizeFieldColor;
}

- (NSString *) titleForFileItem: (FileItem *)item {
  NSAssert(NO, @"Abstract method");
  return nil;
}

@end // @implementation ItemInFocusControls


@implementation FolderInViewFocusControls

- (NSString *)titleForFileItem:(FileItem *)item {
  if ( ! [item isPhysical] ) {
    return NSLocalizedString(@"Area in view:", "Label in Focus panel");
  }
  else if ( [item isPackage] ) {
    return NSLocalizedString(@"Package in view:", "Label in Focus panel");
  }
  else if ( [item isDirectory] ) {
    return NSLocalizedString(@"Folder in view:", "Label in Focus panel");
  }
  else { // Default, also used when item == nil
    return NSLocalizedString(@"File in view:", "Label in Focus panel");
  }
}

@end // @implementation FolderInViewFocusControls


@implementation SelectedItemFocusControls

// Overrides designated initialiser
- (instancetype) initWithPathTextView:(NSTextView *)textView
                           titleField:(NSTextField *)titleField
                       exactSizeField:(NSTextField *)exactSizeField
                            sizeField:(NSTextField *)sizeField {
  NSAssert(NO, @"Use other initialiser instead");
  return [self initWithPathTextView: nil titleField: nil exactSizeField: nil sizeField: nil
                  creationTimeField: nil modificationTimeField: nil accessTimeField: nil];
}

- (instancetype) initWithPathTextView:(NSTextView *)textViewVal
                           titleField:(NSTextField *)titleFieldVal
                       exactSizeField:(NSTextField *)exactSizeFieldVal
                            sizeField:(NSTextField *)sizeFieldVal
                    creationTimeField:(NSTextField *)creationTimeFieldVal
                modificationTimeField:(NSTextField *)modificationTimeFieldVal
                      accessTimeField:(NSTextField *)accessTimeFieldVal {
  if (self = [super initWithPathTextView: textViewVal
                              titleField: titleFieldVal
                          exactSizeField: exactSizeFieldVal
                               sizeField: sizeFieldVal]) {
    creationTimeField = [creationTimeFieldVal retain];
    modificationTimeField = [modificationTimeFieldVal retain];
    accessTimeField = [accessTimeFieldVal retain];
  }
  return self;
}

- (void) dealloc {
  [creationTimeField release];
  [modificationTimeField release];
  [accessTimeField release];

  [super dealloc];
}

- (void) showFileItem:(FileItem *)item
             itemPath:(NSString *)pathString
           sizeString:(NSString *)sizeString {
  [super showFileItem: item itemPath: pathString sizeString: sizeString];

  creationTimeField.stringValue = [FileItem stringForTime: [item creationTime]];
  modificationTimeField.stringValue = [FileItem stringForTime: [item modificationTime]];
  accessTimeField.stringValue = [FileItem stringForTime: [item accessTime]];
}

- (NSString *)titleForFileItem:(FileItem *)item {
  if ( ! [item isPhysical] ) {
    return NSLocalizedString(@"Selected area:", "Label in Focus panel");
  }
  else if ( [item isPackage] ) {
    return NSLocalizedString(@"Selected package:", "Label in Focus panel");
  }
  else if ( [item isDirectory] ) {
    return NSLocalizedString(@"Selected folder:", "Label in Focus panel");
  }
  else { // Default, also used when item == nil
    return NSLocalizedString(@"Selected file:", "Label in Focus panel");
  }
}

@end // @implementation SelectedItemFocusControls
