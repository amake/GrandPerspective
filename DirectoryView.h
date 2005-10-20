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
@class DirectoryViewDrawer;
@class TreeNavigator;
@class FileItemHashing;

// TEMP implements TreeLayoutTraverser
#import "TreeLayoutTraverser.h"

@interface DirectoryView : NSView <TreeLayoutTraverser> {

  TreeLayoutBuilder  *treeLayoutBuilder;
  DirectoryViewDrawer  *treeDrawer;
  TreeNavigator  *treeNavigator;

}

- (void) setTreeNavigator:(TreeNavigator*)navigator;

- (void) setFileItemHashing:(FileItemHashing*)fileItemHashing;
- (FileItemHashing*) fileItemHashing;

@end
