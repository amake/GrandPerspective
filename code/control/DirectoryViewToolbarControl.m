#import "DirectoryViewToolbarControl.h"

#import "DirectoryViewControl.h"


NSString  *ToolbarNavigateUp = @"NavigateUp";
NSString  *ToolbarNavigateDown = @"NavigateDown"; 
NSString  *ToolbarNavigation = @"Navigation"; 
NSString  *ToolbarOpenItem = @"OpenItem";
NSString  *ToolbarDeleteItem = @"DeleteItem";
NSString  *ToolbarToggleInfoDrawer = @"ToggleInfoDrawer";


@interface DirectoryViewToolbarControl (PrivateMethods)

/* Registers that the given selector should be used for creating the toolbar
 * item with the given identifier.
 */
- (void) createToolbarItem: (NSString *)identifier 
            usingSelector: (SEL)selector;

- (NSToolbarItem *) navigateUpToolbarItem;
- (NSToolbarItem *) navigateDownToolbarItem;
- (NSToolbarItem *) navigationToolbarItem;
- (NSToolbarItem *) openItemToolbarItem;
- (NSToolbarItem *) deleteItemToolbarItem;
- (NSToolbarItem *) toggleInfoDrawerToolbarItem;

- (void) validateNavigationControls;

@end


@interface SelectorObject : NSObject {
  SEL  selector;
}

- (id) initWithSelector: (SEL)selector;
- (SEL) selector;

@end


@interface NavigationToolbarItem : NSToolbarItem {
  DirectoryViewToolbarControl  *toolbarControl;
}

- (id) initWithItemIdentifier: (NSString *)identifier
         toolbarControl: (DirectoryViewToolbarControl *)toolbarControl;

@end


@implementation DirectoryViewToolbarControl

- (id) init {
  if (self = [super init]) {
    dirView = nil; // Will be set when loaded from nib.
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
  NSLog(@"new toolbar item: %@", itemIdentifier);
  
  if (createToolbarItemLookup == nil) {
    createToolbarItemLookup = [[NSMutableDictionary alloc] initWithCapacity: 8];

    [self createToolbarItem: ToolbarNavigateUp 
            usingSelector: @selector(navigateUpToolbarItem)];
    [self createToolbarItem: ToolbarNavigateDown 
            usingSelector: @selector(navigateDownToolbarItem)];
    [self createToolbarItem: ToolbarNavigation
            usingSelector: @selector(navigationToolbarItem)];
    [self createToolbarItem: ToolbarOpenItem 
            usingSelector: @selector(openItemToolbarItem)];
    [self createToolbarItem: ToolbarDeleteItem 
            usingSelector: @selector(deleteItemToolbarItem)];
    [self createToolbarItem: ToolbarToggleInfoDrawer
            usingSelector: @selector(toggleInfoDrawerToolbarItem)];
  }
  
  SEL  selector = 
    [[createToolbarItemLookup objectForKey: itemIdentifier] selector];
  
  NSToolbarItem  *item = [self performSelector: selector];

  if (flag) {
    [item setTarget: dirView];
  }

  return item;
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar {
    return [NSArray arrayWithObjects:
                      ToolbarNavigation,
                      NSToolbarFlexibleSpaceItemIdentifier,  
                      ToolbarOpenItem, ToolbarDeleteItem, 
                      NSToolbarFlexibleSpaceItemIdentifier, 
                      ToolbarToggleInfoDrawer, nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar {
    return [NSArray arrayWithObjects:
                      ToolbarNavigateUp, ToolbarNavigateDown, 
                      ToolbarNavigation,
                      ToolbarOpenItem, ToolbarDeleteItem,
                      ToolbarToggleInfoDrawer, 
                      NSToolbarSeparatorItemIdentifier, 
                      NSToolbarFlexibleSpaceItemIdentifier, nil];
}


- (IBAction) navigationAction: (id) sender {
  if ([sender selectedSegment] == 0) {
    [dirView upAction: sender];
  }
  else if ([sender selectedSegment] == 1) {
    [dirView downAction: sender];
  }
}

@end


@implementation DirectoryViewToolbarControl (PrivateMethods)

- (void) createToolbarItem: (NSString *)identifier 
            usingSelector: (SEL)selector {
  id  obj = [[[SelectorObject alloc] initWithSelector: selector] autorelease];

  [createToolbarItemLookup setObject: obj forKey: identifier];
}


- (NSToolbarItem *) navigateUpToolbarItem {
  NSToolbarItem  *item = 
    [[[NSToolbarItem alloc] initWithItemIdentifier: ToolbarNavigateUp] 
         autorelease];

  [item setLabel: NSLocalizedString( @"Up", 
                                     @"Toolbar label for navigating up" )];
  [item setPaletteLabel: [item label]];
  [item setToolTip: NSLocalizedString( @"Navigate up", "Tooltip" ) ];
  [item setImage: [NSImage imageNamed: @"Up.png"]];
  [item setAction: @selector(upAction:) ];
  
  return item;
}

- (NSToolbarItem *) navigateDownToolbarItem {
  NSToolbarItem  *item = 
    [[[NSToolbarItem alloc] initWithItemIdentifier: ToolbarNavigateDown] 
         autorelease];

  [item setLabel: NSLocalizedString( @"Down", 
                                     @"Toolbar label for navigating down" )];
  [item setPaletteLabel: [item label]];
  [item setToolTip: NSLocalizedString( @"Navigate down", "Tooltip" ) ];
  [item setImage: [NSImage imageNamed: @"Down.png"]];
  [item setAction: @selector(downAction:) ];

  return item;
}

- (NSToolbarItem *) navigationToolbarItem {
  NSToolbarItem  *item = 
    [[[NavigationToolbarItem alloc] 
         initWithItemIdentifier: ToolbarNavigation toolbarControl: self] 
           autorelease];

  [item setLabel: NSLocalizedString( @"Up/Down", 
                                     @"Toolbar label for Navigation controls" )];
  [item setPaletteLabel: [item label]];
  [item setView: navigationView];
  [item setMinSize: [navigationControls bounds].size];
  [item setMaxSize: [navigationControls bounds].size];

  return item;
}

- (NSToolbarItem *) openItemToolbarItem {
  NSToolbarItem  *item = 
    [[[NSToolbarItem alloc] initWithItemIdentifier: ToolbarOpenItem] 
         autorelease];

  [item setLabel: NSLocalizedString( @"Open", 
                                     @"Toolbar label for Open in Finder" )];
  [item setPaletteLabel: [item label]];
  [item setToolTip: NSLocalizedString( @"Open in Finder", "Tooltip" ) ];
  [item setImage: [NSImage imageNamed: @"FinderIcon.png"]];
  [item setAction: @selector(openFileInFinder:) ];

  return item;
}

- (NSToolbarItem *) deleteItemToolbarItem {
  NSToolbarItem  *item = 
    [[[NSToolbarItem alloc] initWithItemIdentifier: ToolbarDeleteItem] 
         autorelease];

  [item setLabel: NSLocalizedString( @"Delete", 
                                     @"Toolbar label for deleting item" )];
  [item setPaletteLabel: [item label]];
  [item setToolTip: NSLocalizedString( @"Move to trash", "Tooltip" ) ];
  [item setImage: [NSImage imageNamed: @"Delete.tiff"]];
  [item setAction: @selector(deleteFile:) ];

  return item;
}

- (NSToolbarItem *) toggleInfoDrawerToolbarItem {
  NSToolbarItem  *item = 
    [[[NSToolbarItem alloc] initWithItemIdentifier: ToolbarToggleInfoDrawer] 
         autorelease];

  [item setLabel: NSLocalizedString( @"Info", 
                                     @"Toolbar label for toggling Info drawer" )];
  [item setPaletteLabel: [item label]];
  [item setToolTip: NSLocalizedString( @"Show/hide drawer", "Tooltip" ) ];
  // TODO (eventually): Use "NSImageNameInfo" (Only available since 10.5)
  [item setImage: [NSImage imageNamed: @"Info.tiff"]];
  [item setAction: @selector(toggleDrawer:) ];

  return item;
}


- (void) validateNavigationControls {
  [navigationControls setEnabled: [dirView canNavigateUp] forSegment: 0];
  [navigationControls setEnabled: [dirView canNavigateDown] forSegment: 1];
}

@end // @implementation DirectoryViewToolbarControl (PrivateMethods)


@implementation NavigationToolbarItem

- (id) initWithItemIdentifier: (NSString *)identifier
         toolbarControl: (DirectoryViewToolbarControl *)toolbarControlVal {
  if (self = [super initWithItemIdentifier: identifier]) {
    toolbarControl = [toolbarControlVal retain];
  }
  return self;
}

- (void) dealloc {
  [toolbarControl release];
  
  [super dealloc];
}


- (void) validate {
  [toolbarControl validateNavigationControls];
}

@end // @implementation NavigationToolbarItem


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

