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

#import "FileItemHashingOptions.h"

#import "DirectoryItem.h" // Imports FileItem.h
#import "FileItemHashing.h"

@interface HashingByDepth : FileItemHashing {
}
@end

@interface HashingByExtension : FileItemHashing {
}
@end

@interface HashingByFilename : FileItemHashing {
}
@end

@interface HashingByDirectoryName : FileItemHashing {
}
@end


@implementation HashingByDepth

- (int) hashForFileItem:(FileItem*)item depth:(int)depth {
  return depth;
}

@end // HashingByDepth


@implementation HashingByExtension

- (int) hashForFileItem:(FileItem*)item depth:(int)depth {
  return [[[item name] pathExtension] hash];
}

@end // HashingByExtension


@implementation HashingByFilename

- (int) hashForFileItem:(FileItem*)item depth:(int)depth {
  return [[item name] hash];
}

@end //HashingByFilename


@implementation HashingByDirectoryName

- (int) hashForFileItem:(FileItem*)item depth:(int)depth {
  return [[[item parentDirectory] name] hash];
}

@end // HashingByDirectoryName 


@implementation FileItemHashingOptions

FileItemHashingOptions  *defaultFileItemHashingOptions = nil;

+ (FileItemHashingOptions*) defaultFileItemHashingOptions {
  if (defaultFileItemHashingOptions==nil) {
    defaultFileItemHashingOptions = [[FileItemHashingOptions alloc] init];
  }
  
  return defaultFileItemHashingOptions;
}

// Uses a default set of five coloring options.
// Overrides super's designated initialiser.
- (id) init {
  NSMutableDictionary  *colorings = 
    [NSMutableDictionary dictionaryWithCapacity:5];

  [colorings setObject:[[[HashingByDirectoryName alloc] init] autorelease]
               forKey:@"directory"];
  [colorings setObject:[[[HashingByExtension alloc] init] autorelease]
               forKey:@"extension"];
  [colorings setObject:[[[HashingByFilename alloc] init] autorelease]
               forKey:@"name"];
  [colorings setObject:[[[HashingByDepth alloc] init] autorelease]
               forKey:@"depth"];
  [colorings setObject:[[[FileItemHashing alloc] init] autorelease]
               forKey:@"nothing"];

  return [self initWithDictionary:colorings defaultKey:@"directory"];
}

- (id) initWithDictionary:(NSDictionary*)dictionary {
  // Init with arbitrary key as default
  return [self initWithDictionary:dictionary 
                 defaultKey:[[dictionary keyEnumerator] nextObject]];
}

- (id) initWithDictionary:(NSDictionary*)dictionary defaultKey:defaultKeyVal {
  if (self = [super init]) {
    optionsDictionary = [dictionary retain];
    defaultKey = [defaultKeyVal retain];
  }
  return self;
}

- (void) dealloc {
  [optionsDictionary release];
  [defaultKey release];
  
  [super dealloc];
}

- (NSArray*) allKeys {
  return [optionsDictionary allKeys];
}

- (NSString*) keyForDefaultHashing {
  return defaultKey;
}

- (FileItemHashing*) fileItemHashingForKey:(NSString*)key {
  return [optionsDictionary objectForKey:key];
}

@end
