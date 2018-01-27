#import "DirectoryView.h"

#import "DirectoryViewControl.h"
#import "DirectoryItem.h"

#import "TreeLayoutBuilder.h"
#import "TreeDrawer.h"
#import "TreeDrawerSettings.h"
#import "ItemPathDrawer.h"
#import "ItemPathModel.h"
#import "ItemPathModelView.h"
#import "SelectedItemLocator.h"

#import "TreeLayoutTraverser.h"

#import "AsynchronousTaskManager.h"
#import "DrawTaskExecutor.h"
#import "DrawTaskInput.h"

#import "FileItemMapping.h"
#import "FileItemMappingScheme.h"


#define SCROLL_WHEEL_SENSITIVITY  6.0


NSString  *ColorPaletteChangedEvent = @"colorPaletteChanged";
NSString  *ColorMappingChangedEvent = @"colorMappingChanged";


@interface DirectoryView (PrivateMethods)

- (BOOL) validateAction:(SEL)action;

- (void) forceRedraw;

- (void) itemTreeImageReady:(id)image;

- (void) postColorPaletteChanged;
- (void) postColorMappingChanged;

- (void) selectedItemChanged:(NSNotification *)notification;
- (void) visibleTreeChanged:(NSNotification *)notification;
- (void) visiblePathLockingChanged:(NSNotification *)notification;
- (void) windowMainStatusChanged:(NSNotification *)notification;
- (void) windowKeyStatusChanged:(NSNotification *)notification;

- (void) updateAcceptMouseMovedEvents;

- (void) observeColorMapping;
- (void) colorMappingChanged:(NSNotification *)notification;

- (void) updateSelectedItem:(NSPoint)point;

@end 


@implementation DirectoryView

- (id) initWithFrame:(NSRect)frame {
  if (self = [super initWithFrame:frame]) {
    layoutBuilder = [[TreeLayoutBuilder alloc] init];
    pathDrawer = [[ItemPathDrawer alloc] init];
    selectedItemLocator = [[SelectedItemLocator alloc] init];
    
    scrollWheelDelta = 0;
  }

  return self;
}

- (void) dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  
  [drawTaskManager dispose];
  [drawTaskManager release];

  [layoutBuilder release];
  [pathDrawer release];
  [selectedItemLocator release];
  
  [observedColorMapping release];
  
  [pathModelView release];
  
  [treeImage release];
  
  [super dealloc];
}


- (void) postInitWithPathModelView:(ItemPathModelView *)pathModelViewVal {
  NSAssert(pathModelView==nil, @"The path model view should only be set once.");

  pathModelView = [pathModelViewVal retain];
  
  DrawTaskExecutor  *drawTaskExecutor = 
    [[[DrawTaskExecutor alloc] initWithTreeContext: [[pathModelView pathModel] treeContext]]
     autorelease];
  drawTaskManager = [[AsynchronousTaskManager alloc] initWithTaskExecutor: drawTaskExecutor];

  [self observeColorMapping];
  
  NSNotificationCenter  *nc = [NSNotificationCenter defaultCenter];

  [nc addObserver: self
         selector: @selector(selectedItemChanged:)
             name: SelectedItemChangedEvent
           object: pathModelView];
  [nc addObserver: self
         selector: @selector(visibleTreeChanged:)
             name: VisibleTreeChangedEvent
           object: pathModelView];
  [nc addObserver: self
         selector: @selector(visiblePathLockingChanged:)
             name: VisiblePathLockingChangedEvent
           object: [pathModelView pathModel]];

  [nc addObserver: self
         selector: @selector(windowMainStatusChanged:)
             name: NSWindowDidBecomeMainNotification
           object: [self window]];
  [nc addObserver: self
         selector: @selector(windowMainStatusChanged:)
             name: NSWindowDidResignMainNotification
           object: [self window]];
  [nc addObserver: self
         selector: @selector(windowKeyStatusChanged:)
             name: NSWindowDidBecomeKeyNotification
           object: [self window]];
  [nc addObserver: self
         selector: @selector(windowKeyStatusChanged:)
             name: NSWindowDidResignKeyNotification
           object: [self window]];
          
  [self visiblePathLockingChanged: nil];
  [self setNeedsDisplay: YES];
}


- (ItemPathModelView *)pathModelView {
  return pathModelView;
}

- (FileItem *)treeInView {
  return (showEntireVolume 
          ? [pathModelView volumeTree]
          : [pathModelView visibleTree]);
}


- (NSRect) locationInViewForItemAtEndOfPath:(NSArray *)itemPath {
  return [selectedItemLocator locationForItemAtEndOfPath: itemPath
                                          startingAtTree: [self treeInView]
                                      usingLayoutBuilder: layoutBuilder
                                                  bounds: [self bounds]];
}

- (NSImage *)imageInViewForItemAtEndOfPath:(NSArray *)itemPath {
  NSRect sourceRect = [self locationInViewForItemAtEndOfPath: itemPath];

  NSImage  *targetImage = [[[NSImage alloc] initWithSize: sourceRect.size] autorelease];

  [targetImage lockFocus];
  [treeImage drawInRect: NSMakeRect(0, 0, sourceRect.size.width, sourceRect.size.height)
               fromRect: sourceRect
              operation: NSCompositeCopy
               fraction: 1.0];
  [targetImage unlockFocus];

  return targetImage;
}


- (TreeDrawerSettings *)treeDrawerSettings {
  DrawTaskExecutor  *drawTaskExecutor = (DrawTaskExecutor*)[drawTaskManager taskExecutor];

  return [drawTaskExecutor treeDrawerSettings];
}

- (void) setTreeDrawerSettings:(TreeDrawerSettings *)settings {
  DrawTaskExecutor  *drawTaskExecutor = (DrawTaskExecutor*)[drawTaskManager taskExecutor];

  TreeDrawerSettings  *oldSettings = [drawTaskExecutor treeDrawerSettings];
  if (settings != oldSettings) {
    [oldSettings retain];

    [drawTaskExecutor setTreeDrawerSettings: settings];
    
    if ([settings colorPalette] != [oldSettings colorPalette]) {
      [self postColorPaletteChanged]; 
    }
    
    if ([settings colorMapper] != [oldSettings colorMapper]) {
      [self postColorMappingChanged]; 

      // Observe the color mapping (for possible changes to its hashing
      // implementation)
      [self observeColorMapping];
    }
    
    if ([settings showPackageContents] != [oldSettings showPackageContents]) {
      [pathModelView setShowPackageContents: [settings showPackageContents]];
    }
    
    [oldSettings release];

    [self forceRedraw];
  }
}


- (BOOL) showEntireVolume {
  return showEntireVolume;
}

- (void) setShowEntireVolume:(BOOL)flag {
  if (flag != showEntireVolume) {
    showEntireVolume = flag;
    [self forceRedraw];
  }
}


- (TreeLayoutBuilder *)layoutBuilder {
  return layoutBuilder;
}


- (BOOL) canZoomIn {
  return ( [[pathModelView pathModel] isVisiblePathLocked] 
           && [pathModelView canMoveVisibleTreeDown] );
}

- (BOOL) canZoomOut {
  return [pathModelView canMoveVisibleTreeUp];
}


- (void) zoomIn {
  [pathModelView moveVisibleTreeDown];
}

- (void) zoomOut {
  [pathModelView moveVisibleTreeUp];
  
  // Automatically lock path as well.
  [[pathModelView pathModel] setVisiblePathLocking: YES];
}


- (BOOL) canMoveFocusUp {
  return [pathModelView canMoveSelectionUp];
}

- (BOOL) canMoveFocusDown {
  return ! [pathModelView selectionSticksToEndPoint];
}


- (void) moveFocusUp {
  [pathModelView moveSelectionUp]; 
}

- (void) moveFocusDown {
  if ([pathModelView canMoveSelectionDown]) {
    [pathModelView moveSelectionDown];
  }
  else {
    [pathModelView setSelectionSticksToEndPoint: YES];
  }
}


- (void) drawRect:(NSRect)rect {
  if (pathModelView==nil) {
    return;
  }
  
  if (treeImage != nil && !NSEqualSizes([treeImage size], [self bounds].size)) {
    // Scale the existing image for the new size
    [treeImage setSize: [self bounds].size];
    
    // Indicate that the scaling has taken place, so that a new image will be
    // created.
    treeImageIsScaled = YES;
  }

  if (treeImage==nil || treeImageIsScaled) {
    NSAssert([self bounds].origin.x == 0 &&
             [self bounds].origin.y == 0, @"Bounds not at (0, 0)");

    // Create image in background thread.
    DrawTaskInput  *drawInput =
      [[DrawTaskInput alloc] initWithVisibleTree: [pathModelView visibleTree]
                                      treeInView: [self treeInView]
                                   layoutBuilder: layoutBuilder
                                          bounds: [self bounds]];
    [drawTaskManager asynchronouslyRunTaskWithInput: drawInput
                                           callback: self
                                           selector: @selector(itemTreeImageReady:)];
    [drawInput release];
  }
  
  if (treeImage != nil) {
    [treeImage drawAtPoint: NSZeroPoint
                  fromRect: NSZeroRect
                 operation: NSCompositeCopy
                  fraction: 1.0f];

    if ([pathModelView isSelectedFileItemVisible] && !treeImageIsScaled) {
      [pathDrawer drawVisiblePath: pathModelView
                   startingAtTree: [self treeInView]
               usingLayoutBuilder: layoutBuilder
                           bounds: [self bounds]];
    }
  }
}


- (BOOL) isOpaque {
  return YES;
}

- (BOOL) acceptsFirstResponder {
  return YES;
}

- (BOOL) becomeFirstResponder {
  return YES;
}

- (BOOL) resignFirstResponder {
  return YES;
}


- (BOOL)performKeyEquivalent:(NSEvent *)theEvent {
  int  flags = [theEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask;
  NSString  *chars = [theEvent characters];
  
  if ([chars isEqualToString: @"]"]) {
    if (flags == NSCommandKeyMask) {
      if ([self canMoveFocusDown]) {
        [self moveFocusDown];
      }
      return YES;
    }
  }
  else if ([chars isEqualToString: @"["]) {
    if (flags == NSCommandKeyMask) {
      if ([self canMoveFocusUp]) {
        [self moveFocusUp];
      }
      return YES;
    }
  }
  else if ([chars isEqualToString: @"="]) {
    // Accepting this with or without the Shift key-pressed, as having to use 
    // the Shift key is a bit of a pain.
    if ((flags | NSShiftKeyMask) == (NSCommandKeyMask | NSShiftKeyMask)) {
      if ([self canZoomIn]) {
        [self zoomIn];
      }
      return YES;
    }
  }
  else if ([chars isEqualToString: @"-"]) {
    if (flags == NSCommandKeyMask) {
      if ([self canZoomOut]) {
        [self zoomOut];
      }
      return YES;
    }
  }
  else if ([chars isEqualToString: @" "]) {
    if (flags == 0) {
      SEL  action = @selector(previewFile:);
      if ([self validateAction: action]) {
        DirectoryViewControl*  target = (DirectoryViewControl*)
          [[NSApplication sharedApplication] targetForAction: action];
        [target previewFile: self];
      }
      return YES;
    }
  }
  
  return NO;
}


- (void) scrollWheel: (NSEvent *)theEvent {
  scrollWheelDelta += [theEvent deltaY];
  
  if (scrollWheelDelta > 0) {
    if (! [self canMoveFocusDown]) {
      // Keep it at zero, to make moving up not unnecessarily cumbersome.
      scrollWheelDelta = 0;
    }
    else if (scrollWheelDelta > SCROLL_WHEEL_SENSITIVITY + 0.5f) {
      [self moveFocusDown];

      // Make it easy to move up down again.
      scrollWheelDelta = - SCROLL_WHEEL_SENSITIVITY;
    }
  }
  else {
    if (! [self canMoveFocusUp]) {
      // Keep it at zero, to make moving up not unnecessarily cumbersome.
      scrollWheelDelta = 0;
    }
    else if (scrollWheelDelta < - (SCROLL_WHEEL_SENSITIVITY + 0.5f)) {
      [self moveFocusUp];

      // Make it easy to move back down again.
      scrollWheelDelta = SCROLL_WHEEL_SENSITIVITY;
    }
  }
}


- (void) mouseDown:(NSEvent *)theEvent {
  ItemPathModel  *pathModel = [pathModelView pathModel];

  if ([[self window] acceptsMouseMovedEvents] &&
      [pathModel lastFileItem] == [pathModel visibleTree]) {
    // Although the visible path is following the mouse, the visible path is empty. This can either
    // mean that the view only shows a single file item or, more likely, the view did not yet
    // receive the mouse moved events that are required to update the visible path because it was
    // not yet the first responder.
    
    // Force building (and drawing) of the visible path.
    [self mouseMoved: theEvent];
    
    if ( [pathModel lastFileItem] != [pathModel visibleTree] ) {
      // The path changed. Do not toggle the locking. This mouse click was used to make the view the
      // first responder, ensuring that the visible path is following the mouse pointer.
      return;
    }
  }

  // Toggle the path locking.

  BOOL  wasLocked = [pathModel isVisiblePathLocked];
  if (wasLocked) {
    // Unlock first, then build new path.
    [pathModel setVisiblePathLocking: NO];
  }

  NSPoint  loc = [theEvent locationInWindow];
  [self updateSelectedItem: [self convertPoint: loc fromView: nil]];

  if (!wasLocked) {
    // Now lock, after having updated path.

    if ([pathModelView isSelectedFileItemVisible]) {
      // Only lock the path if it contains the selected item, i.e. if the mouse click was inside the
      // visible tree.
      [pathModel setVisiblePathLocking: YES];
    }
  }
}


- (void) mouseMoved:(NSEvent *)theEvent {
  if ([[pathModelView pathModel] isVisiblePathLocked]) {
    // Ignore mouseMoved events when the item path is locked.
    //
    // Note: Although this view stops accepting mouse moved events when the path becomes locked,
    // these may be generated later on anyway, requested by other components. In particular, mousing
    // over the NSTextViews in the drawer triggers mouse moved events again.
    return;
  }
  
  if (! ([[self window] isMainWindow] && [[self window] isKeyWindow])) {
    // Only handle mouseMoved events when the window is main and key. 
    return;
  }
  
  NSPoint  loc = [[self window] mouseLocationOutsideOfEventStream];
  // Note: not using the location returned by [theEvent locationInWindow] as this is incorrect after
  // the drawer has been clicked on.

  NSPoint  mouseLoc = [self convertPoint: loc fromView: nil];
  BOOL isInside = [self mouse: mouseLoc inRect: [self bounds]];

  if (isInside) {
    [self updateSelectedItem: mouseLoc];
  }
  else {
    [[pathModelView pathModel] clearVisiblePath];
  }
}


- (NSMenu *)menuForEvent:(NSEvent *)theEvent {
  NSMenu  *popUpMenu = [[[NSMenu alloc] initWithTitle: @"Contextual Menu"] autorelease];
  int  itemCount = 0;


  if ( [self validateAction: @selector(revealFileInFinder:)] ) {
    [popUpMenu insertItemWithTitle: 
                 NSLocalizedStringFromTable( @"Reveal in Finder", @"PopUpMenu", @"Menu item" )
                            action: @selector(revealFileInFinder:) 
                     keyEquivalent: @""
                           atIndex: itemCount++];
  }

  if ( [self validateAction: @selector(previewFile:)] ) {
    NSMenuItem  *menuItem = [[[NSMenuItem alloc] initWithTitle:
                            NSLocalizedStringFromTable( @"Quick Look", @"PopUpMenu", @"Menu item" )
                                                        action: @selector(previewFile:)
                                                 keyEquivalent: @" "]
                             autorelease];
    menuItem.keyEquivalentModifierMask = 0; // No modifiers
    [popUpMenu insertItem: menuItem atIndex: itemCount++];
  }
  
  if ( [self validateAction: @selector(openFile:)] ) {
    [popUpMenu insertItemWithTitle: 
     NSLocalizedStringFromTable( @"Open with Finder", @"PopUpMenu", @"Menu item" )
                            action: @selector(openFile:) 
                     keyEquivalent: @"" 
                           atIndex: itemCount++];
  }
  
  if ( [self validateAction: @selector(copy:)] ) {
    [popUpMenu insertItemWithTitle:
     NSLocalizedStringFromTable(@"Copy path", @"PopUpMenu", @"Menu item" )
                            action: @selector(copy:) 
                     keyEquivalent: @"c"
                           atIndex: itemCount++];
  }
  
  if ( [self validateAction: @selector(deleteFile:)] ) {
    [popUpMenu insertItemWithTitle: 
     NSLocalizedStringFromTable( @"Delete file", @"PopUpMenu", @"Menu item" )
                            action: @selector(deleteFile:) 
                     keyEquivalent: @""
                           atIndex: itemCount++];
  }
  
  return (itemCount > 0) ? popUpMenu : nil;
}

@end // @implementation DirectoryView


@implementation DirectoryView (PrivateMethods)

/**
 * Checks with the target that will execute the action if it should be enabled. It assumes that the
 * target has implemented validateAction:, which is the case when the target is
 * DirectoryViewControl.
 */
- (BOOL) validateAction:(SEL)action {
  DirectoryViewControl*  target =
    (DirectoryViewControl *)[[NSApplication sharedApplication] targetForAction: action];
  return [target validateAction: action];
}

- (void) forceRedraw {
  [self setNeedsDisplay: YES];

  // Discard the existing image.
  [treeImage release];
  treeImage = nil;
}


/**
 * Callback method that signals that the drawing task has finished execution. It is also called when
 * the drawing has been aborted, in which the image will be nil.
 */
- (void) itemTreeImageReady: (id) image {
  if (image != nil) {
    // Only take action when the drawing task has completed succesfully. 
    //
    // Without this check, a race condition can occur. When a new drawing task aborts the execution
    // of an ongoing task, the completion of the latter and subsequent invocation of -drawRect:
    // results in the abortion of the new task (as long as it has not yet completed).
  
    // Note: This method is called from the main thread (even though it has been triggered by the
    // drawer's background thread). So calling setNeedsDisplay directly is okay.
    [treeImage release];
    treeImage = [image retain];
    treeImageIsScaled = NO;
  
    [self setNeedsDisplay: YES];
  }
}


- (void) postColorPaletteChanged {
  [[NSNotificationCenter defaultCenter]
      postNotificationName: ColorPaletteChangedEvent object: self];
}

- (void) postColorMappingChanged {
  [[NSNotificationCenter defaultCenter]
      postNotificationName: ColorMappingChangedEvent object: self];
}


/* Called when selection changes in path
 */
- (void) selectedItemChanged:(NSNotification *)notification {
  [self setNeedsDisplay: YES];
}

- (void) visibleTreeChanged:(NSNotification *)notification {
  [self forceRedraw];
}

- (void) visiblePathLockingChanged:(NSNotification *)notification {
  BOOL  locked = [[pathModelView pathModel] isVisiblePathLocked];
  
  // Update the item path drawer directly. Although the drawer could also listen to the
  // notification, it seems better to do it like this. It keeps the item path drawer more general,
  // and as the item path drawer is tightly integrated with this view, there is no harm in updating
  // it directly.
  [pathDrawer setHighlightPathEndPoint: locked];
 
  [self updateAcceptMouseMovedEvents];
  
  [self setNeedsDisplay: YES];
}

- (void) windowMainStatusChanged:(NSNotification *)notification {
  [self updateAcceptMouseMovedEvents];
}

- (void) windowKeyStatusChanged:(NSNotification *)notification {
  [self updateAcceptMouseMovedEvents];
}

- (void) updateAcceptMouseMovedEvents {
  BOOL  letPathFollowMouse = 
    ( ![[pathModelView pathModel] isVisiblePathLocked] 
      && [[self window] isMainWindow] 
      && [[self window] isKeyWindow] );
      
  [[self window] setAcceptsMouseMovedEvents: letPathFollowMouse];

  if (letPathFollowMouse) {
    // Ensures that the view also receives the mouse moved events.
    [[self window] makeFirstResponder: self];
  }
}


- (void) observeColorMapping {
  TreeDrawerSettings  *treeDrawerSettings = [self treeDrawerSettings];
  NSObject <FileItemMappingScheme>  *colorMapping = 
    [[treeDrawerSettings colorMapper] fileItemMappingScheme];
    
  if (colorMapping != observedColorMapping) {
    NSNotificationCenter  *nc = [NSNotificationCenter defaultCenter];
    
    if (observedColorMapping != nil) {
      [nc removeObserver: self
                    name: MappingSchemeChangedEvent
                  object: observedColorMapping];
      [observedColorMapping release];
    }

    [nc addObserver: self
           selector: @selector(colorMappingChanged:)
               name: MappingSchemeChangedEvent
             object: colorMapping];
    observedColorMapping = [colorMapping retain];
  }
}

- (void) colorMappingChanged:(NSNotification *) notification {
  // Replace the mapper that is used by a new one (still from the same scheme)
  NSObject <FileItemMapping>  *newMapping =
    [observedColorMapping fileItemMappingForTree: [pathModelView scanTree]];

  [self setTreeDrawerSettings: [[self treeDrawerSettings] copyWithColorMapper: newMapping]];

  [self postColorMappingChanged]; 
}


- (void) updateSelectedItem: (NSPoint) point {
  [pathModelView selectItemAtPoint: point 
                    startingAtTree: [self treeInView]
                usingLayoutBuilder: layoutBuilder
                            bounds: [self bounds]];
  // Redrawing in response to any changes will happen when the change notification is received.
}

@end // @implementation DirectoryView (PrivateMethods)
