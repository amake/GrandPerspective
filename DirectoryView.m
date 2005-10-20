/* GrandPerspective, Version 0.90 
 *   A utility for Mac OS X that graphically shows disk usage. 
 * Copyright (C) 2005, Eriban Software 
 * 
 * This program is free software; you can redistribute it and/or modify it 
 * under the terms of the GNU General Public License as published by the Free 
 * Software Foundation; either version 2 of the License, or (at your option) 
 * any later version. 
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT 
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or 
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for 
 * more details. 
 * 
 * You should have received a copy of the GNU General Public License along 
 * with this program; if not, write to the Free Software Foundation, Inc., 
 * 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA. 
 */

#import "DirectoryView.h"

#import "FileItem.h"
#import "TreeLayoutBuilder.h"
#import "DirectoryViewDrawer.h"
#import "TreeNavigator.h"
#import "ColorPalette.h"

@interface DirectoryView (PrivateMethods)

- (void) selectItemAtMouseLoc:(NSPoint)point;

- (void) itemTreeImageReady:(NSNotification*)notification;
- (void) visibleItemPathChanged:(NSNotification*)notification;
- (void) visibleItemTreeChanged:(NSNotification*)notification;
@end  


@implementation DirectoryView

- (id) initWithFrame:(NSRect)frame {
  if (self = [super initWithFrame:frame]) {
    treeLayoutBuilder = [[TreeLayoutBuilder alloc] init];

    // TEMP
    [treeLayoutBuilder setLayoutLimits:self];
    
    treeDrawer = [[DirectoryViewDrawer alloc] init];
          
    [[NSNotificationCenter defaultCenter]
      addObserver:self selector:@selector(itemTreeImageReady:)
      name:@"itemTreeImageReady" object:treeDrawer];  
  }
  return self;
}

- (void) dealloc {
  [treeLayoutBuilder release];
  [treeDrawer release];
  [treeNavigator release];

  [super dealloc];
}

// TEMP: used for layout limits.
- (BOOL) descendIntoItem:(Item*)item atRect:(NSRect)rect depth:(int)depth {
  return (rect.size.width >= 1 && rect.size.height >= 1);
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

- (void) setFileItemColoring:(id <FileItemColoring>)fileItemColoring {
  if (fileItemColoring != [self fileItemColoring]) {
    [treeDrawer setFileItemColoring:fileItemColoring];
    [self setNeedsDisplay:YES];
  }
}

- (id <FileItemColoring>) fileItemColoring {
  return [treeDrawer fileItemColoring];
}

- (void) drawRect:(NSRect)rect {
  if (treeNavigator==nil) {
    return;
  }

  NSImage*  image = [treeDrawer getImage];
  if (image==nil || !NSEqualSizes([image size], [self bounds].size)) {
    NSAssert([self bounds].origin.x == 0 &&
             [self bounds].origin.y == 0, @"Bounds not at (0, 0)");

    // Create image in background thread.
    [treeDrawer drawItemTree:[treeNavigator visibleItemTree]
                  usingLayoutBuilder:treeLayoutBuilder
                  inRect:[self bounds]];
                  
    [[NSColor blackColor] set];
    NSRectFill([self bounds]);
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
