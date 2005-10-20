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

#import <Cocoa/Cocoa.h>

@class TreeLayoutBuilder;
@class ItemPathManager;
@class ItemPathDrawer;
@class Item;
@class FileItem;

@interface TreeNavigator : NSObject {
  ItemPathManager  *pathManager;
  ItemPathDrawer  *pathDrawer;
  
  BOOL  pathLocked;
}

- (id) initWithTree:(Item*)itemTreeRoot;

// Returns all file items from root until (inclusive) root in view
- (NSArray*) invisibleItemPath;

// Returns all file item in view path (excluding root in view)
- (NSArray*) visibleItemPath;

- (FileItem*) itemPathEndPoint;

// Returns "YES" if the visible item path has changed
- (BOOL) clearVisibleItemPath;

// Returns "YES" if the visible item path has changed
- (BOOL) buildVisibleItemPathToPoint:(NSPoint)point 
           usingLayoutBuilder:(TreeLayoutBuilder*)layoutBuilder
           bounds:(NSRect)bounds;

- (BOOL) isVisibleItemPathLocked;
- (BOOL) toggleVisibleItemPathLock;

- (void) drawVisibleItemPathUsingLayoutBuilder:(TreeLayoutBuilder*)layoutBuilder
           bounds:(NSRect)bounds;

- (FileItem*) visibleItemTree;

- (BOOL) canMoveTreeViewUp;
- (BOOL) canMoveTreeViewDown;
- (void) moveTreeViewUp;
- (void) moveTreeViewDown;

@end
