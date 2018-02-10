#import "ReadTaskInput.h"


@implementation ReadTaskInput

// Overrides designated initialiser
- (instancetype) init {
  NSAssert(NO, @"Use initWithPath: instead");
  return nil;
}

- (instancetype) initWithPath:(NSString *)pathVal {
  if (self = [super init]) {
    path = [pathVal retain];
  }
  
  return self;
}

- (void) dealloc {
  [path release];
  
  [super dealloc];
}

- (NSString *)path {
  return path;
}

@end
