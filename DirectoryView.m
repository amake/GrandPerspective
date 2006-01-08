#import "DirectoryView.h"

#import "math.h"

#import "FileItem.h"
#import "TreeLayoutBuilder.h"
#import "ItemTreeDrawer.h"
#import "ItemPathDrawer.h"
#import "ItemPathBuilder.h"
#import "ItemPathModel.h"
#import "ColorPalette.h"
#import "TreeLayoutTraverser.h"


@interface DirectoryView (PrivateMethods)

- (void) itemTreeImageReady:(NSNotification*)notification;
- (void) visibleItemPathChanged:(NSNotification*)notification;
- (void) visibleItemTreeChanged:(NSNotification*)notification;

- (void) postVisibleItemPathLockingChanged;

- (void) buildPathToMouseLoc:(NSPoint)point;

- (void) enableTrackingRect;
- (void) disableTrackingRect;

@end  


@interface LayoutLimits : NSObject <TreeLayoutTraverser> {
}
@end // @interface LayoutLimits


@implementation LayoutLimits

- (BOOL) descendIntoItem:(Item*)item atRect:(NSRect)rect depth:(int)depth {
  // Rectangle must enclose one or more pixel "centers", i.e. it must enclose
  // a point (x+0.5, y+0.5) where x, y are integer values. This means that the
  // rectangle will be visible.
  return ((int)(rect.origin.x + rect.size.width + 0.5f) - 
          (int)(rect.origin.x + 0.5f) > 0 && 
          (int)(rect.origin.y + rect.size.height + 0.5f) -
          (int)(rect.origin.y + 0.5f) > 0);
}

@end // @implementation LayoutLimits


@implementation DirectoryView

- (id) initWithFrame:(NSRect)frame {
  if (self = [super initWithFrame:frame]) {
    treeLayoutBuilder = [[TreeLayoutBuilder alloc] init];

    [treeLayoutBuilder setLayoutLimits:
      [[[LayoutLimits alloc] init] autorelease]];
    
    treeDrawer = [[ItemTreeDrawer alloc] init];
    pathDrawer = [[ItemPathDrawer alloc] init];
    
    trackingRectEnabled = NO;

    [[NSNotificationCenter defaultCenter]
      addObserver:self selector:@selector(itemTreeImageReady:)
      name:@"itemTreeImageReady" object:treeDrawer];  
  }
  return self;
}


- (void) dealloc {
  NSLog(@"DirectoryView-dealloc");
  
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
  [treeLayoutBuilder release];
  [treeDrawer release];
  [pathDrawer release];
  [pathBuilder release];
  [pathModel release];

  [super dealloc];
}


- (void) setItemPathModel:(ItemPathModel*)pathModelVal {
  NSAssert(pathModel==nil, @"The item path model should only be set once.");

  pathModel = [pathModelVal retain];

  [[NSNotificationCenter defaultCenter]
      addObserver:self selector:@selector(visibleItemPathChanged:)
      name:@"visibleItemPathChanged" object:pathModel];
  [[NSNotificationCenter defaultCenter]
      addObserver:self selector:@selector(visibleItemTreeChanged:)
      name:@"visibleItemTreeChanged" object:pathModel];
      
  pathBuilder = [[ItemPathBuilder alloc] initWithPathModel:pathModel];
  
  //[[self window] setAcceptsMouseMovedEvents:YES];
  [self setNeedsDisplay:YES];
}

- (void) setFileItemHashing:(FileItemHashing*)fileItemHashing {
  if (fileItemHashing != [self fileItemHashing]) {
    [treeDrawer setFileItemHashing:fileItemHashing];
    [self setNeedsDisplay:YES];
  }
}

- (FileItemHashing*) fileItemHashing {
  return [treeDrawer fileItemHashing];
}


- (BOOL) isVisibleItemPathLocked {
  return visibleItemPathLocked;
}

- (void) setVisibleItemPathLocking:(BOOL)value {
  if (value == visibleItemPathLocked) {
    return; // No change: Ignore.
  }
  
  visibleItemPathLocked = value;
  [self postVisibleItemPathLockingChanged];
  
  // Update the item path drawer directly. Although the drawer could also
  // listen to the notification, it seems better to do it like this. It keeps
  // the item path drawer more general, and as the item path drawer is tightly
  // integrated with this view, there is no harm in updating it directly.
  [pathDrawer setHighlightPathEndPoint:visibleItemPathLocked];
  
  [self setNeedsDisplay:YES]; // Always needs redraw, as locking status changed
}


- (void) drawRect:(NSRect)rect {
  if (pathModel==nil) {
    return;
  }

  NSImage*  image = [treeDrawer getImage];
  if (image==nil || !NSEqualSizes([image size], [self bounds].size)) {
    NSAssert([self bounds].origin.x == 0 &&
             [self bounds].origin.y == 0, @"Bounds not at (0, 0)");

    [self disableTrackingRect];
    
    [[NSColor blackColor] set];
    NSRectFill([self bounds]);
    
    // Create image in background thread.
    [treeDrawer drawItemTree:[pathModel visibleItemTree]
                  usingLayoutBuilder:treeLayoutBuilder
                  inRect:[self bounds]];
  }
  else {
    [image compositeToPoint:NSZeroPoint operation:NSCompositeCopy];
  
    [pathDrawer drawItemPath:[pathModel itemPath] 
         tree:[pathModel visibleItemTree] 
         usingLayoutBuilder:treeLayoutBuilder bounds:[self bounds]];
  }
}


- (BOOL) acceptsFirstResponder {
  return YES;
}

- (BOOL) becomeFirstResponder {
  NSLog(@"becomeFirstResponder");
  return YES;
}

- (BOOL) resignFirstResponder {
  NSLog(@"resignFirstResponder");
  return YES;
}


- (void) mouseDown:(NSEvent*)theEvent {
  NSLog(@"mouseDown");

  [self buildPathToMouseLoc:
          [self convertPoint:[theEvent locationInWindow] fromView:nil]];

  // Toggle the path locking.
  [self setVisibleItemPathLocking:!visibleItemPathLocked];

  [[self window] setAcceptsMouseMovedEvents:!visibleItemPathLocked];
  if (visibleItemPathLocked) {
    [self disableTrackingRect];
    // Note: This should not really be needed, as there should not be a 
    // tracking rectangle anymore when the user clicks in the view. However,
    // this is not always the case. For example, when a small window is
    // maximsed, a new tracking rectangle is set that correctly tracks the 
    // bounds of the larger view. However, if the mouse now happens to be 
    // inside this rectangle, which is likely as the view now fills most of 
    // the screen, no "mouse entered" event is fired and thus the tracking
    // rectangle remains in place. 
  }
}


- (void) mouseEntered:(NSEvent*)theEvent {
  NSLog(@"mouseEntered");
  
  NSAssert(!visibleItemPathLocked, @"mouseEntered while path locked.");
  
  // Remove tracker (it has done its job).
  [self disableTrackingRect];
  
  [[self window] setAcceptsMouseMovedEvents:YES];
}


- (void) mouseMoved:(NSEvent*)theEvent {
  NSPoint  mouseLoc = 
                  [self convertPoint:[theEvent locationInWindow] fromView:nil];
    
  BOOL isInside = [self mouse:mouseLoc inRect:[self bounds]];
  if (isInside) {
    [self buildPathToMouseLoc:mouseLoc];
  }
  else {
    [pathModel clearVisibleItemPath];

    [[self window] setAcceptsMouseMovedEvents:NO];
    [self enableTrackingRect];
  }
}

@end // @implementation DirectoryView


@implementation DirectoryView (PrivateMethods)


- (void) itemTreeImageReady:(NSNotification*)notification {
  // Note: This method is called from the main thread (even though it has been
  // triggered by the drawer's background thread). So calling setNeedsDisplay
  // directly is okay.
  [self setNeedsDisplay:YES];
  
  if (!trackingRectEnabled && !visibleItemPathLocked) {
    // The tracking rectangle was temporarily removed, so enable it again.
    
    [self enableTrackingRect];
  }
}

- (void) visibleItemPathChanged:(NSNotification*)notification {
  [self setNeedsDisplay:YES];
}

- (void) visibleItemTreeChanged:(NSNotification*)notification {
  [treeDrawer resetImage];
  
  [self setNeedsDisplay:YES];
}


- (void) postVisibleItemPathLockingChanged {
  [[NSNotificationCenter defaultCenter]
      postNotificationName:@"visibleItemPathLockingChanged" object:self];
}


- (void) buildPathToMouseLoc:(NSPoint)point {
  [pathBuilder buildVisibleItemPathToPoint:point
                       usingLayoutBuilder:treeLayoutBuilder
                       bounds:[self bounds]];
}


- (void) enableTrackingRect {
  NSAssert(!trackingRectEnabled, @"Tracking rectangle already enabled.");
  
  trackingRectTag = [self addTrackingRect:[self bounds] owner:self 
                              userData:nil assumeInside:NO];
  trackingRectEnabled = YES;

  NSLog(@"Added tracker %d", trackingRectTag);
}

- (void) disableTrackingRect {
  if (trackingRectEnabled) {    
    [self removeTrackingRect:trackingRectTag];
    trackingRectEnabled = NO;

    NSLog(@"Removed tracker %d", trackingRectTag);
  }
}


@end // @implementation DirectoryView (PrivateMethods)
