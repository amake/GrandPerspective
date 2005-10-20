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

#import "CompoundItem.h"


@implementation CompoundItem

+ (Item*) compoundItemWithFirst:(Item*)firstVal second:(Item*)secondVal {
  if (firstVal!=nil && secondVal!=nil) {
    return [[[CompoundItem alloc] initWithFirst:firstVal second:secondVal]
            autorelease];
  }
  if (firstVal!=nil) {
    return firstVal;
  }
  if (secondVal!=nil) {
    return secondVal;
  }
  return nil;
}


// Overrides super's designated initialiser.
- (id) initWithItemSize:(ITEM_SIZE)size {
  NSAssert(NO, @"Use initWithFirst:second instead.");
}

- (id) initWithFirst:(Item*)firstVal second:(Item*)secondVal {
  NSAssert(firstVal!=nil && secondVal!=nil, @"Both values must be non nil.");
  
  if (self = [super initWithItemSize:([firstVal itemSize] + 
                                      [secondVal itemSize])]) {
    first = [firstVal retain];
    second = [secondVal retain];
  }

  return self;
}


- (void) dealloc {
  [first release];
  [second release];
  
  [super dealloc];
}


- (NSString*) description {
  return [NSString stringWithFormat:@"CompoundItem(%@, %@)", first, second];
}

- (BOOL) isVirtual {
  return YES;
}


- (Item*) getFirst {
  return first;
}

- (Item*) getSecond {
  return second;
}

@end
