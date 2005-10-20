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

#import "ColorPalette.h"


@implementation ColorPalette

ColorPalette  *defaultPalette = nil;

+ (ColorPalette*) defaultColorPalette {
  if (defaultPalette == nil) {
    defaultPalette = [[ColorPalette alloc] init];
  }
  
  return defaultPalette;
}

// Uses a default list of eight colors.
// Overrides super's designated initialiser.
- (id) init {
  NSMutableArray  *colors = [NSMutableArray arrayWithCapacity:8];

  [colors addObject:[NSColor blueColor]];
  [colors addObject:[NSColor redColor]];
  [colors addObject:[NSColor greenColor]];
  [colors addObject:[NSColor cyanColor]];
  [colors addObject:[NSColor magentaColor]];
  [colors addObject:[NSColor orangeColor]];
  [colors addObject:[NSColor yellowColor]];
  [colors addObject:[NSColor purpleColor]];
  
  return [self initWithColors:colors];
}

- (id) initWithColors:(NSArray*)colorArrayVal {
  if (self = [super init]) {
    colorArray = [colorArrayVal retain];
  }
  return self;
}

- (void) dealloc {
  [colorArray release];
  
  [super dealloc];
}

- (NSColor*) getColorForInt:(unsigned)intVal {
  return [colorArray objectAtIndex:(intVal % [colorArray count])];
  // Note: not retaining-autoreleasing it for efficiency. Should be okay as
  // the color palette should be longer lived than the stack whenever this
  // method is called
}

- (int) numColors {
  return [colorArray count];
}

@end
