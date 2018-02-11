#import <Cocoa/Cocoa.h>

#import "FileItem.h"

@class UniformType;

/* Represents a plain file that, unlike a directory, may have a type associated with it.
 * 
 * TODO: Could reduce memory footprint by using two different implementations of the interface. The
 * type only needs to be stored when it is not nil. The other implementation can simply return nil
 * in its implementation of -uniformType.
 */
@interface PlainFileItem : FileItem {
}

- (instancetype) initWithLabel:(NSString *)label
                        parent:(DirectoryItem *)parent
                          size:(ITEM_SIZE)size
                          type:(UniformType *)type
                         flags:(UInt8)flags
                  creationTime:(CFAbsoluteTime)creationTime
              modificationTime:(CFAbsoluteTime)modificationTime
                    accessTime:(CFAbsoluteTime)accessTime NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly, strong) UniformType *uniformType;

@end
