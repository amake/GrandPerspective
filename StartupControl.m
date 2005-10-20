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

#import "StartupControl.h"

#import "FileItem.h"

#import "BalancedTreeBuilder.h"
#import "DirectoryViewControl.h"

@interface StartupControl (PrivateMethods)
- (void)readDirectories:(NSString*)dirName;
- (void)createWindowForTree:(FileItem*)itemTree;
@end


@implementation StartupControl

- (id) init {
  if (self = [super init]) {
    // void
  }
  return self;
}

- (void) dealloc {
  NSAssert(treeBuilder == nil, @"TreeBuilder should be nil.");
  
  [dirViewControl release];
  
  [super dealloc];
}

- (IBAction) abort:(id)sender {
  [treeBuilder abort];
}

- (void) applicationDidFinishLaunching:(NSNotification *)notification {
  [self openDirectoryView:self];
}

- (IBAction) openDirectoryView:(id)sender {
  NSOpenPanel  *openPanel = [NSOpenPanel openPanel];
  [openPanel setCanChooseFiles:NO];
  [openPanel setCanChooseDirectories:YES];
  [openPanel setAllowsMultipleSelection:NO];

  if ([openPanel runModalForTypes:nil] == NSOKButton) {
    NSString  *dirName = 
      [[[openPanel filenames] objectAtIndex:0] retain];
  
    [NSThread detachNewThreadSelector:@selector(readDirectories:)
                             toTarget:self withObject:dirName];
  }
}


- (BOOL) validateMenuItem:(NSMenuItem *)anItem {
  if ([anItem action]==@selector(duplicateDirectoryView:)) {
    return ([[NSApplication sharedApplication] mainWindow] != nil);
  }
  
  return YES;
}


- (IBAction) duplicateDirectoryView:(id)sender {
  DirectoryViewControl  *controller = 
    [[[NSApplication sharedApplication] mainWindow] windowController];
  
  if ([controller itemTree]!=nil) {
    [self createWindowForTree:[controller itemTree]];
  }
}

@end // @implementation StartupControl


@implementation StartupControl (PrivateMethods)

- (void) readDirectories:(NSString*)dirName {
  NSAutoreleasePool *pool;
  pool = [[NSAutoreleasePool alloc] init];
  
  NSDate  *startTime = [NSDate date];
  
  [progressText setStringValue:@"Scanning directory..."];
  [progressPanel center];
  [progressPanel orderFront:self];
  
  [progressIndicator startAnimation:nil];
  
  treeBuilder = [[BalancedTreeBuilder alloc] init];
  
  FileItem*  itemTreeRoot = [treeBuilder buildTreeForPath:dirName];
  
  [treeBuilder release];
  treeBuilder = nil;
  [dirName release];
  
  [progressIndicator stopAnimation:nil];
  NSLog(@"Done scanning. Total size=%qu, Time taken=%f", 
        [itemTreeRoot itemSize], -[startTime timeIntervalSinceNow]);
  
  [progressPanel close];
  
  if (itemTreeRoot != nil) {
    [self createWindowForTree:itemTreeRoot];
  }
  
  [pool release];  
}


- (void) createWindowForTree:(FileItem*)itemTree {
  dirViewControl = [[DirectoryViewControl alloc] initWithItemTree:itemTree];
      
  // Force loading (and showing) of the window.
  [[dirViewControl window] setTitle:[itemTree name]];
}

@end // @implementation StartupControl (PrivateMethods)
