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

#import "Item.h"

@interface CompoundItem : Item {
  Item*  first;
  Item*  second;
}

/* Both items must be non-nil.
 */
- (id) initWithFirst:(Item*)first second:(Item*)second;

- (Item*) getFirst;

- (Item*) getSecond;

/* Can handle case where either one or both are nil:
 * If both are nil, it returns nil
 * If one item is nil, it returns the other item
 * Otherwise it returns a CompoundItem  containing both.
 */
+ (Item*) compoundItemWithFirst:(Item*)first second:(Item*)second;

@end
