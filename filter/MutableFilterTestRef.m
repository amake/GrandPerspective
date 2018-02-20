#import "MutableFilterTestRef.h"


@implementation MutableFilterTestRef

// Override designated initialiser
- (instancetype) initWithName:(NSString *)name inverted:(BOOL)inverted {
  if (self = [super initWithName: name inverted: inverted]) {
    // Set default value
    _canToggleInverted = YES;
    invertedToggle = NO;
  }

  return self;
}


- (BOOL) isInverted {
  return [super isInverted] != invertedToggle;
}

- (void) toggleInverted {
  NSAssert([self canToggleInverted], @"Cannot toggle test.");
  invertedToggle = !invertedToggle;
}

@end // @implementation MutableFilterTestRef
