#import "ReadTaskInput.h"


@implementation ReadTaskInput

// Overrides designated initialiser
- (instancetype) init {
  NSAssert(NO, @"Use initWithPath: instead");
  return [self initWithPath: nil];
}

- (instancetype) initWithPath:(NSString *)path {
  if (self = [super init]) {
    _path = [path retain];
  }
  
  return self;
}

- (void) dealloc {
  [_path release];
  
  [super dealloc];
}

@end
