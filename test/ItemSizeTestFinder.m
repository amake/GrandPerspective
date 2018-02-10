#import "ItemSizeTestFinder.h"


@implementation ItemSizeTestFinder

- (instancetype) init {
  if (self = [super init]) {
    itemSizeTestFound = NO;
  }
  
  return self;
}


- (void) reset {
  itemSizeTestFound = NO;
}

- (BOOL) itemSizeTestFound {
  return itemSizeTestFound;
}


- (void) visitItemSizeTest:(ItemSizeTest *)test {
  itemSizeTestFound = YES;
}

@end
