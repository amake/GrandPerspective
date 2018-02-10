#import "MutableArrayPool.h"


@implementation MutableArrayPool

// Overrides designated initialiser.
- (instancetype) initWithCapacity:(int)maxSizeVal {
  return [self initWithCapacity: maxSizeVal initialArrayCapacity: 16];
}

- (instancetype) initWithCapacity:(int)maxSizeVal
             initialArrayCapacity:(int)initialArraySize {
  if (self = [super initWithCapacity: maxSizeVal]) {
    initialArrayCapacity = initialArraySize;
  }
  
  return self;
}


- (id) createObject {
  return [NSMutableArray arrayWithCapacity: initialArrayCapacity];
}

- (id) resetObject:(id)object {
  [object removeAllObjects];
  return object;
}

@end
