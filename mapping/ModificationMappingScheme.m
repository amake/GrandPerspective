#import "ModificationMappingScheme.h"

#import "FileItem.h"
#import "TimeBasedMapping.h"

@interface MappingByModification : TimeBasedMapping {
}
@end // @interface MappingByModification


@implementation ModificationMappingScheme

//----------------------------------------------------------------------------
// Implementation of FileItemMappingScheme protocol

- (NSObject <FileItemMapping> *) fileItemMappingForTree: (DirectoryItem *)tree {
  return [[[MappingByModification alloc] 
           initWithFileItemMappingScheme: self tree: tree] autorelease];
}

@end // @implementation ModificationMappingScheme


@implementation MappingByModification

- (CFAbsoluteTime) timeForFileItem: (FileItem *)fileItem {
  return [fileItem modificationTime];
}

@end // @implementation MappingByModification
