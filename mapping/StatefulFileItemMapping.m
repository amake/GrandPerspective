#import "StatefulFileItemMapping.h"


@implementation StatefulFileItemMapping

- (instancetype) initWithFileItemMappingScheme:(NSObject <FileItemMappingScheme> *)schemeVal {
  if (self = [super init]) {
    scheme = [schemeVal retain];
  } 
  
  return self;
}

- (void) dealloc {
  [scheme release];

  [super dealloc];
}


- (NSObject <FileItemMappingScheme> *)fileItemMappingScheme {
  return scheme;
}


- (NSUInteger) hashForFileItem:(PlainFileItem *)item atDepth:(NSUInteger)depth {
  return 0;
}

- (NSUInteger) hashForFileItem:(PlainFileItem *)item inTree:(FileItem *)treeRoot {
  // By default assuming that "depth" is not used in the hash calculation.
  // If it is, this method needs to be overridden.
  return [self hashForFileItem: item atDepth: 0];
}


- (BOOL) canProvideLegend {
  return NO;
}

@end
