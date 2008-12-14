#import "DirectoryViewToolbarControl.h"

#import "DirectoryViewControl.h"
#import "ItemPathModelView.h"


NSString  *ToolbarZoom = @"Zoom"; 
NSString  *ToolbarFocus = @"Focus"; 
NSString  *ToolbarOpenItem = @"OpenItem";
NSString  *ToolbarRevealItem = @"RevealItem";
NSString  *ToolbarDeleteItem = @"DeleteItem";
NSString  *ToolbarToggleDrawer = @"ToggleDrawer";


// Tags for each of the segments in the Zoom and Focus controls, so that the 
// order can be changed in the nib file.
#define  ZOOM_IN_TAG     100
#define  ZOOM_OUT_TAG    101
#define  FOCUS_UP_TAG    102
#define  FOCUS_DOWN_TAG  103


@interface DirectoryViewToolbarControl (PrivateMethods)

/* Registers that the given selector should be used for creating the toolbar
 * item with the given identifier.
 */
- (void) createToolbarItem: (NSString *)identifier 
            usingSelector: (SEL)selector;

- (NSToolbarItem *) zoomToolbarItem;
- (NSToolbarItem *) focusToolbarItem;
- (NSToolbarItem *) openItemToolbarItem;
- (NSToolbarItem *) revealItemToolbarItem;
- (NSToolbarItem *) deleteItemToolbarItem;
- (NSToolbarItem *) toggleDrawerToolbarItem;

- (id) validateZoomControls;
- (id) validateFocusControls;

- (BOOL) validateAction: (SEL)action;

- (void) zoomOut: (id) sender;
- (void) zoomIn: (id) sender;

- (void) moveFocusUp: (id) sender;
- (void) moveFocusDown: (id) sender;

- (void) openFile: (id) sender;
- (void) revealFile: (id) sender;
- (void) deleteFile: (id) sender;

@end


@interface ToolbarItemMenu : NSMenuItem {
}

- (id) initWithTitle: (NSString *)title target: (id) target;
- (void) addAction: (SEL) action withTitle: (NSString *)title;

@end


@interface SelectorObject : NSObject {
  SEL  selector;
}

- (id) initWithSelector: (SEL)selector;
- (SEL) selector;

@end


@interface ValidatingToolbarItem : NSToolbarItem {
  NSObject  *validator;
  SEL  validationSelector;
}

- (id) initWithItemIdentifier: (NSString *)identifier
         validator: (NSObject *)validator 
         validationSelector: (SEL) validationSelector;

@end


@implementation DirectoryViewToolbarControl

- (id) init {
  if (self = [super init]) {
    dirView = nil; // Will be set when loaded from nib.
    
    // Set defaults (can be overridden when segments are tagged)
    zoomInSegment = 1;
    zoomOutSegment = 0;
    focusUpSegment = 0;
    focusDownSegment = 1;
  }
  return self;
}

- (void) dealloc {
  // We were not retaining it, so should not call -release  
  dirView = nil;

  [super dealloc];
}


- (void) awakeFromNib {
  // Not retaining it. It needs to be deallocated when the window is closed.
  dirView = [dirViewWindow windowController];
  
  signed int  i;
  
  // Check if tags have been used to change default segment ordering 
  i = [zoomControls segmentCount];
  while (--i >= 0) {
    int  tag = [[zoomControls cell] tagForSegment: i];
    switch (tag) {
      case ZOOM_IN_TAG:
        zoomInSegment = i; break;
      case ZOOM_OUT_TAG:
        zoomOutSegment = i; break;
    }
  }

  i = [focusControls segmentCount];
  while (--i >= 0) {
    int  tag = [[focusControls cell] tagForSegment: i];
    switch (tag) {
      case FOCUS_UP_TAG:
        focusUpSegment = i; break;
      case FOCUS_DOWN_TAG:
        focusDownSegment = i; break;
    }
  }

  
  NSToolbar  *toolbar = 
    [[[NSToolbar alloc] initWithIdentifier: @"DirectoryViewToolbar"] 
         autorelease];
           
  [toolbar setAllowsUserCustomization: YES];
  [toolbar setAutosavesConfiguration: YES];     
  [toolbar setDisplayMode: NSToolbarDisplayModeIconAndLabel];

  [toolbar setDelegate: self];
  [[dirView window] setToolbar: toolbar];
}


NSMutableDictionary  *createToolbarItemLookup = nil;

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar 
                     itemForItemIdentifier: (NSString *)itemIdentifier
                     willBeInsertedIntoToolbar: (BOOL)flag {
  if (createToolbarItemLookup == nil) {
    createToolbarItemLookup = [[NSMutableDictionary alloc] initWithCapacity: 8];

    [self createToolbarItem: ToolbarZoom
            usingSelector: @selector(zoomToolbarItem)];
    [self createToolbarItem: ToolbarFocus
            usingSelector: @selector(focusToolbarItem)];
    [self createToolbarItem: ToolbarOpenItem 
            usingSelector: @selector(openItemToolbarItem)];
    [self createToolbarItem: ToolbarRevealItem 
            usingSelector: @selector(revealItemToolbarItem)];
    [self createToolbarItem: ToolbarDeleteItem 
            usingSelector: @selector(deleteItemToolbarItem)];
    [self createToolbarItem: ToolbarToggleDrawer
            usingSelector: @selector(toggleDrawerToolbarItem)];
  }
  
  SelectorObject  *selObj = 
    [createToolbarItemLookup objectForKey: itemIdentifier];
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
                      ToolbarOpenItem, ToolbarRevealItem, ToolbarDeleteItem, 
                      NSToolbarFlexibleSpaceItemIdentifier, 
                      ToolbarToggleDrawer, nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar {
    return [NSArray arrayWithObjects:
                      ToolbarZoom, ToolbarFocus,
                      ToolbarOpenItem, ToolbarRevealItem, ToolbarDeleteItem,
                      ToolbarToggleDrawer, 
                      NSToolbarSeparatorItemIdentifier, 
                      NSToolbarSpaceItemIdentifier, 
                      NSToolbarFlexibleSpaceItemIdentifier, nil];
}


- (IBAction) zoomAction: (id) sender {
  int  selected = [sender selectedSegment];

  if (selected == zoomInSegment) {
    [self zoomIn: sender];
  }
  else if (selected == zoomOutSegment) {
    [self zoomOut: sender];
  }
  else {
    NSAssert1(NO, @"Unexpected selected segment: %d", selected);
  }
}


- (IBAction) focusAction: (id) sender {
  int  selected = [sender selectedSegment];
  
  if ([sender selectedSegment] == focusDownSegment) {
    [self moveFocusDown: sender];
  }
  else if ([sender selectedSegment] == focusUpSegment) {
    [self moveFocusUp: sender];
  }
  else {
    NSAssert1(NO, @"Unexpected selected segment: %d", selected);
  }
}

@end


@implementation DirectoryViewToolbarControl (PrivateMethods)

- (void) createToolbarItem: (NSString *)identifier 
            usingSelector: (SEL)selector {
  id  obj = [[[SelectorObject alloc] initWithSelector: selector] autorelease];

  [createToolbarItemLookup setObject: obj forKey: identifier];
}


- (NSToolbarItem *) zoomToolbarItem {
  NSToolbarItem  *item = 
    [[[ValidatingToolbarItem alloc] 
         initWithItemIdentifier: ToolbarZoom validator: self
           validationSelector: @selector(validateZoomControls)]
             autorelease];
             
  NSString  *title = 
    NSLocalizedStringFromTable( @"Zoom", @"Toolbar", 
                                @"Label for zooming controls" );
  NSString  *zoomOutTitle = 
    NSLocalizedStringFromTable( @"Zoom out", @"Toolbar", @"Toolbar action" );
  NSString  *zoomInTitle = 
    NSLocalizedStringFromTable( @"Zoom in", @"Toolbar", @"Toolbar action" );

  [item setLabel: title];
  [item setPaletteLabel: [item label]];
  [item setView: zoomControls];
  [item setMinSize: [zoomControls bounds].size];
  [item setMaxSize: [zoomControls bounds].size];
  
  // Tool tips set here (as opposed to Interface Builder) so that all toolbar-
  // related text is in the same file, to facilitate localization.
  [[zoomControls cell] setToolTip: zoomInTitle  forSegment: zoomInSegment];
  [[zoomControls cell] setToolTip: zoomOutTitle forSegment: zoomOutSegment];

  ToolbarItemMenu  *menu = 
    [[[ToolbarItemMenu alloc] initWithTitle: title target: self] autorelease];
  [menu addAction: @selector(zoomOut:) withTitle: zoomOutTitle];
  [menu addAction: @selector(zoomIn:) withTitle: zoomInTitle];

  [item setMenuFormRepresentation: menu];

  return item;
}

- (NSToolbarItem *) focusToolbarItem {
  NSToolbarItem  *item = 
    [[[ValidatingToolbarItem alloc] 
         initWithItemIdentifier: ToolbarFocus validator: self
           validationSelector: @selector(validateFocusControls)]
             autorelease];
             
  NSString  *title = 
    NSLocalizedStringFromTable( @"Focus", @"Toolbar", 
                                @"Label for focus controls" );
  NSString  *moveUpTitle =
    NSLocalizedStringFromTable( @"Move focus up", @"Toolbar", 
                                @"Toolbar action" );
  NSString  *moveDownTitle =
    NSLocalizedStringFromTable( @"Move focus down", @"Toolbar", 
                                @"Toolbar action" );

  [item setLabel: title];
  [item setPaletteLabel: [item label]];
  [item setView: focusControls];
  [item setMinSize: [focusControls bounds].size];
  [item setMaxSize: [focusControls bounds].size];

  // Tool tips set here (as opposed to Interface Builder) so that all toolbar-
  // related text is in the same file, to facilitate localization.
  [[focusControls cell] setToolTip: moveDownTitle forSegment: focusDownSegment];
  [[focusControls cell] setToolTip: moveUpTitle   forSegment: focusUpSegment];

  ToolbarItemMenu  *menu = 
    [[[ToolbarItemMenu alloc] initWithTitle: title target: self] autorelease];
  [menu addAction: @selector(moveFocusUp:) withTitle: moveUpTitle];
  [menu addAction: @selector(moveFocusDown:) withTitle: moveDownTitle];

  [item setMenuFormRepresentation: menu];

  return item;
}

- (NSToolbarItem *) openItemToolbarItem {
  NSToolbarItem  *item = 
    [[[NSToolbarItem alloc] 
         initWithItemIdentifier: ToolbarOpenItem] autorelease];

  [item setLabel: NSLocalizedStringFromTable( @"Open", @"Toolbar", 
                                              @"Toolbar action" )];
  [item setPaletteLabel: [item label]];
  [item setToolTip: NSLocalizedStringFromTable( @"Open with Finder", 
                                                @"Toolbar", @"Tooltip" )];
  [item setImage: [NSImage imageNamed: @"OpenWithFinder"]];
  [item setAction: @selector(openFile:) ];
  [item setTarget: self];

  return item;
}

- (NSToolbarItem *) revealItemToolbarItem {
  NSToolbarItem  *item = 
    [[[NSToolbarItem alloc] 
         initWithItemIdentifier: ToolbarRevealItem] autorelease];

  [item setLabel: NSLocalizedStringFromTable( @"Reveal", @"Toolbar", 
                                              @"Toolbar action" )];
  [item setPaletteLabel: [item label]];
  [item setToolTip: NSLocalizedStringFromTable( @"Reveal in Finder", 
                                                @"Toolbar", @"Tooltip" )];
  [item setImage: [NSImage imageNamed: @"RevealInFinder"]];
  [item setAction: @selector(revealFile:) ];
  [item setTarget: self];

  return item;
}

- (NSToolbarItem *) deleteItemToolbarItem {
  NSToolbarItem  *item = 
    [[[NSToolbarItem alloc] 
         initWithItemIdentifier: ToolbarDeleteItem] autorelease];

  [item setLabel: NSLocalizedStringFromTable( @"Delete", @"Toolbar",
                                              @"Toolbar action" )];
  [item setPaletteLabel: [item label]];
  [item setToolTip: NSLocalizedStringFromTable( @"Move to trash", @"Toolbar", 
                                                @"Tooltip" ) ];
  [item setImage: [NSImage imageNamed: @"Delete"]];
  [item setAction: @selector(deleteFile:) ];
  [item setTarget: self];

  return item;
}

- (NSToolbarItem *) toggleDrawerToolbarItem {
  NSToolbarItem  *item = 
    [[[NSToolbarItem alloc] initWithItemIdentifier: ToolbarToggleDrawer] 
         autorelease];

  [item setLabel: NSLocalizedStringFromTable( @"Drawer", @"Toolbar",
                                              @"Toolbar action" )];
  [item setPaletteLabel: [item label]];
  [item setToolTip: NSLocalizedStringFromTable( @"Open/close drawer", 
                                                @"Toolbar", "Tooltip" )];
  [item setImage: [NSImage imageNamed: @"ToggleDrawer"]];
  [item setAction: @selector(toggleDrawer:) ];
  [item setTarget: dirView];

  return item;
}


- (id) validateZoomControls {
  [zoomControls setEnabled: [dirView canNavigateUp]
                  forSegment: zoomOutSegment];
  [zoomControls setEnabled: [dirView canNavigateDown] 
                  forSegment: zoomInSegment];

  return self; // Always enable the overall control
}

- (id) validateFocusControls {
  ItemPathModelView  *pathModelView = [dirView pathModelView]; 

  [focusControls setEnabled: [pathModelView canMoveSelectionUp] 
                   forSegment: focusUpSegment];
  [focusControls setEnabled: ! [pathModelView selectionSticksToEndPoint] 
                   forSegment: focusDownSegment];
  return self; // Always enable the overall control
}


- (BOOL) validateToolbarItem: (NSToolbarItem *)item {
  return [self validateAction: [item action]];
}

- (BOOL) validateMenuItem: (NSMenuItem *)item {
  return [self validateAction: [item action]];
}
  

- (BOOL) validateAction: (SEL)action {
  if ( action == @selector(zoomOut:) ) {
    return [dirView canNavigateUp];
  }
  else if ( action == @selector(zoomIn:) ) {
    return [dirView canNavigateDown];
  }
  if ( action == @selector(moveFocusUp:) ) {
    return [[dirView pathModelView] canMoveSelectionUp];
  }
  else if ( action == @selector(moveFocusDown:) ) {
    return ! [[dirView pathModelView] selectionSticksToEndPoint];
  }
  else if ( action == @selector(openFile:) ) {
    return [dirView canOpenSelectedFile];
  }
  else if ( action == @selector(revealFile:) ) {
    return [dirView canRevealSelectedFile];
  }
  else if ( action == @selector(deleteFile:) ) {
    return [dirView canDeleteSelectedFile];
  }
  else {
    NSLog(@"Unrecognized action %@", NSStringFromSelector(action));
  }
}


- (void) zoomOut: (id) sender {
  [dirView upAction: sender];
}

- (void) zoomIn: (id) sender {
  [dirView downAction: sender];
}


- (void) moveFocusUp: (id) sender {
  [[dirView pathModelView] moveSelectionUp];
}

- (void) moveFocusDown: (id) sender {
  ItemPathModelView  *pathModelView = [dirView pathModelView];
  
  if ([pathModelView canMoveSelectionDown]) {
    [pathModelView moveSelectionDown];
  }
  else {
    [pathModelView setSelectionSticksToEndPoint: YES];
  }
}


- (void) openFile: (id) sender {
  [dirView openFile: sender];
}

- (void) revealFile: (id) sender {
  [dirView revealFileInFinder: sender];
}

- (void) deleteFile: (id) sender {
  [dirView deleteFile: sender];
}

@end // @implementation DirectoryViewToolbarControl (PrivateMethods)


@implementation ToolbarItemMenu

- (id) initWithTitle: (NSString *)title {
  return [self initWithTitle: title target: nil];
}

- (id) initWithTitle: (NSString *)title target: (id) target {
  if (self = [super init]) {
    [self setTitle: title];
    [self setTarget: target]; // Using target for setting target of subitems.
    
    NSMenu  *submenu = [[[NSMenu alloc] initWithTitle: title] autorelease];
    [submenu setAutoenablesItems: YES];

    [self setSubmenu: submenu];
  }
  
  return self;
}


- (void) addAction: (SEL) action withTitle: (NSString *)title {
  NSMenuItem  *item =
    [[[NSMenuItem alloc] 
        initWithTitle: title action: action keyEquivalent: @""] autorelease];
  [item setTarget: [self target]];
  [[self submenu] addItem: item];
}

@end // @implementation ToolbarItemMenu


@implementation ValidatingToolbarItem

- (id) initWithItemIdentifier: (NSString *)identifier
         validator: (NSObject *)validatorVal 
         validationSelector: (SEL) validationSelectorVal {
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
  [self setEnabled: [validator performSelector: validationSelector] != nil];
}

@end // @implementation ValidatingToolbarItem


@implementation SelectorObject

- (id) initWithSelector: (SEL)selectorVal {
  if (self = [super init]) {
    selector = selectorVal;
  }
  return self;
}


- (SEL) selector {
  return selector;
}

@end // @implementation SelectorObject


