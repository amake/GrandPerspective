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

#import <Cocoa/Cocoa.h>

#import "TreeLayoutTraverser.h"

@class TreeLayoutBuilder;
@protocol FileItemColoring;

@interface DirectoryViewDrawer : NSObject <TreeLayoutTraverser> {

  // TODO: Why not id <FileItemColoring>?
  id  fileItemColoring;

  NSImage  *image;

  NSConditionLock  *workLock;
  NSLock           *settingsLock;  
  BOOL             abort;

  // Settings for next drawing task
  Item               *drawItemTree; // Assumed to be immutable
  TreeLayoutBuilder  *drawLayoutBuilder; // Assumed to be immutable
  NSRect             drawInRect;
}

- (id) initWithFileItemColoring:(id <FileItemColoring>)fileItemColoring;

- (void) setFileItemColoring:(id <FileItemColoring>)fileItemColoring;
- (id <FileItemColoring>) fileItemColoring;

// Both "itemTreeRoot" and "layoutBuilder" should be immutable.
- (void) drawItemTree:(Item*)itemTreeRoot 
           usingLayoutBuilder:(TreeLayoutBuilder*)layoutBuilder
           inRect:(NSRect)bounds;

- (NSImage*) getImage;
- (void) resetImage;

@end
