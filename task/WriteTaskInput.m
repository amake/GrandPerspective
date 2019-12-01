#import "WriteTaskInput.h"


@implementation WriteTaskInput

// Overrides designated initialiser
- (instancetype) init {
  NSAssert(NO, @"Use initWithAnnotatedTreeContext:path: instead");
  return [self initWithAnnotatedTreeContext: nil path: nil];
}

- (instancetype) initWithAnnotatedTreeContext:(AnnotatedTreeContext *)context
                                         path:(NSString *)path {
  return [self initWithAnnotatedTreeContext: context path: path options: nil];
}

- (instancetype) initWithAnnotatedTreeContext:(AnnotatedTreeContext *)context
                                         path:(NSString *)path
                                      options:(id)options {
  if (self = [super init]) {
    _annotatedTreeContext = [context retain];
    _path = [path retain];
    _options = [options retain];
  }
  
  return self;
}

- (void) dealloc {
  [_annotatedTreeContext release];
  [_path release];
  [_options release];
  
  [super dealloc];
}

@end
