#import "DirectoryViewToolbarControl.h"

#import "DirectoryViewControl.h"
#import "DirectoryView.h"
#import "ToolbarSegmentedCell.h"
#import "MainMenuControl.h"
#import "KBPopUpToolbarItem.h"


NSString  *ToolbarZoom = @"Zoom"; 
NSString  *ToolbarFocus = @"Focus"; 
NSString  *ToolbarOpenItem = @"OpenItem";
NSString  *ToolbarPreviewItem = @"PreviewItem";
NSString  *ToolbarRevealItem = @"RevealItem";
NSString  *ToolbarDeleteItem = @"DeleteItem";
NSString  *ToolbarRescan = @"Rescan";
NSString  *ToolbarToggleDrawer = @"ToggleDrawer";


// Tags for each of the segments in the Zoom and Focus controls, so that the 
// order can be changed in the nib file.
#define  ZOOM_IN_TAG     100
#define  ZOOM_OUT_TAG    101
#define  FOCUS_UP_TAG    102
#define  FOCUS_DOWN_TAG  103
#define  ZOOM_RESET_TAG  104
#define  FOCUS_RESET_TAG 105


@interface DirectoryViewToolbarControl (PrivateMethods)

/* Registers that the given selector should be used for creating the toolbar item with the given
 * identifier.
 */
- (void) createToolbarItem:(NSString *)identifier usingSelector:(SEL)selector;

- (NSToolbarItem *)zoomToolbarItem;
- (NSToolbarItem *)focusToolbarItem;
- (NSToolbarItem *)openItemToolbarItem;
- (NSToolbarItem *)previewItemToolbarItem;
- (NSToolbarItem *)revealItemToolbarItem;
- (NSToolbarItem *)deleteItemToolbarItem;
- (NSToolbarItem *)rescanToolbarItem;
- (NSToolbarItem *)toggleDrawerToolbarItem;

- (id) validateZoomControls:(NSToolbarItem *)toolbarItem;
- (id) validateFocusControls:(NSToolbarItem *)toolbarItem;

- (BOOL) validateAction:(SEL)action;


- (void) zoom:(id)sender;
- (void) focus:(id)sender;

- (void) zoomOut:(id)sender;
- (void) zoomIn:(id)sender;
- (void) resetZoom:(id)sender;

- (void) moveFocusUp:(id)sender;
- (void) moveFocusDown:(id)sender;
- (void) resetFocus:(id)sender;

// Methods corresponding to methods in DirectoryViewControl
- (void) openFile:(id)sender;
- (void) previewFile:(id)sender;
- (void) revealFileInFinder:(id)sender;
- (void) deleteFile:(id)sender;

// Methods corresponding to methods in MainMenuControl
- (void) rescan:(id)sender;
- (void) rescanAll:(id)sender;
- (void) rescanVisible:(id)sender;
- (void) rescanSelected:(id)sender;

@end


@interface ToolbarItemMenu : NSMenuItem {
}

- (id) initWithTitle:(NSString *)title target:(id)target;

- (NSMenuItem *) addAction:(SEL)action withTitle:(NSString *)title;

@end


@interface SelectorObject : NSObject {
  SEL  selector;
}

- (id) initWithSelector:(SEL)selector;

- (SEL) selector;

@end


@interface ValidatingToolbarItem : NSToolbarItem {
  NSObject  *validator;
  SEL  validationSelector;
}

- (id) initWithItemIdentifier:(NSString *)identifier
                    validator:(NSObject *)validator
           validationSelector:(SEL)validationSelector;

@end


@implementation DirectoryViewToolbarControl

- (id) init {
  if (self = [super init]) {
    dirViewControl = nil; // Will be set when loaded from nib.
    
    // Set defaults (can be overridden when segments are tagged)
    zoomInSegment = 0;
    zoomOutSegment = 1;
    focusUpSegment = 0;
    focusDownSegment = 1;
  }
  return self;
}

- (void) dealloc {
  // We were not retaining it, so should not call -release 
  dirViewControl = nil;

  [super dealloc];
}


- (void) awakeFromNib {
  // Not retaining it. It needs to be deallocated when the window is closed.
  dirViewControl = [dirViewWindow windowController];
  
  // Replace the cells, so that they always remain at normal size.
  [zoomControls setCell:
   [[[ToolbarSegmentedCell alloc] initWithSegmentedCell: [zoomControls cell]] autorelease]];
  [focusControls setCell:
   [[[ToolbarSegmentedCell alloc] initWithSegmentedCell: [focusControls cell]] autorelease]];

  // Disable auto-layout for toolbar controls. This is apparantly needed for the toolbar to be layed
  // out correctly.
  [zoomControls setTranslatesAutoresizingMaskIntoConstraints: YES];
  [focusControls setTranslatesAutoresizingMaskIntoConstraints: YES];

  // Set the actions for the controls. This is not done in Interface Builder as changing the cells
  // resets it again. Furthermore, might as well do it here once, as opposed to in all (localized)
  // versions of the NIB file.
  [zoomControls setTarget: self];
  [zoomControls setAction: @selector(zoom:)]; 
  [focusControls setTarget: self];
  [focusControls setAction: @selector(focus:)];
  
  NSUInteger  i;
  
  // Check if tags have been used to change default segment ordering 
  i = [zoomControls segmentCount];
  while (i-- > 0) {
    NSUInteger  tag = [[zoomControls cell] tagForSegment: i];
    switch (tag) {
      case ZOOM_IN_TAG:
        zoomInSegment = i; break;
      case ZOOM_OUT_TAG:
        zoomOutSegment = i; break;
      case ZOOM_RESET_TAG:
        zoomResetSegment = i; break;
    }
  }

  i = [focusControls segmentCount];
  while (i-- > 0) {
    NSUInteger  tag = [[focusControls cell] tagForSegment: i];
    switch (tag) {
      case FOCUS_UP_TAG:
        focusUpSegment = i; break;
      case FOCUS_DOWN_TAG:
        focusDownSegment = i; break;
      case FOCUS_RESET_TAG:
        focusResetSegment = i; break;
    }
  }

  
  NSToolbar  *toolbar = 
    [[[NSToolbar alloc] initWithIdentifier: @"DirectoryViewToolbar"] 
         autorelease];
           
  [toolbar setAllowsUserCustomization: YES];
  [toolbar setAutosavesConfiguration: YES]; 
  [toolbar setDisplayMode: NSToolbarDisplayModeIconAndLabel];

  [toolbar setDelegate: self];
  [[dirViewControl window] setToolbar: toolbar];
}


NSMutableDictionary  *createToolbarItemLookup = nil;

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar
     itemForItemIdentifier:(NSString *)itemIdentifier
 willBeInsertedIntoToolbar:(BOOL)flag {
  if (createToolbarItemLookup == nil) {
    createToolbarItemLookup = [[NSMutableDictionary alloc] initWithCapacity: 8];

    [self createToolbarItem: ToolbarZoom
              usingSelector: @selector(zoomToolbarItem)];
    [self createToolbarItem: ToolbarFocus
              usingSelector: @selector(focusToolbarItem)];
    [self createToolbarItem: ToolbarOpenItem 
              usingSelector: @selector(openItemToolbarItem)];
    [self createToolbarItem: ToolbarPreviewItem
              usingSelector: @selector(previewItemToolbarItem)];
    [self createToolbarItem: ToolbarRevealItem
              usingSelector: @selector(revealItemToolbarItem)];
    [self createToolbarItem: ToolbarDeleteItem 
              usingSelector: @selector(deleteItemToolbarItem)];
    [self createToolbarItem: ToolbarRescan 
              usingSelector: @selector(rescanToolbarItem)];
    [self createToolbarItem: ToolbarToggleDrawer
              usingSelector: @selector(toggleDrawerToolbarItem)];
  }
  
  SelectorObject  *selObj = [createToolbarItemLookup objectForKey: itemIdentifier];
  if (selObj == nil) {
    // May happen when user preferences refers to old/outdated toolbar items
    NSLog(@"Unrecognized toolbar item: %@", itemIdentifier);
    return nil;
  }
  
  return [self performSelector: [selObj selector]];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar {
    return [NSArray arrayWithObjects:
                      ToolbarZoom, ToolbarFocus,
                      NSToolbarSpaceItemIdentifier, 
                      ToolbarOpenItem, ToolbarPreviewItem,
                      ToolbarRevealItem, ToolbarDeleteItem,
                      NSToolbarSpaceItemIdentifier, 
                      ToolbarRescan,
                      NSToolbarFlexibleSpaceItemIdentifier, 
                      ToolbarToggleDrawer, nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar {
    return [NSArray arrayWithObjects:
                      ToolbarZoom, ToolbarFocus,
                      ToolbarOpenItem, ToolbarPreviewItem,
                      ToolbarRevealItem, ToolbarDeleteItem,
                      ToolbarRescan,
                      ToolbarToggleDrawer, 
                      NSToolbarSeparatorItemIdentifier, 
                      NSToolbarSpaceItemIdentifier, 
                      NSToolbarFlexibleSpaceItemIdentifier, nil];
}

@end


@implementation DirectoryViewToolbarControl (PrivateMethods)

- (void) createToolbarItem:(NSString *)identifier
             usingSelector:(SEL)selector {
  id  obj = [[[SelectorObject alloc] initWithSelector: selector] autorelease];

  [createToolbarItemLookup setObject: obj forKey: identifier];
}


- (NSToolbarItem *) zoomToolbarItem {
  NSToolbarItem  *item =
    [[[ValidatingToolbarItem alloc] initWithItemIdentifier: ToolbarZoom
                                                 validator: self
                                         validationSelector: @selector(validateZoomControls:)]
     autorelease];

  NSString  *title = NSLocalizedStringFromTable(@"Zoom", @"Toolbar", @"Label for zooming controls");
  NSString  *zoomOutTitle = NSLocalizedStringFromTable(@"Zoom out", @"Toolbar", @"Toolbar action");
  NSString  *zoomInTitle = NSLocalizedStringFromTable(@"Zoom in", @"Toolbar", @"Toolbar action");
  NSString  *resetTitle = NSLocalizedStringFromTable(@"Reset zoom", @"Toolbar", @"Toolbar action");

  [item setLabel: title];
  [item setPaletteLabel: [item label]];
  [item setView: zoomControls];
  [item setMinSize: [zoomControls bounds].size];
  [item setMaxSize: [zoomControls bounds].size];
  
  // Tool tips set here (as opposed to Interface Builder) so that all toolbar-related text is in the
  // same file, to facilitate localization.
  [[zoomControls cell] setToolTip: zoomInTitle  forSegment: zoomInSegment];
  [[zoomControls cell] setToolTip: zoomOutTitle forSegment: zoomOutSegment];
  [[zoomControls cell] setToolTip: resetTitle   forSegment: zoomResetSegment];

  ToolbarItemMenu  *menu =
    [[[ToolbarItemMenu alloc] initWithTitle: title target: self] autorelease];
  NSMenuItem  *zoomOutItem = [menu addAction: @selector(zoomOut:) withTitle: zoomOutTitle];
  NSMenuItem  *zoomInItem = [menu addAction: @selector(zoomIn:) withTitle: zoomInTitle];
  NSMenuItem  *zoomResetItem __unused =
    [menu addAction: @selector(resetZoom:) withTitle: resetTitle];

  // Set the key equivalents so that they show up in the menu (which may help to make the user aware
  // of them or remind the user of them). They do not actually have an effect. Handling these key
  // equivalents is handled in the DirectoryView class.
  [zoomOutItem setKeyEquivalent: @"-"];
  [zoomOutItem setKeyEquivalentModifierMask: NSCommandKeyMask];
  
  [zoomInItem setKeyEquivalent: @"+"];
  [zoomInItem setKeyEquivalentModifierMask: NSCommandKeyMask];

  [item setMenuFormRepresentation: menu];

  return item;
}

- (NSToolbarItem *)focusToolbarItem {
  NSToolbarItem  *item =
    [[[ValidatingToolbarItem alloc] initWithItemIdentifier: ToolbarFocus
                                                 validator: self
                                        validationSelector: @selector(validateFocusControls:)]
     autorelease];

  NSString  *title = NSLocalizedStringFromTable(@"Focus", @"Toolbar", @"Label for focus controls");
  NSString  *moveUpTitle =
    NSLocalizedStringFromTable(@"Move focus up", @"Toolbar", @"Toolbar action");
  NSString  *moveDownTitle =
    NSLocalizedStringFromTable(@"Move focus down", @"Toolbar", @"Toolbar action");
  NSString  *resetTitle = NSLocalizedStringFromTable(@"Reset focus", @"Toolbar", @"Toolbar action");

  [item setLabel: title];
  [item setPaletteLabel: [item label]];
  [item setView: focusControls];
  [item setMinSize: [focusControls bounds].size];
  [item setMaxSize: [focusControls bounds].size];

  // Tool tips set here (as opposed to Interface Builder) so that all toolbar-related text is in the
  // same file, to facilitate localization.
  [[focusControls cell] setToolTip: moveDownTitle forSegment: focusDownSegment];
  [[focusControls cell] setToolTip: moveUpTitle   forSegment: focusUpSegment];
  [[focusControls cell] setToolTip: resetTitle    forSegment: focusResetSegment];

  ToolbarItemMenu  *menu =
    [[[ToolbarItemMenu alloc] initWithTitle: title target: self] autorelease];
  NSMenuItem  *focusUpItem = [menu addAction: @selector(moveFocusUp:) withTitle: moveUpTitle];
  NSMenuItem  *focusDownItem = [menu addAction: @selector(moveFocusDown:) withTitle: moveDownTitle];
  NSMenuItem  *focusResetItem __unused =
    [menu addAction: @selector(resetFocus:) withTitle: resetTitle];

  // Set the key equivalents so that they show up in the menu (which may help to make the user aware
  // of them or remind the user of them). They do not actually have an effect. Handling these key
  // equivalents is handled in the DirectoryView class.
  [focusUpItem setKeyEquivalent: @"["];
  [focusUpItem setKeyEquivalentModifierMask: NSCommandKeyMask];
  
  [focusDownItem setKeyEquivalent: @"]"];
  [focusDownItem setKeyEquivalentModifierMask: NSCommandKeyMask];

  [item setMenuFormRepresentation: menu];

  return item;
}

- (NSToolbarItem *)openItemToolbarItem {
  NSToolbarItem  *item =
    [[[NSToolbarItem alloc] initWithItemIdentifier: ToolbarOpenItem] autorelease];

  [item setLabel: NSLocalizedStringFromTable(@"Open", @"Toolbar", @"Toolbar action")];
  [item setPaletteLabel: [item label]];
  [item setToolTip: NSLocalizedStringFromTable(@"Open with Finder", @"Toolbar", @"Tooltip")];
  [item setImage: [NSImage imageNamed: @"OpenWithFinder"]];
  [item setAction: @selector(openFile:)];
  [item setTarget: self];

  return item;
}

- (NSToolbarItem *)previewItemToolbarItem {
  NSToolbarItem  *item =
    [[[NSToolbarItem alloc] initWithItemIdentifier: ToolbarPreviewItem] autorelease];

  [item setLabel: NSLocalizedStringFromTable(@"Quick Look", @"Toolbar", @"Toolbar action")];
  [item setPaletteLabel: [item label]];
  [item setToolTip:
    NSLocalizedStringFromTable(@"Preview item in Quick Look panel", @"Toolbar", @"Tooltip")];
  [item setImage: [NSImage imageNamed: @"QuickLook"]];
  [item setAction: @selector(previewFile:)];
  [item setTarget: self];

  return item;
}

- (NSToolbarItem *)revealItemToolbarItem {
  NSToolbarItem  *item = 
    [[[NSToolbarItem alloc] initWithItemIdentifier: ToolbarRevealItem] autorelease];

  [item setLabel: NSLocalizedStringFromTable( @"Reveal", @"Toolbar", 
                                              @"Toolbar action" )];
  [item setPaletteLabel: [item label]];
  [item setToolTip: NSLocalizedStringFromTable( @"Reveal in Finder", 
                                                @"Toolbar", @"Tooltip" )];
  [item setImage: [NSImage imageNamed: @"RevealInFinder"]];
  [item setAction: @selector(revealFileInFinder:)];
  [item setTarget: self];

  return item;
}

- (NSToolbarItem *)deleteItemToolbarItem {
  NSToolbarItem  *item = 
    [[[NSToolbarItem alloc] initWithItemIdentifier: ToolbarDeleteItem] autorelease];

  [item setLabel: NSLocalizedStringFromTable(@"Delete", @"Toolbar", @"Toolbar action")];
  [item setPaletteLabel: [item label]];
  [item setToolTip: NSLocalizedStringFromTable(@"Move to trash", @"Toolbar", @"Tooltip")];
  [item setImage: [NSImage imageNamed: @"Delete"]];
  [item setAction: @selector(deleteFile:)];
  [item setTarget: self];

  return item;
}

- (NSToolbarItem *)rescanToolbarItem {
  KBPopUpToolbarItem  *item = 
    [[[KBPopUpToolbarItem alloc] initWithItemIdentifier: ToolbarRescan] autorelease];

  [item setLabel: NSLocalizedStringFromTable(@"Rescan", @"Toolbar", @"Toolbar action")];
  [item setPaletteLabel: [item label]];
  [item setToolTip: NSLocalizedStringFromTable(@"Rescan view data", @"Toolbar", @"Tooltip")];
  [item setImage: [NSImage imageNamed: @"Rescan"]];
  [item setAction: @selector(rescan:)];
  [item setTarget: self];
  
  NSString  *rescanAllTitle =
    NSLocalizedStringFromTable(@"Rescan all", @"Toolbar", @"Toolbar action");
  NSString  *rescanVisibleTitle =
    NSLocalizedStringFromTable(@"Rescan folder in view", @"Toolbar", @"Toolbar action");
  NSString  *rescanSelectedTitle =
    NSLocalizedStringFromTable(@"Rescan selected", @"Toolbar", @"Toolbar action");

  NSMenu  *menu = [[NSMenu alloc] initWithTitle: @"Rescan actions"];
  int  itemCount = 0;

  NSMenuItem  *rescanAllItem = [menu insertItemWithTitle: rescanAllTitle
                                                  action: @selector(rescanAll:)
                                           keyEquivalent: @""
                                                 atIndex: itemCount++];
  [rescanAllItem setTarget: self];

  NSMenuItem  *rescanVisibleItem = [menu insertItemWithTitle: rescanVisibleTitle
                                                      action: @selector(rescanVisible:)
                                               keyEquivalent: @""
                                                     atIndex: itemCount++];
  [rescanVisibleItem setTarget: self];

  NSMenuItem  *rescanSelectedItem = [menu insertItemWithTitle: rescanSelectedTitle
                                                       action: @selector(rescanSelected:)
                                                keyEquivalent: @""
                                                      atIndex: itemCount++];
  [rescanSelectedItem setTarget: self];

  [menu setAutoenablesItems: YES];
  [item setMenu: menu];

  return item;
}

- (NSToolbarItem *)toggleDrawerToolbarItem {
  NSToolbarItem  *item = 
    [[[NSToolbarItem alloc] initWithItemIdentifier: ToolbarToggleDrawer] autorelease];

  [item setLabel: NSLocalizedStringFromTable(@"Drawer", @"Toolbar", @"Toolbar action")];
  [item setPaletteLabel: [item label]];
  [item setToolTip: NSLocalizedStringFromTable(@"Open/close drawer", @"Toolbar", "Tooltip")];
  [item setImage: [NSImage imageNamed: @"ToggleDrawer"]];
  [item setAction: @selector(toggleDrawer:)];
  [item setTarget: dirViewControl];

  return item;
}


- (id) validateZoomControls:(NSToolbarItem *)toolbarItem {
  NSSegmentedControl  *control = (NSSegmentedControl *)[toolbarItem view];
  DirectoryView  *dirView = [dirViewControl directoryView];

  [control setEnabled: [dirView canZoomOut] forSegment: zoomOutSegment];
  [control setEnabled: [dirView canZoomIn] forSegment: zoomInSegment];
  [control setEnabled: [dirView canZoomOut] forSegment: zoomResetSegment];

  return self; // Always enable the overall control
}

- (id) validateFocusControls:(NSToolbarItem *)toolbarItem {
  NSSegmentedControl  *control = (NSSegmentedControl *)[toolbarItem view];
  DirectoryView  *dirView = [dirViewControl directoryView];

  [control setEnabled: [dirView canMoveFocusUp] forSegment: focusUpSegment];
  [control setEnabled: [dirView canMoveFocusDown] forSegment: focusDownSegment];
  [control setEnabled: [dirView canMoveFocusDown] forSegment: focusResetSegment];

  return self; // Always enable the overall control
}


- (BOOL) validateToolbarItem:(NSToolbarItem *)item {
  return [self validateAction: [item action]];
}

- (BOOL) validateMenuItem:(NSMenuItem *)item {
  return [self validateAction: [item action]];
}
  

- (BOOL) validateAction:(SEL)action {
  if ( action == @selector(zoomOut:) ||
       action == @selector(resetZoom:) ) {
    return [[dirViewControl directoryView] canZoomOut];
  }
  else if ( action == @selector(zoomIn:) ) {
    return [[dirViewControl directoryView] canZoomIn];
  }
  if ( action == @selector(moveFocusUp:) ) {
    return [[dirViewControl directoryView] canMoveFocusUp];
  }
  else if ( action == @selector(moveFocusDown:) ||
            action == @selector(resetFocus:) ) {
    return [[dirViewControl directoryView] canMoveFocusDown];
  }
  else if ( action == @selector(openFile:) ||
            action == @selector(previewFile:) ||
            action == @selector(revealFileInFinder:) ||
            action == @selector(deleteFile:) ) {
    return ( [dirViewControl validateAction: action] &&
    
             // Selection must be locked, as it would otherwise change when the mouse is moved in
             // order to click on the toolbar button.
             [dirViewControl isSelectedFileLocked] );
  }
  else if ( action == @selector(rescanSelected:) ) {
    return ( [[[NSApplication sharedApplication] mainWindow] windowController] == dirViewControl &&
    
             // Selection must be locked (see above)
             [dirViewControl isSelectedFileLocked] );
  }
  else if ( action == @selector(rescan:) ||
            action == @selector(rescanAll:) ||
            action == @selector(rescanVisible:) ) {
    return [[[NSApplication sharedApplication] mainWindow] windowController] == dirViewControl;
  }
  else {
    NSLog(@"Unrecognized action %@", NSStringFromSelector(action));
    return NO;
  }
}


- (void) zoom:(id)sender {
  NSUInteger  selected = [sender selectedSegment];

  if (selected == zoomInSegment) {
    [self zoomIn: sender];
  }
  else if (selected == zoomOutSegment) {
    [self zoomOut: sender];
  }
  else if (selected == zoomResetSegment) {
    [self resetZoom: sender];
  }
  else {
    NSAssert1(NO, @"Unexpected selected segment: %lu", (unsigned long)selected);
  }
}


- (void) focus:(id)sender {
  NSUInteger  selected = [sender selectedSegment];
  
  if ([sender selectedSegment] == focusDownSegment) {
    [self moveFocusDown: sender];
  }
  else if ([sender selectedSegment] == focusUpSegment) {
    [self moveFocusUp: sender];
  }
  else if ([sender selectedSegment] == focusResetSegment) {
    [self resetFocus: sender];
  }
  else {
    NSAssert1(NO, @"Unexpected selected segment: %lu", (unsigned long)selected);
  }
}


- (void) zoomOut:(id)sender {
  [[dirViewControl directoryView] zoomOut];
}

- (void) zoomIn:(id)sender {
  [[dirViewControl directoryView] zoomIn];
}

- (void) resetZoom:(id)sender {
  DirectoryView  *directoryView = [dirViewControl directoryView];
  while ([directoryView canZoomOut]) {
    [directoryView zoomOut];
  }
}


- (void) moveFocusUp:(id)sender {
  [[dirViewControl directoryView] moveFocusUp];
}

- (void) moveFocusDown:(id)sender {
  [[dirViewControl directoryView] moveFocusDown];
}

- (void) resetFocus:(id)sender {
  DirectoryView  *directoryView = [dirViewControl directoryView];
  while ([directoryView canMoveFocusDown]) {
    [directoryView moveFocusDown];
  }
}


- (void) openFile:(id)sender {
  [dirViewControl openFile: sender];
}

- (void) previewFile:(id)sender {
  [dirViewControl previewFile: sender];
}

- (void) revealFileInFinder:(id)sender {
  [dirViewControl revealFileInFinder: sender];
}

- (void) deleteFile:(id)sender {
  [dirViewControl deleteFile: sender];
}

- (void) rescan:(id)sender {
  [[MainMenuControl singletonInstance] rescan: sender];
}

- (void) rescanAll:(id)sender {
  [[MainMenuControl singletonInstance] rescanAll: sender];
}

- (void) rescanVisible:(id)sender {
  [[MainMenuControl singletonInstance] rescanVisible: sender];
}

- (void) rescanSelected:(id)sender {
  [[MainMenuControl singletonInstance] rescanSelected: sender];
}

@end // @implementation DirectoryViewToolbarControl (PrivateMethods)


@implementation ToolbarItemMenu

- (id) initWithTitle:(NSString *)title {
  return [self initWithTitle: title target: nil];
}

- (id) initWithTitle:(NSString *)title target:(id)target {
  if (self = [super init]) {
    [self setTitle: title];
    [self setTarget: target]; // Using target for setting target of subitems.
    
    NSMenu  *submenu = [[[NSMenu alloc] initWithTitle: title] autorelease];
    [submenu setAutoenablesItems: YES];

    [self setSubmenu: submenu];
  }
  
  return self;
}


- (NSMenuItem *)addAction:(SEL)action withTitle:(NSString *)title {
  NSMenuItem  *item =
    [[[NSMenuItem alloc] initWithTitle: title action: action keyEquivalent: @""] autorelease];
  [item setTarget: [self target]];
  [[self submenu] addItem: item];

  return item;
}

@end // @implementation ToolbarItemMenu


@implementation ValidatingToolbarItem

- (id) initWithItemIdentifier:(NSString *)identifier
                    validator:(NSObject *)validatorVal
           validationSelector:(SEL)validationSelectorVal {
  if (self = [super initWithItemIdentifier: identifier]) {
    validator = [validatorVal retain];
    validationSelector = validationSelectorVal;
  }
  return self;
}

- (void) dealloc {
  [validator release];
  
  [super dealloc];
}


- (void) validate {
  // Any non-nil value means that the control should be enabled.
  [self setEnabled: [validator performSelector: validationSelector withObject: self] != nil];
}

@end // @implementation ValidatingToolbarItem


@implementation SelectorObject

- (id) initWithSelector:(SEL)selectorVal {
  if (self = [super init]) {
    selector = selectorVal;
  }
  return self;
}


- (SEL) selector {
  return selector;
}

@end // @implementation SelectorObject


