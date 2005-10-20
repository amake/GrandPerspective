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

#import "BasicColoring.h"

#import "ColorPalette.h"

@implementation BasicColoring

// Overrides super's designated initialiser.
- (id) init {
  return [self initWithColorPalette:[ColorPalette defaultColorPalette]];
}

- (id) initWithColorPalette:(ColorPalette*)colorPaletteVal {
  if (self = [super init]) {
    colorPalette = [colorPaletteVal retain];
  }
  return self;
}

- (void) dealloc {
  [colorPalette release];

  [super dealloc];
}

- (NSColor*) colorForFileItem:(FileItem*)item depth:(int)depth {
  return [colorPalette getColorForInt:0];
}

@end
