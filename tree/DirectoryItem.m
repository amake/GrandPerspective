#import "DirectoryItem.h"

#import "PlainFileItem.h"
#import "UniformTypeInventory.h"


@implementation DirectoryItem

// Overrides designated initialiser
- (id) initWithName:(NSString *)name
             parent:(DirectoryItem *)parent 
               size:(ITEM_SIZE) size 
              flags:(UInt8) flags
       creationTime:(CFAbsoluteTime) creationTime 
   modificationTime:(CFAbsoluteTime) modificationTime {
  NSAssert(NO, @"Initialize without size.");
}


- (id) initWithName: (NSString *)nameVal 
             parent: (DirectoryItem *)parentVal
              flags: (UInt8) flagsVal
       creationTime: (CFAbsoluteTime) creationTimeVal
   modificationTime: (CFAbsoluteTime) modificationTimeVal {
  
  if (self = [super initWithName: nameVal
                          parent: parentVal
                            size: 0
                           flags: flagsVal
                    creationTime: creationTimeVal
                modificationTime: modificationTimeVal]) {
    contents = nil;
  }
  return self;
}


- (void) dealloc {
  [contents release];

  [super dealloc];
}


- (FileItem *)duplicateFileItem:(DirectoryItem *)newParent {
  return [[[DirectoryItem allocWithZone: [newParent zone]] 
              initWithName: name 
                    parent: newParent 
                     flags: flags
              creationTime: creationTime 
          modificationTime: modificationTime
           ] autorelease];
}


- (void) setDirectoryContents:(Item *)contentsVal {
  NSAssert(contents == nil, @"Contents should only be set once.");
  
  contents = [contentsVal retain];
  if (contents != nil) {
    size = [contents itemSize];
  }
}


- (void) replaceDirectoryContents:(Item *)newItem {
  NSAssert([newItem itemSize] == [contents itemSize], @"Sizes must be equal.");
  
  if (contents != newItem) {
    [contents release];
    contents = [newItem retain];
  }
}


- (FileItem *)itemWhenHidingPackageContents {
  if ([self isPackage]) {
    UniformType  *fileType = 
      [[UniformTypeInventory defaultUniformTypeInventory] 
         uniformTypeForExtension: [name pathExtension]];
  
    // Note: This item is short-lived, so it is allocated in the default zone.
    return [[[PlainFileItem alloc]
             initWithName: name
                   parent: parent
                     size: size
                     type: fileType
                    flags: flags
             creationTime: creationTime 
         modificationTime: modificationTime
             ] autorelease];
  }
  else {
    return self;
  }
}


- (NSString *)description {
  return [NSString stringWithFormat:@"DirectoryItem(%@, %qu, %@)", name, size,
                     [contents description]];
}


- (FILE_COUNT) numFiles {
  return [contents numFiles];
}

- (BOOL) isDirectory {
  return YES;
}

- (Item *)getContents {
  return contents;
}

@end // @implementation DirectoryItem


@implementation DirectoryItem (ProtectedMethods)

- (NSString *)systemPathComponent {
  if (! [self isPhysical]) {
    return nil;
  }
  if (parent == nil) {
    // This is the volume root. Return the name "as is", it could be "/".
    return [self pathComponent];
  }

  // The path component is the name of a single folder. It may contain
  // slashes, which should be converted to colons.
  return [super systemPathComponent];
}

@end // @implementation DirectoryItem (ProtectedMethods)

