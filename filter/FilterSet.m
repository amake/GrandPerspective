#import "FilterSet.h"

#import "Filter.h"
#import "NamedFilter.h"
#import "CompoundAndItemTest.h"

#import "FilterRepository.h"
#import "FilterTestRepository.h"

@interface FilterSet (PrivateMethods)

- (instancetype) initWithNamedFilters:(NSArray *)filters
                     filterRepository:(FilterRepository *)filterRepository
                       testRepository:(FilterTestRepository *)testRepository
                       unboundFilters:(NSMutableArray *)unboundFilters
                         unboundTests:(NSMutableArray *)unboundTests;

@end // @interface FilterSet (PrivateMethods)


@implementation FilterSet

+ (instancetype) filterSet {
  return [[[FilterSet alloc] init] autorelease];
}

+ (instancetype) filterSetWithNamedFilter:(NamedFilter *)namedFilter
                           unboundFilters:(NSMutableArray *)unboundFilters
                             unboundTests:(NSMutableArray *)unboundTests {
  NSArray  *namedFilters = @[namedFilter];
  return [FilterSet filterSetWithNamedFilters: namedFilters
                               unboundFilters: unboundFilters
                                 unboundTests: unboundTests];
}

+ (instancetype) filterSetWithNamedFilters:(NSArray *)namedFilters
                            unboundFilters:(NSMutableArray *)unboundFilters
                              unboundTests:(NSMutableArray *)unboundTests {
  FilterRepository  *filterRepo = [FilterRepository defaultInstance];
  FilterTestRepository  *testRepo = [FilterTestRepository defaultInstance];
  return [FilterSet filterSetWithNamedFilters: namedFilters
                             filterRepository: filterRepo
                               testRepository: testRepo
                               unboundFilters: unboundFilters
                                 unboundTests: unboundTests];
}

+ (instancetype) filterSetWithNamedFilters:(NSArray *)namedFilters
                          filterRepository:(FilterRepository *)filterRepository
                            testRepository:(FilterTestRepository *)testRepository
                            unboundFilters:(NSMutableArray *)unboundFilters
                              unboundTests:(NSMutableArray *)unboundTests {
  return [[[FilterSet alloc] initWithNamedFilters: namedFilters
                                 filterRepository: filterRepository
                                   testRepository: testRepository
                                   unboundFilters: unboundFilters
                                     unboundTests: unboundTests]
          autorelease];
}


// Overrides parent's designated initialiser.
- (instancetype) init {
  return [self initWithNamedFilters: @[] fileItemTest: nil];
}

/* Designated initialiser.
 */
- (instancetype) initWithNamedFilters:(NSArray *)filters
                         fileItemTest:(FileItemTest *)fileItemTest {
  if (self = [super init]) {
    // Copy to ensure immutability
    _filters = [[filters copy] retain];
    _fileItemTest = [fileItemTest retain];
  }
  return self;
}

- (void) dealloc {
  [_filters release];
  [_fileItemTest release];
  
  [super dealloc];
}


- (FilterSet *)updatedFilterSetUnboundFilters:(NSMutableArray *)unboundFilters
                                 unboundTests:(NSMutableArray *)unboundTests {
  return [self updatedFilterSetUsingFilterRepository: [FilterRepository defaultInstance]
                                      testRepository: [FilterTestRepository defaultInstance]
                                      unboundFilters: unboundFilters
                                        unboundTests: unboundTests];
}

- (FilterSet *)updatedFilterSetUsingFilterRepository:(FilterRepository *)filterRepository
                                      testRepository:(FilterTestRepository *)testRepository
                                      unboundFilters:(NSMutableArray *)unboundFilters
                                        unboundTests:(NSMutableArray *)unboundTests {
  return [[[FilterSet alloc] initWithNamedFilters: self.filters
                                 filterRepository: filterRepository
                                   testRepository: testRepository
                                   unboundFilters: unboundFilters
                                     unboundTests: unboundTests] autorelease];
}

- (FilterSet *)filterSetWithAddedNamedFilter:(NamedFilter *)filter
                                unboundTests:(NSMutableArray *)unboundTests {
  NSMutableArray  *newFilters = [NSMutableArray arrayWithCapacity: self.numFilters + 1];
    
  [newFilters addObjectsFromArray: self.filters];
  [newFilters addObject: filter];

  FileItemTest  *testForNewFilter = [[filter filter] createFileItemTestUnboundTests: unboundTests];

  // Construct new file item test by combining test for new filter with existing file item test.
  FileItemTest  *newFileItemTest;
  if (self.fileItemTest == nil) {
    newFileItemTest = testForNewFilter;
  } else if (testForNewFilter == nil) {
    newFileItemTest = self.fileItemTest;
  } else {
    newFileItemTest =
      [[CompoundAndItemTest alloc] initWithSubItemTests: @[self.fileItemTest, testForNewFilter]];
  }

  return [[[FilterSet alloc] initWithNamedFilters: newFilters
                                     fileItemTest: newFileItemTest] autorelease];
}


- (NSUInteger) numFilters {
  return self.filters.count;
}

- (NSString *)description {
  NSMutableString  *descr = [NSMutableString stringWithCapacity: 32];
  
  NSEnumerator  *filterEnum = [self.filters objectEnumerator];
  NamedFilter  *namedFilter;

  while (namedFilter = [filterEnum nextObject]) {
    if (descr.length > 0) {
      [descr appendString: @", "];
    }
    [descr appendString: [namedFilter localizedName]];
  }
  
  return descr;
}

@end // @implementation FilterSet


@implementation FilterSet (PrivateMethods)

- (instancetype) initWithNamedFilters:(NSArray *)namedFilters
                     filterRepository:(FilterRepository *)filterRepository
                       testRepository:(FilterTestRepository *)testRepository
                       unboundFilters:(NSMutableArray *)unboundFilters
                         unboundTests:(NSMutableArray *)unboundTests {
  // Create the file item test for the set of filters.
  NSMutableArray  *filterTests = [NSMutableArray arrayWithCapacity: namedFilters.count];

  NSEnumerator  *filterEnum = [namedFilters objectEnumerator];
  NamedFilter  *namedFilter;
  while (namedFilter = [filterEnum nextObject]) {
    Filter  *filter;

    if (filterRepository == nil) {
      // Preserve old filter
      filter = [namedFilter filter];
    } else {
      // Look-up current filter definition
      filter = [filterRepository filtersByName][[namedFilter name]];
      if (filter == nil) {
        // The filter with this name does not exist anymore in the repository
        [unboundFilters addObject: [namedFilter name]];

        // So resort to the original filter
        filter = [namedFilter filter];
      }
    }

    FileItemTest  *filterTest = [filter createFileItemTestFromRepository: testRepository
                                                            unboundTests: unboundTests];
    if (filterTest != nil) {
      [filterTests addObject: filterTest];
    } else {
      // Apparently the filter or its item test(s) do not exist anymore.
      NSLog(@"Could not instantiate test for filter %@", [namedFilter name]);
    }
  }

  FileItemTest  *testForFilterSet;
  if (filterTests.count == 0) {
    testForFilterSet = nil;
  }
  else if (filterTests.count == 1) {
    testForFilterSet = [filterTests[0] retain];
  }
  else {
    testForFilterSet = [[CompoundAndItemTest alloc] initWithSubItemTests: filterTests];
  }

  return [self initWithNamedFilters: namedFilters fileItemTest: testForFilterSet];
}

@end // @implementation FilterSet (PrivateMethods)
