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

#import "TreeLayoutTraverser.h"

@class TreeLayoutBuilder;
@class FileItemHashing;
@class ColorPalette;

@interface DirectoryViewDrawer : NSObject <TreeLayoutTraverser> {

  FileItemHashing  *fileItemHashing;

  // Only set when it has not yet been loaded into the gradient array.
  ColorPalette  *colorPalette;
  UInt32  *gradientColors;
  int  numGradientColors;

  NSImage  *image;
  NSBitmapImageRep  *drawBitmap;

  NSConditionLock  *workLock;
  NSLock           *settingsLock;  
  BOOL             abort;

  // Settings for next drawing task
  Item               *drawItemTree; // Assumed to be immutable
  TreeLayoutBuilder  *drawLayoutBuilder; // Assumed to be immutable
  NSRect             drawInRect;
}

- (id) initWithFileItemHashing:(FileItemHashing*)fileItemHashing;

- (id) initWithFileItemHashing:(FileItemHashing*)fileItemHashing
                  colorPalette:(ColorPalette*)colorPalette;

- (void) setFileItemHashing:(FileItemHashing*)fileItemHashing;
- (FileItemHashing*) fileItemHashing;

- (void) setColorPalette:(ColorPalette*)colorPalette;

// Both "itemTreeRoot" and "layoutBuilder" should be immutable.
- (void) drawItemTree:(Item*)itemTreeRoot 
           usingLayoutBuilder:(TreeLayoutBuilder*)layoutBuilder
           inRect:(NSRect)bounds;

- (NSImage*) getImage;
- (void) resetImage;

@end
