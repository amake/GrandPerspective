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

#import "TreeLayoutBuilder.h"

#import "TreeLayoutTraverser.h"
#import "CompoundItem.h"
#import "DirectoryItem.h" // Also imports FileItem.h


@interface TreeLayoutBuilder (PrivateMethods) 
  - (void) layoutItemTree:(id)root inRect:(NSRect)rect 
             traverser:(id <TreeLayoutTraverser>)traverser depth:(int)depth;
@end


@implementation TreeLayoutBuilder

- (void) dealloc {
  [layoutLimits release];
  
  [super dealloc];
}


- (void) setLayoutLimits:(id <TreeLayoutTraverser>)layoutLimitsVal {
  NSAssert(layoutLimitsVal!=nil, @"Cannot be nil.");
  if (layoutLimits!=layoutLimitsVal) {
    [layoutLimits release];
    layoutLimits = layoutLimitsVal;
    [layoutLimits retain];
  }
}


- (void) layoutItemTree:(Item*)itemTreeRoot inRect:(NSRect)bounds
           traverser:(id <TreeLayoutTraverser>)traverser {
  [self layoutItemTree:itemTreeRoot inRect:bounds traverser:traverser depth:0];
}

@end // @implementation TreeLayoutBuilder


@implementation TreeLayoutBuilder (PrivateMethods)

- (void) layoutItemTree:(id)root inRect:(NSRect)rect 
          traverser:(id <TreeLayoutTraverser>)traverser depth:(int)depth {
  
  //NSLog(@"%@", NSStringFromRect(rect));
  
  if (!([layoutLimits descendIntoItem:root atRect:rect depth:depth] &&
        [traverser descendIntoItem:root atRect:rect depth:depth])) {
    return;
  }
  
  if ([root isVirtual]) {
    Item  *sub1 = [root getFirst];
    Item  *sub2 = [root getSecond];
    
    float  ratio = 
      ([root itemSize]>0) ? ([sub1 itemSize]/(float)[root itemSize]) : 0.50;
    NSRect  rect1;
    NSRect  rect2;
    
    if (NSWidth(rect) > NSHeight(rect)) {
      NSDivideRect(rect, &rect1, &rect2, ratio*NSWidth(rect), NSMaxXEdge);
    }
    else {
      NSDivideRect(rect, &rect1, &rect2, ratio*NSHeight(rect), NSMinYEdge); 
    }
    
    //NSLog(@"%@ divided into %@ and %@", NSStringFromRect(rect),
    //      NSStringFromRect(rect1), NSStringFromRect(rect2));
    
    [self layoutItemTree:sub1 inRect:rect1 traverser:traverser depth:depth];
    [self layoutItemTree:sub2 inRect:rect2 traverser:traverser depth:depth];
  }
  else if (![root isPlainFile]) { 
    Item*  sub = [root getContents];		

    if (sub!=nil) {
      [self layoutItemTree:sub inRect:rect traverser:traverser depth:depth+1];
    }
  }
}

@end // @implementation TreeLayoutBuilder (PrivateMethods)
