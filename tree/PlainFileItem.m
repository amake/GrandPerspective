#import "PlainFileItem.h"

#import "UniformType.h"

@implementation PlainFileItem

// Overrides designated initialiser
- (id) initWithLabel:(NSString *)labelVal
              parent:(DirectoryItem *)parentVal
                size:(ITEM_SIZE)sizeVal
               flags:(UInt8)flagsVal
        creationTime:(CFAbsoluteTime)creationTimeVal
    modificationTime:(CFAbsoluteTime)modificationTimeVal
          accessTime:(CFAbsoluteTime)accessTimeVal {
  return [self initWithLabel: labelVal
                      parent: parentVal
                        size: sizeVal
                        type: nil
                       flags: flagsVal
                creationTime: creationTimeVal
            modificationTime: modificationTimeVal
                  accessTime: accessTimeVal];
}

- (id) initWithLabel:(NSString *)labelVal
              parent:(DirectoryItem *)parentVal
                size:(ITEM_SIZE)sizeVal
                type:(UniformType *)typeVal
               flags:(UInt8)flagsVal
        creationTime:(CFAbsoluteTime)creationTimeVal
    modificationTime:(CFAbsoluteTime)modificationTimeVal
          accessTime:(CFAbsoluteTime)accessTimeVal {
  if (self = [super initWithLabel: labelVal
                           parent: parentVal
                             size: sizeVal
                            flags: flagsVal
                     creationTime: creationTimeVal
                 modificationTime: modificationTimeVal
                       accessTime: accessTimeVal]) {
    type = [typeVal retain];
  }
  
  return self;
}

- (void) dealloc {
  [type release];
  
  [super dealloc];
}


- (FileItem *)duplicateFileItem:(DirectoryItem *)newParent {
  return [[[PlainFileItem allocWithZone: [newParent zone]] initWithLabel: label
                                                                  parent: newParent
                                                                    size: size
                                                                    type: type
                                                                   flags: flags
                                                            creationTime: creationTime
                                                        modificationTime: modificationTime
                                                              accessTime: accessTime]
          autorelease];
}


- (UniformType *)uniformType {
  return type;
}

@end
