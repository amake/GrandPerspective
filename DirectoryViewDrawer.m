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

#import "DirectoryViewDrawer.h"

#import "FileItem.h"
#import "TreeLayoutBuilder.h"
#import "BasicColoring.h"

enum {
  IMAGE_TASK_PENDING = 345,
  NO_IMAGE_TASK
};

@interface DirectoryViewDrawer (PrivateMethods)

- (void) imageDrawLoop;
- (void) backgroundDrawItemTree:(Item*)itemTreeRoot 
           usingLayoutBuilder:(TreeLayoutBuilder*)layoutBuilder 
           inRect:(NSRect)bounds;
- (void) drawBasicFilledRect:(NSRect)rect color:(NSColor*)color;
- (void) drawGradientFilledRect:(NSRect)rect color:(NSColor*)color;
- (NSColor*) darkenColor:(NSColor*)color by:(float)adjust;
- (NSColor*) lightenColor:(NSColor*)color by:(float)adjust;

@end


@implementation DirectoryViewDrawer

- (id) init {
  return [self initWithFileItemColoring:
           [[[BasicColoring alloc] init] autorelease]];
}

- (id) initWithFileItemColoring:(id <FileItemColoring>)fileItemColoringVal {
  if (self = [super init]) {
    fileItemColoring = fileItemColoringVal;
    [fileItemColoring retain];
  
    workLock = [[NSConditionLock alloc] initWithCondition:NO_IMAGE_TASK];
    settingsLock = [[NSLock alloc] init];
    abort = NO;

    [NSThread detachNewThreadSelector:@selector(imageDrawLoop)
                toTarget:self withObject:nil];
  }
  return self;
}

- (void) dealloc {
  [fileItemColoring release];
  
  [image release];
  
  [workLock release];
  [settingsLock release];
  
  [drawItemTree release];
  [drawLayoutBuilder release];
  
  [super dealloc];
}

- (void) setFileItemColoring:(id <FileItemColoring>)fileItemColoringVal {
  if (fileItemColoringVal != fileItemColoring) {
    [fileItemColoring release];
    fileItemColoring = fileItemColoringVal;
    [fileItemColoring retain];
    [self resetImage];
  }
}

- (id <FileItemColoring>) fileItemColoring {
  return fileItemColoring;
}


- (NSImage*) getImage {
  [settingsLock lock];
  NSImage*  returnImage = [[image retain] autorelease];
  [settingsLock unlock];
  
  return returnImage;
}

- (void) resetImage {
  [settingsLock lock];
  [image release];
  image = nil;
  [settingsLock unlock];
}


- (BOOL) descendIntoItem:(Item*)item atRect:(NSRect)rect depth:(int)depth {
  if (![item isVirtual]) {
    id  file = item;

    if ([file isPlainFile]) {
      [self drawGradientFilledRect:rect 
              color:[fileItemColoring colorForFileItem:file depth:depth]];
    }
    /*
    // nice, but slow
    else {
      [self drawGradientFilledRect:rect color:
        [self darkenColor:[[NSColor darkGrayColor] 
                              colorUsingColorSpaceName:NSDeviceRGBColorSpace] 
                       by:0.2f]];
    }
    */
  }

  // Only descend/continue when the current drawing task has not been aborted.
  return !abort;
}

- (void) drawItemTree:(Item*)itemTreeRoot 
           usingLayoutBuilder:(TreeLayoutBuilder*)layoutBuilder
           inRect:(NSRect)bounds {
  [settingsLock lock];
  if (drawItemTree != itemTreeRoot) {
    [drawItemTree release];
    drawItemTree = [itemTreeRoot retain];
  }
  if (drawLayoutBuilder != layoutBuilder) {
    [drawLayoutBuilder release];
    drawLayoutBuilder = [layoutBuilder retain];
  }
  drawInRect = bounds;
  abort = YES;

  if ([workLock condition] == NO_IMAGE_TASK) {
    // Notify waiting thread
    [workLock lock];
    [workLock unlockWithCondition:IMAGE_TASK_PENDING];
  }
  [settingsLock unlock];
}

@end // @implementation DirectoryViewDrawer


@implementation DirectoryViewDrawer (PrivateMethods)

- (void) imageDrawLoop {
  while (YES) {
    NSAutoreleasePool  *pool = [[NSAutoreleasePool alloc] init];

    [workLock lockWhenCondition:IMAGE_TASK_PENDING];
        
    [settingsLock lock];
    NSAssert(drawItemTree != nil && drawLayoutBuilder != nil, 
             @"Draw task not set properly.");
    Item  *tree = [drawItemTree autorelease];
    TreeLayoutBuilder  *builder = [drawLayoutBuilder autorelease];
    NSRect  rect = drawInRect;
    drawItemTree = nil;
    drawLayoutBuilder = nil;
    abort = NO;
    [settingsLock unlock];

    [self backgroundDrawItemTree:tree usingLayoutBuilder:builder
            inRect:rect];
    
    [settingsLock lock];
    if (!abort) {
      [[NSNotificationCenter defaultCenter]
        postNotificationName:@"itemTreeImageReady" object:self];
      [workLock unlockWithCondition:NO_IMAGE_TASK];
    }
    else {
      [workLock unlockWithCondition:IMAGE_TASK_PENDING];
    }
    [settingsLock unlock];
    
    [pool release];
  }
}

// Called from own thread.
- (void) backgroundDrawItemTree:(Item*)itemTreeRoot 
           usingLayoutBuilder:(TreeLayoutBuilder*)layoutBuilder
           inRect:(NSRect)bounds {
  [self resetImage];

  NSImage  *drawImage = [[NSImage alloc] initWithSize:bounds.size];

  [drawImage lockFocus];
  
  // TODO: cope with fact when bounds not start at (0, 0)? Would this every be
  // useful/occur?
  [[NSColor blackColor] set];
  NSRectFill(bounds);

  [layoutBuilder layoutItemTree:itemTreeRoot inRect:bounds traverser:self];

  [drawImage unlockFocus];
  
  [settingsLock lock];
  if (!abort) {
    image = drawImage;
  }
  else {
    [drawImage release];
  }
  [settingsLock unlock];
}


- (void)drawBasicFilledRect:(NSRect)rect color:(NSColor*)color {
  NSBezierPath  *path = [NSBezierPath bezierPathWithRect:rect];

  [[NSColor blackColor] set];
  [path stroke];
  
  [color set];
  [path fill];
}

- (void)drawGradientFilledRect:(NSRect)rect color:(NSColor*)color {
  NSBezierPath  *bPath = [NSBezierPath bezierPath];
  NSPoint  p1, p2;
  float  r;
  
  // TODO: Make c a configurable parameter.
  float  c = 1.0f;
  
  [bPath setLineCapStyle:NSButtLineCapStyle];
  [bPath setLineWidth:2];

  color = [color colorUsingColorSpaceName:NSDeviceRGBColorSpace];

  p1 = rect.origin;
  p1.y += 1;
  [bPath moveToPoint:p1];
  p1.x += rect.size.width-1;
  [bPath lineToPoint:p1];
  p1.y += rect.size.height-2;
  [bPath lineToPoint:p1];
  [[self darkenColor:color by:0.5f*c] set];
  [bPath stroke];
  
  int  x;
  int  xmin = (int)(rect.origin.x + 1);
  int  xmax = (int)(rect.origin.x + rect.size.width);

  p1.y = rect.origin.y + rect.size.height - 0.5f;
  p2.y = rect.origin.y;// + 0.5f;
  for (x=xmin; x<=xmax; x++) {
    [bPath removeAllPoints];

    r = (xmax > xmin) ? (x-xmin)/(float)(xmax-xmin) : 0.5f;

    p1.x = x;
    p2.x = x;

    [bPath moveToPoint:p1];
    [bPath lineToPoint:p2];
    
    // TODO: use caching of colors? Now very many colors/objects created during
    // drawing (only freed when drawing is finished).
    if (r < 0.5f) {
      [[self lightenColor:color by:(0.5f-r)*c] set];
    }
    else {
      [[self darkenColor:color by:(r-0.5f)*c] set];
    }
    
    [bPath stroke];
  } 

  int  y;
  int  ymin = (int)(rect.origin.y+1);
  int  ymax = (int)(rect.origin.y + rect.size.height);

  p1.x = rect.origin.x - 0.5f;
  for (y=ymin; y<=ymax; y++) {
    [bPath removeAllPoints];

    r = (ymax > ymin) ? (y-ymin)/(float)(ymax-ymin) : 0.5f;
 
    p1.y = y;
    p2.y = y;
    p2.x = p1.x + (1-r)*rect.size.width;

    [bPath moveToPoint:p1];
    [bPath lineToPoint:p2];

    if (r < 0.5f) {
      [[self darkenColor:color by:(0.5f-r)*c] set];
    }
    else {
      [[self lightenColor:color by:(r-0.5f)*c] set];
    }
    
    [bPath stroke];
  }
}


- (NSColor*) darkenColor:(NSColor*)color by:(float)adjust {
  NSAssert(adjust >= 0.0f && adjust <= 1.0f, @"adjust amount outside range");

  // Descrease brightness
  return 
    [NSColor colorWithDeviceHue:[color hueComponent] 
                     saturation:[color saturationComponent]
                     brightness:[color brightnessComponent]*(1-adjust)
                          alpha:[color alphaComponent]];
}

- (NSColor*) lightenColor:(NSColor*)color by:(float)adjust {
  NSAssert(adjust >= 0.0f && adjust <= 1.0f, @"adjust amount outside range");

  // First ramp up brightness, then decrease saturation  
  float dif = 1 - [color brightnessComponent];
  float absAdjust = (dif + [color saturationComponent]) * adjust;
  if (absAdjust < dif) {
    return 
      [NSColor colorWithDeviceHue:[color hueComponent] 
                       saturation:[color saturationComponent]
                       brightness:[color brightnessComponent] + absAdjust
                            alpha:[color alphaComponent]];
  }
  else {
    return 
      [NSColor colorWithDeviceHue:[color hueComponent] 
                       saturation:[color saturationComponent] - absAdjust + dif
                       brightness:1.0f
                            alpha:[color alphaComponent]];
  }
}

@end // @implementation DirectoryViewDrawer (PrivateMethods)
