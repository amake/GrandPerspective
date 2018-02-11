#import "ItemSizeTestFinder.h"


@implementation ItemSizeTestFinder

- (instancetype) init {
  if (self = [super init]) {
    _itemSizeTestFound = NO;
  }
  
  return self;
}

// Limited "setter"
- (void) reset {
  _itemSizeTestFound = NO;
}


- (void) visitItemSizeTest:(ItemSizeTest *)test {
  _itemSizeTestFound = YES;
}

@end
