#import "AccessMappingScheme.h"

#import "FileItem.h"
#import "TimeBasedMapping.h"

@interface MappingByAccess : TimeBasedMapping {
}
@end // @interface MappingByAccess


@implementation AccessMappingScheme

//----------------------------------------------------------------------------
// Implementation of FileItemMappingScheme protocol

- (NSObject <FileItemMapping> *) fileItemMappingForTree: (DirectoryItem *)tree {
  return [[[MappingByAccess alloc] initWithFileItemMappingScheme: self tree: tree] autorelease];
}

@end // @implementation AccessMappingScheme


@implementation MappingByAccess

- (CFAbsoluteTime) timeForFileItem: (FileItem *)fileItem {
  return [fileItem accessTime];
}

@end // @implementation MappingByAccess
