#import "AnnotatedTreeContext.h"

#import "TreeContext.h"

#import "FilterSet.h"
#import "FileItemTest.h"

@implementation AnnotatedTreeContext

+ (instancetype) annotatedTreeContext:(TreeContext *)treeContext {
  return (treeContext == nil 
          ? nil
          : [[[AnnotatedTreeContext alloc] initWithTreeContext: treeContext] autorelease]);
}

+ (instancetype) annotatedTreeContext:(TreeContext *)treeContext
                             comments:(NSString *)comments {
  return (treeContext == nil
          ? nil
          : [[[AnnotatedTreeContext alloc] initWithTreeContext: treeContext comments: comments]
             autorelease]);
}

// Override designated initialiser
- (instancetype) init {
  NSAssert(NO, @"Use initWithTreeContext: instead");
  return [self initWithTreeContext: nil];
}

- (instancetype) initWithTreeContext:(TreeContext *)treeContextVal {
  FileItemTest  *test = [[treeContextVal filterSet] fileItemTest];

  return [self initWithTreeContext: treeContextVal
                          comments: ((test != nil) ? test.description : @"")];
}

- (instancetype) initWithTreeContext:(TreeContext *)treeContext
                            comments:(NSString *)comments {
  if (self = [super init]) {
    NSAssert(treeContext != nil, @"TreeContext must be set.");
  
    _treeContext = [treeContext retain];
    
    // Create a copy of the string, to ensure it is immutable.
    _comments = comments != nil ? [NSString stringWithString: comments] : @"";
    [_comments retain];
  }
  return self;
}

- (void) dealloc {
  [_treeContext release];
  [_comments release];

  [super dealloc];
}

@end
