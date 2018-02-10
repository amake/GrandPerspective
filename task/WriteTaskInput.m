#import "WriteTaskInput.h"


@implementation WriteTaskInput

// Overrides designated initialiser
- (instancetype) init {
  NSAssert(NO, @"Use initWithAnnotatedTreeContext:path: instead");
  return [self initWithAnnotatedTreeContext: nil path: nil];
}

- (instancetype) initWithAnnotatedTreeContext:(AnnotatedTreeContext *)context
                                         path:(NSString *)pathVal {
  if (self = [super init]) {
    treeContext = [context retain];
    path = [pathVal retain];
  }
  
  return self;
}

- (void) dealloc {
  [treeContext release];
  [path release];
  
  [super dealloc];
}

- (AnnotatedTreeContext *)annotatedTreeContext {
  return treeContext;
}

- (NSString *)path {
  return path;
}

@end
