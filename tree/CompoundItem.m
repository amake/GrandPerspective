#import "CompoundItem.h"


@implementation CompoundItem

+ (Item *)compoundItemWithFirst:(Item *)first second:(Item *)second {
  if (first != nil && second != nil) {
    return [[[CompoundItem allocWithZone: [first zone]] initWithFirst: first
                                                               second: second] autorelease];
  }
  if (first != nil) {
    return first;
  }
  if (second != nil) {
    return second;
  }
  return nil;
}


// Overrides super's designated initialiser.
- (instancetype) initWithItemSize:(ITEM_SIZE)size {
  NSAssert(NO, @"Use initWithFirst:second instead.");
  return [self initWithFirst: nil second: nil];
}

- (instancetype) initWithFirst:(Item *)first second:(Item *)second {
  NSAssert(first != nil && second != nil, @"Both values must be non nil.");
  
  if (self = [super initWithItemSize:([first itemSize] + [second itemSize])]) {
    _first = [first retain];
    _second = [second retain];
    numFiles = [first numFiles] + [second numFiles];
  }

  return self;
}


- (void) dealloc {
  [_first release];
  [_second release];
  
  [super dealloc];
}


- (NSString *)description {
  return [NSString stringWithFormat:@"CompoundItem(%@, %@)", self.first, self.second];
}


- (FILE_COUNT) numFiles {
  return numFiles;
}

- (BOOL) isVirtual {
  return YES;
}


// Custom "setter", which enforces that size remains the same
- (void) replaceFirst:(Item *)newItem {
  NSAssert([newItem itemSize] == [_first itemSize], @"Sizes must be equal.");
  
  if (_first != newItem) {
    [_first release];
    _first = [newItem retain];
  }
}

// Custom "setter", which enforces that size remains the same
- (void) replaceSecond:(Item *)newItem {
  NSAssert([newItem itemSize] == [_second itemSize], @"Sizes must be equal.");
  
  if (_second != newItem) {
    [_second release];
    _second = [newItem retain];
  }
}

@end
