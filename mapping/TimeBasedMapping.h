#import <Foundation/Foundation.h>

#import "StatefulFileItemMapping.h"

@class DirectoryItem;
@class FileItem;

/* Mapping scheme that maps each file item to a hash based on a time that is associated with the
 * file item.
 */
@interface TimeBasedMapping : StatefulFileItemMapping {
  CFAbsoluteTime  minTime;
  CFAbsoluteTime  maxTime;
  CFAbsoluteTime  nowTime;
}

- (id) initWithFileItemMappingScheme: (NSObject <FileItemMappingScheme> *)scheme 
                                tree: (DirectoryItem *)tree;

@end // @interface TimeBasedMapping


@interface TimeBasedMapping (ProtectedMethods)

- (CFAbsoluteTime) timeForFileItem: (FileItem *)fileItem;

@end // @interface TimeBasedMapping (ProtectedMethods)
