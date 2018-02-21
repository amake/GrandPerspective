#import "StatefulFileItemMapping.h"


@implementation StatefulFileItemMapping

// Overrides designated initialiser
- (instancetype) init {
  NSAssert(NO, @"Use initWithFileItemMappingScheme: instead.");
  return [self initWithFileItemMappingScheme: nil];
}


- (instancetype) initWithFileItemMappingScheme:(NSObject <FileItemMappingScheme> *)scheme {
  if (self = [super init]) {
    _scheme = [scheme retain];
  } 
  
  return self;
}

- (void) dealloc {
  [_scheme release];

  [super dealloc];
}


- (NSObject <FileItemMappingScheme> *)fileItemMappingScheme {
  return _scheme;
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
