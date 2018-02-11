#import "DirectoryItem.h"

#import "PlainFileItem.h"
#import "UniformTypeInventory.h"


@implementation DirectoryItem

// Overrides designated initialiser
- (instancetype) initWithLabel:(NSString *)label
                        parent:(DirectoryItem *)parent
                          size:(ITEM_SIZE)size
                         flags:(FileItemOptions)flags
                  creationTime:(CFAbsoluteTime)creationTime
              modificationTime:(CFAbsoluteTime)modificationTime
                    accessTime:(CFAbsoluteTime)accessTime {
  NSAssert(NO, @"Initialize without size.");
  return [self initWithLabel: nil parent: nil flags: 0 creationTime: 0 modificationTime: 0
                  accessTime: 0];
}


- (instancetype) initWithLabel:(NSString *)label
                        parent:(DirectoryItem *)parent
                         flags:(FileItemOptions)flags
                  creationTime:(CFAbsoluteTime)creationTime
              modificationTime:(CFAbsoluteTime)modificationTime
                    accessTime:(CFAbsoluteTime)accessTime {
  
  if (self = [super initWithLabel: label
                           parent: parent
                             size: 0
                            flags: flags
                     creationTime: creationTime
                 modificationTime: modificationTime
                       accessTime: accessTime]) {
    _contents = nil;
  }
  return self;
}


- (void) dealloc {
  [_contents release];

  [super dealloc];
}


- (FileItem *)duplicateFileItem:(DirectoryItem *)newParent {
  return [[[DirectoryItem allocWithZone: [newParent zone]] 
              initWithLabel: self.label
                     parent: newParent
                      flags: self.fileItemFlags
               creationTime: self.creationTime
           modificationTime: self.modificationTime
                 accessTime: self.accessTime
            ] autorelease];
}


// Special "setter" with additional constraints
- (void) setDirectoryContents:(Item *)contents {
  NSAssert(_contents == nil, @"Contents should only be set once.");
  
  _contents = [contents retain];
  if (contents != nil) {
    self.itemSize = contents.itemSize;
  }
}

// Special "setter" with additional constraints
- (void) replaceDirectoryContents:(Item *)newItem {
  NSAssert(newItem.itemSize == self.contents.itemSize, @"Sizes must be equal.");
  
  if (_contents != newItem) {
    [_contents release];
    _contents = [newItem retain];
  }
}


- (FileItem *)itemWhenHidingPackageContents {
  if ([self isPackage]) {
    UniformType  *fileType = [[UniformTypeInventory defaultUniformTypeInventory]
                              uniformTypeForExtension: [self systemPathComponent].pathExtension];
  
    // Note: This item is short-lived, so it is allocated in the default zone.
    return [[[PlainFileItem alloc]
             initWithLabel: self.label
                    parent: self.parentDirectory
                      size: self.itemSize
                      type: fileType
                     flags: self.fileItemFlags
              creationTime: self.creationTime
          modificationTime: self.modificationTime
                accessTime: self.accessTime
              ] autorelease];
  }
  else {
    return self;
  }
}


- (NSString *)description {
  return [NSString stringWithFormat:
          @"DirectoryItem(%@, %qu, %@)", self.label, self.itemSize, self.contents.description];
}


- (FILE_COUNT) numFiles {
  return self.contents.numFiles;
}

- (BOOL) isDirectory {
  return YES;
}

@end // @implementation DirectoryItem

