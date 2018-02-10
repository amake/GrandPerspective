#import "Filter.h"

#import "FileItemTest.h"
#import "FilterTestRepository.h"
#import "FilterTestRef.h"

#import "CompoundOrItemTest.h"
#import "NotItemTest.h"


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
    
  NSEnumerator  *testEnum = [storedFilterTests objectEnumerator];
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
  return [self initWithFilterTests: [filter filterTests]];
}

- (instancetype) initWithFilterTests:(NSArray *)filterTestsVal {
  if (self = [super init]) {
    filterTests = [[NSArray alloc] initWithArray: filterTestsVal];
  }

  return self;
}


- (void) dealloc {
  [filterTests release];

  [super dealloc];
}


- (NSUInteger) numFilterTests {
  return filterTests.count;
}

- (NSArray *)filterTests {
  return filterTests;
}

- (FilterTestRef *)filterTestAtIndex:(NSUInteger)index {
  return filterTests[index];
}

- (FilterTestRef *)filterTestWithName:(NSString *)testName {
  NSEnumerator  *filterTestEnum = [filterTests objectEnumerator];
  FilterTestRef  *filterTest;

  while (filterTest = [filterTestEnum nextObject]) {
    if ([[filterTest name] isEqualToString: testName]) {
      return filterTest;
    }
  }
  return nil;
}

- (NSUInteger) indexOfFilterTest:(FilterTestRef *)test {
  return [filterTests indexOfObject: test];
}


- (FileItemTest *)createFileItemTestUnboundTests:(NSMutableArray *)unboundTests {
  FilterTestRepository  *testRepo = [FilterTestRepository defaultInstance];
  return [self createFileItemTestFromRepository: testRepo
                                   unboundTests: unboundTests];
}

- (FileItemTest *)createFileItemTestFromRepository:(FilterTestRepository *)repository
                                      unboundTests:(NSMutableArray *)unboundTests {
  NSMutableArray  *subTests = [NSMutableArray arrayWithCapacity: filterTests.count];

  NSEnumerator  *filterTestEnum = [filterTests objectEnumerator];
  FilterTestRef  *filterTest;

  while (filterTest = [filterTestEnum nextObject]) {
    FileItemTest  *subTest = [repository fileItemTestForName: [filterTest name]];

    if (subTest != nil) {
      if ([filterTest isInverted]) {
        subTest = [[[NotItemTest alloc] initWithSubItemTest: subTest] autorelease];
      }
      
      [subTests addObject: subTest];
    }
    else {
      [unboundTests addObject: [filterTest name]];
    }
  }

  if (subTests.count == 0) {
    return nil;
  }
  else if (subTests.count == 1) {
    return subTests[0];
  }
  else {
    return [[[CompoundOrItemTest alloc] initWithSubItemTests: subTests] autorelease];
  }
}

- (NSDictionary *)dictionaryForObject {
  NSMutableArray  *storedTests = [NSMutableArray arrayWithCapacity: filterTests.count];
  NSEnumerator  *testEnum = [filterTests objectEnumerator];
  FilterTestRef  *testRef;
  while (testRef = [testEnum nextObject]) {
    [storedTests addObject: [testRef dictionaryForObject]];
  }
  
  return @{@"tests": storedTests};
}

@end // @implementation Filter
