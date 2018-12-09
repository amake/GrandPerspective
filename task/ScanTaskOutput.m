#import "ScanTaskOutput.h"

#import "AlertMessage.h"
#import "TreeContext.h"

@implementation ScanTaskOutput

+ (instancetype) scanTaskOutput:(TreeContext *)treeContext alert:(AlertMessage *)alert {
  return [[[ScanTaskOutput alloc] initWithTreeContext: treeContext alert: alert] autorelease];
}

// Override designated initialiser
- (instancetype) init {
  NSAssert(NO, @"Use initWithTreeContext:alert instead");
  return [self initWithTreeContext: nil alert: nil];
}

- (instancetype) initWithTreeContext:(TreeContext *)treeContext alert:(AlertMessage *)alert {
  if (self = [super init]) {
    NSAssert(treeContext != nil, @"TreeContext must be set.");

    _treeContext = [treeContext retain];
    _alert = [alert retain];
  }
  return self;
}

- (void) dealloc {
  [_treeContext release];
  [_alert release];

  [super dealloc];
}

@end
