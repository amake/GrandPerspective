#import "DirectoryView.h"

#import "math.h"

#import "FileItem.h"
#import "TreeLayoutBuilder.h"
#import "DirectoryViewDrawer.h"
#import "TreeNavigator.h"
#import "ColorPalette.h"
#import "TreeLayoutTraverser.h"


@interface DirectoryView (PrivateMethods)

- (void) selectItemAtMouseLoc:(NSPoint)point;

- (void) itemTreeImageReady:(NSNotification*)notification;
- (void) visibleItemPathChanged:(NSNotification*)notification;
- (void) visibleItemTreeChanged:(NSNotification*)notification;

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
    
    treeDrawer = [[DirectoryViewDrawer alloc] init];

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
  [treeNavigator release];

  [super dealloc];
}


- (void) setTreeNavigator:(TreeNavigator*)treeNavigatorVal {
  NSAssert(treeNavigator==nil, @"tree navigator should only be set once.");

  treeNavigator = [treeNavigatorVal retain];

  [[NSNotificationCenter defaultCenter]
      addObserver:self selector:@selector(visibleItemPathChanged:)
      name:@"visibleItemPathChanged" object:treeNavigator];
  [[NSNotificationCenter defaultCenter]
      addObserver:self selector:@selector(visibleItemTreeChanged:)
      name:@"visibleItemTreeChanged" object:treeNavigator];
      
  [[self window] setAcceptsMouseMovedEvents:YES];
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

- (void) drawRect:(NSRect)rect {
  if (treeNavigator==nil) {
    return;
  }

  NSImage*  image = [treeDrawer getImage];
  if (image==nil || !NSEqualSizes([image size], [self bounds].size)) {
    NSAssert([self bounds].origin.x == 0 &&
             [self bounds].origin.y == 0, @"Bounds not at (0, 0)");

    [[NSColor blackColor] set];
    NSRectFill([self bounds]);
    
    // Create image in background thread.
    [treeDrawer drawItemTree:[treeNavigator visibleItemTree]
                  usingLayoutBuilder:treeLayoutBuilder
                  inRect:[self bounds]];
  }
  else {
    [image compositeToPoint:NSZeroPoint operation:NSCompositeCopy];
  
    [treeNavigator drawVisibleItemPathUsingLayoutBuilder:treeLayoutBuilder
                     bounds:[self bounds]];
  }
}

- (BOOL) acceptsFirstResponder {
  return YES;
}

- (BOOL) becomeFirstResponder {
  //NSLog(@"becomeFirstResponder");
  //[[self window] setAcceptsMouseMovedEvents:NO];
  return YES;
}

- (BOOL) resignFirstResponder {
  //NSLog(@"resignFirstResponder");
  [[self window] setAcceptsMouseMovedEvents:NO];
  return YES;
}


- (void) mouseDown:(NSEvent*)theEvent {
  //NSLog(@"mouseDown");

  [self selectItemAtMouseLoc:
          [self convertPoint:[theEvent locationInWindow] fromView:nil]];

  [[self window] 
      setAcceptsMouseMovedEvents: ![treeNavigator toggleVisibleItemPathLock]];
  [self setNeedsDisplay:YES]; // Always needs redraw, as locking status changed
}

- (void) mouseMoved:(NSEvent*)theEvent {
  if ([treeNavigator isVisibleItemPathLocked]) {
    NSLog(@"Error? mouseMoved event while locked.");
    return;
  }
  [self selectItemAtMouseLoc:
          [self convertPoint:[theEvent locationInWindow] fromView:nil]];
}

// TODO: doesn't works yet, why?
- (void) mouseEntered:(NSEvent*)theEvent {
  if ([treeNavigator isVisibleItemPathLocked]) {
    return;
  }
  NSLog(@"mouseEntered");
  [self selectItemAtMouseLoc:
          [self convertPoint:[theEvent locationInWindow] fromView:nil]];
}

// TODO: doesn't works yet, why?
- (void) mouseExited:(NSEvent*)theEvent {
  if ([treeNavigator isVisibleItemPathLocked]) {
    return;
  }
  NSLog(@"mouseExited");

  if ([treeNavigator clearVisibleItemPath]) {
    [self setNeedsDisplay:YES];
  }
}

@end // @implementation DirectoryView


@implementation DirectoryView (PrivateMethods)

- (void) selectItemAtMouseLoc:(NSPoint)mouseLoc {
  if ([treeNavigator buildVisibleItemPathToPoint:mouseLoc
                       usingLayoutBuilder:treeLayoutBuilder
                       bounds:[self bounds]]) {
    // Note: not strictly necessary, as notification should follow as well.
    [self setNeedsDisplay:YES];
  }
}

- (void) itemTreeImageReady:(NSNotification*)notification {
  // Note: This method is called from the main thread (even though it has been
  // triggered by the drawer's background thread). So calling setNeedsDisplay
  // directly is okay.
  [self setNeedsDisplay:YES];
}

- (void) visibleItemPathChanged:(NSNotification*)notification {
  [self setNeedsDisplay:YES];
}

- (void) visibleItemTreeChanged:(NSNotification*)notification {
  [treeDrawer resetImage];
  
  [self setNeedsDisplay:YES];
}

@end // @implementation DirectoryView (PrivateMethods)
