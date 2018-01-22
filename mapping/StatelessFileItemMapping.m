#import "StatelessFileItemMapping.h"

@implementation StatelessFileItemMapping

- (NSObject <FileItemMapping> *)fileItemMappingForTree:(DirectoryItem *)tree {
  return self;
}

- (NSObject <FileItemMappingScheme> *)fileItemMappingScheme {
  return self;
}


- (NSUInteger) hashForFileItem:(PlainFileItem *)item atDepth:(NSUInteger)depth {
  return 0;
}

- (NSUInteger) hashForFileItem:(PlainFileItem *)item inTree:(FileItem *)treeRoot {
  // By default assuming that "depth" is not used in the hash calculation. If it is, this method
  // needs to be overridden.
  return [self hashForFileItem: item atDepth: 0];
}


- (BOOL) canProvideLegend {
  return NO;
}

@end
