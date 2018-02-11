#import "PlainFileItem.h"

#import "UniformType.h"

@implementation PlainFileItem

// Overrides designated initialiser
- (instancetype) initWithLabel:(NSString *)label
                        parent:(DirectoryItem *)parent
                          size:(ITEM_SIZE)size
                         flags:(FileItemOptions)flags
                  creationTime:(CFAbsoluteTime)creationTime
              modificationTime:(CFAbsoluteTime)modificationTime
                    accessTime:(CFAbsoluteTime)accessTime {
  return [self initWithLabel: label
                      parent: parent
                        size: size
                        type: nil
                       flags: flags
                creationTime: creationTime
            modificationTime: modificationTime
                  accessTime: accessTime];
}

- (instancetype) initWithLabel:(NSString *)label
                        parent:(DirectoryItem *)parent
                          size:(ITEM_SIZE)size
                          type:(UniformType *)type
                         flags:(FileItemOptions)flags
                  creationTime:(CFAbsoluteTime)creationTime
              modificationTime:(CFAbsoluteTime)modificationTime
                    accessTime:(CFAbsoluteTime)accessTime {
  if (self = [super initWithLabel: label
                           parent: parent
                             size: size
                            flags: flags
                     creationTime: creationTime
                 modificationTime: modificationTime
                       accessTime: accessTime]) {
    _uniformType = [type retain];
  }
  
  return self;
}

- (void) dealloc {
  [_uniformType release];
  
  [super dealloc];
}


- (FileItem *)duplicateFileItem:(DirectoryItem *)newParent {
  return [[[PlainFileItem allocWithZone: [newParent zone]] initWithLabel: self.label
                                                                  parent: newParent
                                                                    size: self.itemSize
                                                                    type: self.uniformType
                                                                   flags: self.fileItemFlags
                                                            creationTime: self.creationTime
                                                        modificationTime: self.modificationTime
                                                              accessTime: self.accessTime]
          autorelease];
}

@end
