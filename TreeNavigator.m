/* GrandPerspective, Version 0.91 
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

#import "TreeNavigator.h"

#import "FileItem.h"
#import "TreeLayoutBuilder.h"
#import "TreeLayoutTraverser.h"


@interface ItemPathManager : NSObject<TreeLayoutTraverser> {
  NSMutableArray  *path;

  // The index in the path array where the subtree starts (always a FileItem)
  unsigned  visibleTreeRootIndex;

  // Temporary variables only used for building the path
  unsigned  buildPathIndex;  
  NSPoint   buildTargetPoint;
}

- (id) initWithTree:(Item*)itemTreeRoot;

- (NSArray*) itemPath;
- (NSArray*) invisibleItemPath;
- (NSArray*) visibleItemPath;
- (FileItem*) itemPathEndPoint;

- (BOOL) clearVisibleItemPath;
- (BOOL) buildVisibleItemPathToPoint:(NSPoint)point 
           usingLayoutBuilder:(TreeLayoutBuilder*)layoutBuilder 
           bounds:(NSRect)bounds;

- (unsigned) indexOfVisibleItemTreeInPath;
- (FileItem*) visibleItemTree;

- (BOOL) canMoveTreeViewUp;
- (BOOL) canMoveTreeViewDown;
- (void) moveTreeViewUp;
- (void) moveTreeViewDown;

@end // @interface ItemPathManager


@interface ItemPathDrawer : NSObject<TreeLayoutTraverser> {
  BOOL          highlightPathEndPoint;

  // Temporary variables only used for drawing the path
  NSArray*      drawPath;
  unsigned int  drawPathIndex;
}

- (void) setHighlightPathEndPoint:(BOOL)option;

- (id) drawItemPath:(NSArray*)path fromIndex:(unsigned)startIndex 
         tree:(Item*)tree usingLayoutBuilder:(TreeLayoutBuilder*)layoutBuilder
         bounds:(NSRect)bounds;

@end // @interface ItemPathDrawer


@interface TreeNavigator (PrivateMethods)

- (void) postVisibleItemPathChanged;
- (void) postVisibleItemPathLockingChanged;
- (void) postVisibleItemTreeChanged;

@end // @interface TreeNavigator (PrivateMethods)


@implementation ItemPathManager 

// Overrides super's designated initialiser.
- (id) init {
  NSAssert(NO, @"Use initWithTree instead.");
}

- (id) initWithTree:(Item*)itemTreeRoot {
  if (self = [super init]) {
    path = [[NSMutableArray alloc] initWithCapacity:64];

    NSAssert(![itemTreeRoot isVirtual], @"Tree root must not be virtual");
    
    [path addObject:itemTreeRoot];
    visibleTreeRootIndex = 0;
  }
  return self;
}

- (void) dealloc {
  [path release];
  
  [super dealloc];
}

- (NSArray*) itemPath {
  return path;
}

- (NSArray*) invisibleItemPath {
  NSMutableArray  *invisible = [NSMutableArray arrayWithCapacity:8];

  int  i = 0;
  while (i <= visibleTreeRootIndex) {
    if (![[path objectAtIndex:i] isVirtual]) {
      [invisible addObject:[path objectAtIndex:i]];
    }
    i++;
  }
  
  return invisible;
}

- (NSArray*) visibleItemPath {
  NSMutableArray  *visible = [NSMutableArray arrayWithCapacity:8];
  int  i = visibleTreeRootIndex + 1, max = [path count];
  while (i < max) {
    if (![[path objectAtIndex:i] isVirtual]) {
      [visible addObject:[path objectAtIndex:i]];
    }
    i++;
  }
  return visible;
}

- (FileItem*) itemPathEndPoint {
  return [path lastObject];
}

- (BOOL) clearVisibleItemPath {
  int  num = [path count] - visibleTreeRootIndex - 1;

  if (num > 0) {
    [path removeObjectsInRange:NSMakeRange(visibleTreeRootIndex+1, num)];
    return YES;
  }

  return NO;
}

- (BOOL) buildVisibleItemPathToPoint:(NSPoint)target
           usingLayoutBuilder:(TreeLayoutBuilder*)layoutBuilder
           bounds:(NSRect)bounds {
  Item*  prevEndPoint = [path lastObject];

  buildPathIndex = visibleTreeRootIndex;
  buildTargetPoint = target;
  
  [layoutBuilder layoutItemTree:[self visibleItemTree] inRect:bounds
                   traverser:self];

  if (buildPathIndex == visibleTreeRootIndex) {
    // Point must have been outside bounds 
    // TODO: only enabling mouse moved events within view bounds?
    [self clearVisibleItemPath];
  }
  else {
    // Strip virtual items from end of path. Last item should be a real one.
    while ([[path objectAtIndex:buildPathIndex-1] isVirtual]) {
      NSAssert(buildPathIndex > visibleTreeRootIndex, @"Stripping too much.");
      buildPathIndex--;
    }

    if (buildPathIndex < [path count]) {
      // Drop last items (either virtual or still from previous path)
      [path removeObjectsInRange:NSMakeRange(buildPathIndex, 
                                             [path count] - buildPathIndex)];
    }
  }  

  return (prevEndPoint != [path lastObject]);
}

- (BOOL) descendIntoItem:(Item*)item atRect:(NSRect)rect depth:(int)depth {
  if (!NSPointInRect(buildTargetPoint, rect)) {
    return NO;
  }

  if (buildPathIndex == [path count]) {
    [path addObject:item];
  }
  else if ([path objectAtIndex:buildPathIndex] != item) {
    [path replaceObjectAtIndex:buildPathIndex withObject:item];
  }
  buildPathIndex++;

  // track path further
  return YES;
}

- (unsigned) indexOfVisibleItemTreeInPath {
  return visibleTreeRootIndex;
}
- (FileItem*) visibleItemTree {
  return [path objectAtIndex:visibleTreeRootIndex];
}

- (BOOL) canMoveTreeViewUp {
  return (visibleTreeRootIndex > 0);
}

- (BOOL) canMoveTreeViewDown {
  return (visibleTreeRootIndex+1 < [path count]);
}

- (void) moveTreeViewUp {
  NSAssert([self canMoveTreeViewUp], @"Cannot move up.");
  do {
    visibleTreeRootIndex--;
  } while ([[path objectAtIndex:visibleTreeRootIndex] isVirtual]);
}

- (void) moveTreeViewDown {
  NSAssert([self canMoveTreeViewDown], @"Cannot move down.");
  do {
    visibleTreeRootIndex++;
  } while ([[path objectAtIndex:visibleTreeRootIndex] isVirtual]);  
}

@end // @implementation ItemPathBuilder


@implementation ItemPathDrawer

- (void) setHighlightPathEndPoint:(BOOL)option {
  highlightPathEndPoint = option;
}

- (id) drawItemPath:(NSArray*)path fromIndex:(unsigned)startIndex 
         tree:(Item*)tree usingLayoutBuilder:(TreeLayoutBuilder*)layoutBuilder
         bounds:(NSRect)bounds {

  drawPath = path; // Not retaining it. It's only needed during this method.
  drawPathIndex = startIndex;

  [layoutBuilder layoutItemTree:tree inRect:bounds traverser:self];

  drawPath = nil;
}

- (BOOL) descendIntoItem:(Item*)item atRect:(NSRect)rect depth:(int)depth {
  if (drawPathIndex >= [drawPath count] 
        || [drawPath objectAtIndex:drawPathIndex]!=item) {
    return NO;
  }

  drawPathIndex++;

  if (![item isVirtual] && depth > 0) {
    NSBezierPath  *bPath = [NSBezierPath bezierPathWithRect:rect];

    if (drawPathIndex == [drawPath count]) {
      [[NSColor selectedControlColor] set];
      
      if (highlightPathEndPoint) {
        [bPath setLineWidth:2];
      }
    }
    else {
      [[NSColor secondarySelectedControlColor] set];
    }
    [bPath stroke];
  }

  return YES;
}

@end // @implementation ItemPathDrawer


@implementation TreeNavigator

// Overrides super's designated initialiser.
- (id) init {
  NSAssert(NO, @"Use initWithTree instead.");
}

- (id) initWithTree:(Item*)itemTreeRoot {
  if (self = [super init]) {
    pathManager = [[ItemPathManager alloc] initWithTree:itemTreeRoot];
    pathDrawer = [[ItemPathDrawer alloc] init];
    
    pathLocked = NO;
    [pathDrawer setHighlightPathEndPoint:pathLocked];
  }
  return self;
}

- (void) dealloc {
  [pathManager release];
  [pathDrawer release];
  
  [super dealloc];
}


- (NSArray*) invisibleItemPath {
  return [pathManager invisibleItemPath];
}

- (NSArray*) visibleItemPath {
  return [pathManager visibleItemPath];
}

- (FileItem*) itemPathEndPoint {
  return [pathManager itemPathEndPoint];
}

- (BOOL) clearVisibleItemPath {
  if ([pathManager clearVisibleItemPath]) {
    [self postVisibleItemPathChanged];
    return YES;
  }
  return NO;
}

- (BOOL) buildVisibleItemPathToPoint:(NSPoint)point 
           usingLayoutBuilder:(TreeLayoutBuilder*)layoutBuilder
           bounds:(NSRect)bounds {
  if ([pathManager buildVisibleItemPathToPoint:point
                     usingLayoutBuilder:layoutBuilder bounds:bounds]) {
    [self postVisibleItemPathChanged];
    return YES;
  }
  return NO;                        
}

- (BOOL) isVisibleItemPathLocked {
  return pathLocked;
}

- (BOOL) toggleVisibleItemPathLock {
  pathLocked = !pathLocked;

  [pathDrawer setHighlightPathEndPoint:pathLocked];
  [self postVisibleItemPathLockingChanged];

  return pathLocked;
}

- (void) drawVisibleItemPathUsingLayoutBuilder:
           (TreeLayoutBuilder*)layoutBuilder bounds:(NSRect)bounds {
  [pathDrawer drawItemPath:[pathManager itemPath] 
                fromIndex:[pathManager indexOfVisibleItemTreeInPath]
                tree:[pathManager visibleItemTree]
                usingLayoutBuilder:layoutBuilder bounds:bounds];
}


- (FileItem*) visibleItemTree {
  return [pathManager visibleItemTree];
}

- (BOOL) canMoveTreeViewUp {
  return [pathManager canMoveTreeViewUp];
}

- (BOOL) canMoveTreeViewDown {
  return [pathManager canMoveTreeViewDown];
}

- (void) moveTreeViewUp {
  [pathManager moveTreeViewUp];
  [self postVisibleItemTreeChanged];
}

- (void) moveTreeViewDown {
  [pathManager moveTreeViewDown];
  [self postVisibleItemTreeChanged];
}


- (void) postVisibleItemPathChanged {
  [[NSNotificationCenter defaultCenter]
      postNotificationName:@"visibleItemPathChanged" object:self];
}

- (void) postVisibleItemPathLockingChanged {
  [[NSNotificationCenter defaultCenter]
      postNotificationName:@"visibleItemPathLockingChanged" object:self];
}

- (void) postVisibleItemTreeChanged {
  [[NSNotificationCenter defaultCenter]
      postNotificationName:@"visibleItemTreeChanged" object:self];
}

@end // @implementation TreeNavigator
