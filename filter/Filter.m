#import "Filter.h"

#import "FileItemTest.h"
#import "FilterTestRepository.h"
#import "FilterTestRef.h"

#import "CompoundAndItemTest.h"
#import "CompoundOrItemTest.h"
#import "NotItemTest.h"

@interface Filter (PrivateMethods)

- (FileItemTest *)combineTests:(NSArray *)fileItemTests;

@end

@implementation Filter

+ (instancetype) filter {
  return [[[Filter alloc] init] autorelease];
}

+ (instancetype) filterWithFilterTests:(NSArray *)filterTests {
  return [[[Filter alloc] initWithFilterTests: filterTests] autorelease];
}

+ (instancetype) filterWithFilter:(Filter *)filter {
  return [[[Filter alloc] initWithFilter: filter] autorelease];
}


+ (Filter *)filterFromDictionary:(NSDictionary *)dict {
  NSArray  *storedFilterTests = dict[@"tests"];
  NSMutableArray  *testRefs = [NSMutableArray arrayWithCapacity: storedFilterTests.count];
    
  NSEnumerator  *testEnum = storedFilterTests.objectEnumerator;
  NSDictionary  *storedFilterTest;
  while (storedFilterTest = [testEnum nextObject]) {
    FilterTestRef  *testRef = [FilterTestRef filterTestRefFromDictionary: storedFilterTest];
    [testRefs addObject: testRef];
  }
  
  return [Filter filterWithFilterTests: testRefs];
}


- (instancetype) init {
  return [self initWithFilterTests: @[]];
}

- (instancetype) initWithFilter:(Filter *)filter {
  return [self initWithFilterTests: filter.filterTests];
}

- (instancetype) initWithFilterTests:(NSArray *)filterTests {
  if (self = [super init]) {
    // Copy to ensure immutability
    _filterTests = [[NSArray alloc] initWithArray: filterTests];
  }

  return self;
}


- (void) dealloc {
  [_filterTests release];

  [super dealloc];
}


- (NSUInteger) numFilterTests {
  return self.filterTests.count;
}

- (FilterTestRef *)filterTestAtIndex:(NSUInteger)index {
  return self.filterTests[index];
}

- (FilterTestRef *)filterTestWithName:(NSString *)testName {
  NSEnumerator  *filterTestEnum = self.filterTests.objectEnumerator;
  FilterTestRef  *filterTest;

  while (filterTest = [filterTestEnum nextObject]) {
    if ([filterTest.name isEqualToString: testName]) {
      return filterTest;
    }
  }
  return nil;
}

- (NSUInteger) indexOfFilterTest:(FilterTestRef *)test {
  return [self.filterTests indexOfObject: test];
}


- (FileItemTest *)createFileItemTestUnboundTests:(NSMutableArray *)unboundTests {
  return [self createFileItemTestFromRepository: FilterTestRepository.defaultInstance
                                   unboundTests: unboundTests];
}

- (FileItemTest *)createFileItemTestFromRepository:(FilterTestRepository *)repository
                                      unboundTests:(NSMutableArray *)unboundTests {
  NSMutableArray  *positiveTests = [NSMutableArray arrayWithCapacity: self.numFilterTests];
  NSMutableArray  *negativeTests = [NSMutableArray arrayWithCapacity: self.numFilterTests];

  NSEnumerator  *filterTestEnum = self.filterTests.objectEnumerator;
  FilterTestRef  *filterTest;

  while (filterTest = [filterTestEnum nextObject]) {
    FileItemTest  *subTest = [repository fileItemTestForName: filterTest.name];

    if (subTest != nil) {
      if (filterTest.isInverted) {
        [negativeTests addObject: subTest];
      } else {
        [positiveTests addObject: subTest];
      }
    }
    else {
      [unboundTests addObject: filterTest.name];
    }
  }

  FileItemTest  *positiveClause = [self combineTests: positiveTests];
  FileItemTest  *negativeClause = [self combineTests: negativeTests];
  if (negativeClause != nil) {
    negativeClause = [[[NotItemTest alloc] initWithSubItemTest: negativeClause] autorelease];
  }

  if (positiveClause != nil && negativeClause != nil) {
    return [[[CompoundAndItemTest alloc] initWithSubItemTests: @[positiveClause, negativeClause]]
            autorelease];
  } else {
    return (positiveClause != nil) ? positiveClause : negativeClause;
  }
}

- (NSDictionary *)dictionaryForObject {
  NSMutableArray  *storedTests = [NSMutableArray arrayWithCapacity: self.numFilterTests];
  NSEnumerator  *testEnum = [self.filterTests objectEnumerator];
  FilterTestRef  *testRef;
  while (testRef = [testEnum nextObject]) {
    [storedTests addObject: [testRef dictionaryForObject]];
  }
  
  return @{@"tests": storedTests};
}

@end // @implementation Filter

@implementation Filter (PrivateMethods)

- (FileItemTest *)combineTests:(NSArray *)fileItemTests {
  if (fileItemTests.count == 0) {
    return nil;
  }
  else if (fileItemTests.count == 1) {
    return fileItemTests[0];
  }
  else {
    return [[[CompoundOrItemTest alloc] initWithSubItemTests: fileItemTests] autorelease];
  }
}

@end // @implementation Filter (PrivateMethods)
