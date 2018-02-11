#import "WriteTaskInput.h"


@implementation WriteTaskInput

// Overrides designated initialiser
- (instancetype) init {
  NSAssert(NO, @"Use initWithAnnotatedTreeContext:path: instead");
  return [self initWithAnnotatedTreeContext: nil path: nil];
}

- (instancetype) initWithAnnotatedTreeContext:(AnnotatedTreeContext *)context
                                         path:(NSString *)path {
  if (self = [super init]) {
    _annotatedTreeContext = [context retain];
    _path = [path retain];
  }
  
  return self;
}

- (void) dealloc {
  [_annotatedTreeContext release];
  [_path release];
  
  [super dealloc];
}

@end
