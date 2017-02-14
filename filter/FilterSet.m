#import "FilterSet.h"

#import "Filter.h"
#import "NamedFilter.h"
#import "CompoundAndItemTest.h"

#import "FilterRepository.h"
#import "FilterTestRepository.h"

@interface FilterSet (PrivateMethods)

- (id) initWithNamedFilters:(NSArray *)filters
           filterRepository:(FilterRepository *)filterRepository
             testRepository:(FilterTestRepository *)testRepository
             unboundFilters:(NSMutableArray *)unboundFilters
               unboundTests:(NSMutableArray *)unboundTests;

@end // @interface FilterSet (PrivateMethods)


@implementation FilterSet

+ (id) filterSet {
  return [[[FilterSet alloc] init] autorelease];
}

+ (id) filterSetWithNamedFilter:(NamedFilter *)namedFilter
                 unboundFilters:(NSMutableArray *)unboundFilters
                   unboundTests:(NSMutableArray *)unboundTests {
  NSArray  *namedFilters = [NSArray arrayWithObject: namedFilter];
  return [FilterSet filterSetWithNamedFilters: namedFilters
                               unboundFilters: unboundFilters
                                 unboundTests: unboundTests];
}

+ (id) filterSetWithNamedFilters:(NSArray *)namedFilters
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

+ (id) filterSetWithNamedFilters:(NSArray *)namedFilters
                filterRepository:(FilterRepository *)filterRepository
                  testRepository:(FilterTestRepository *)testRepository
                  unboundFilters:(NSMutableArray *)unboundFilters
                    unboundTests:(NSMutableArray *)unboundTests {
  // Clone to ensure immutability
  NSArray  *clonedNamedFilters = [NSArray arrayWithArray: namedFilters];
  return [[[FilterSet alloc] initWithNamedFilters: clonedNamedFilters
                                 filterRepository: filterRepository
                                   testRepository: testRepository
                                   unboundFilters: unboundFilters
                                     unboundTests: unboundTests]
          autorelease];
}


// Overrides parent's designated initialiser.
- (id) init {
  return [self initWithNamedFilters: [NSArray array]
                       fileItemTest: nil];
}

/* Designated initialiser.
 */
- (id) initWithNamedFilters:(NSArray *)filtersVal
               fileItemTest:(FileItemTest *)fileItemTestVal {
  if (self = [super init]) {
    filters = [filtersVal retain];
    fileItemTest = [fileItemTestVal retain];
  }
  return self;
}

- (void) dealloc {
  [filters release];
  [fileItemTest release];
  
  [super dealloc];
}


- (FilterSet *)updatedFilterSetUnboundFilters:(NSMutableArray *)unboundFilters
                                 unboundTests:(NSMutableArray *)unboundTests {
  return [self updatedFilterSetUsingFilterRepository: 
                   [FilterRepository defaultInstance]
                  testRepository: [FilterTestRepository defaultInstance]
                  unboundFilters: unboundFilters
                  unboundTests: unboundTests];
}

- (FilterSet *)updatedFilterSetUsingFilterRepository:(FilterRepository *)filterRepository
                                      testRepository:(FilterTestRepository *)testRepository
                                      unboundFilters:(NSMutableArray *)unboundFilters
                                        unboundTests:(NSMutableArray *)unboundTests {
  return [[[FilterSet alloc] initWithNamedFilters: filters
                                 filterRepository: filterRepository
                                   testRepository: testRepository
                                   unboundFilters: unboundFilters
                                     unboundTests: unboundTests] autorelease];
}

- (FilterSet *)filterSetWithAddedNamedFilter:(NamedFilter *)filter
                                unboundTests:(NSMutableArray *)unboundTests {
  NSMutableArray  *newFilters =
    [NSMutableArray arrayWithCapacity: [filters count]+1];
    
  [newFilters addObjectsFromArray: filters];
  [newFilters addObject: filter];

  FileItemTest  *testForNewFilter =
  [[filter filter] createFileItemTestUnboundTests: unboundTests];

  // Construct new file item test by combining test for new filter with
  // existing file item test.
  FileItemTest  *newFileItemTest;
  if (fileItemTest == nil) {
    newFileItemTest = testForNewFilter;
  } else if (testForNewFilter == nil) {
    newFileItemTest = fileItemTest;
  } else {
    newFileItemTest = [[CompoundAndItemTest alloc] initWithSubItemTests:
                       [NSArray arrayWithObjects:
                        fileItemTest, testForNewFilter, nil]];
  }

  return [[[FilterSet alloc] initWithNamedFilters: newFilters
                                     fileItemTest: newFileItemTest]
          autorelease];
}

- (FileItemTest *)fileItemTest {
  return fileItemTest;
}


- (NSUInteger) numFilters {
  return [filters count];
}

- (NSArray *)filters {
  return [NSArray arrayWithArray: filters];
}


- (NSString *)description {
  NSMutableString  *descr = [NSMutableString stringWithCapacity: 32];
  
  NSEnumerator  *filterEnum = [filters objectEnumerator];
  NamedFilter  *namedFilter;

  while (namedFilter = [filterEnum nextObject]) {
    if ([descr length] > 0) {
      [descr appendString: @", "];
    }
    [descr appendString: [namedFilter localizedName]];
  }
  
  return descr;
}

@end // @implementation FilterSet


@implementation FilterSet (PrivateMethods)

- (id) initWithNamedFilters:(NSArray *)namedFilters
           filterRepository:(FilterRepository *)filterRepository
             testRepository:(FilterTestRepository *)testRepository
             unboundFilters:(NSMutableArray *)unboundFilters
               unboundTests:(NSMutableArray *)unboundTests {
  // Create the file item test for the set of filters.
  NSMutableArray  *filterTests =
  [NSMutableArray arrayWithCapacity: [namedFilters count]];

  NSEnumerator  *filterEnum = [namedFilters objectEnumerator];
  NamedFilter  *namedFilter;
  while (namedFilter = [filterEnum nextObject]) {
    Filter  *filter;

    if (filterRepository == nil) {
      // Preserve old filter
      filter = [namedFilter filter];
    } else {
      // Look-up current filter definition
      filter = [[filterRepository filtersByName]
                objectForKey: [namedFilter name]];
      if (filter == nil) {
        // The filter with this name does not exist anymore in the repository
        [unboundFilters addObject: [namedFilter name]];

        // So resort to the original filter
        filter = [namedFilter filter];
      }
    }

    FileItemTest  *filterTest =
    [filter createFileItemTestFromRepository: testRepository
                                unboundTests: unboundTests];
    if (filterTest != nil) {
      [filterTests addObject: filterTest];
    } else {
      // Apparently the filter or its item test(s) do not exist anymore.
      NSLog(@"Could not instantiate test for filter %@", [namedFilter name]);
    }
  }

  FileItemTest  *testForFilterSet;
  if ([filterTests count] == 0) {
    testForFilterSet = nil;
  }
  else if ([filterTests count] == 1) {
    testForFilterSet = [[filterTests objectAtIndex: 0] retain];
  }
  else {
    testForFilterSet =
    [[CompoundAndItemTest alloc] initWithSubItemTests: filterTests];
  }

  return [self initWithNamedFilters: namedFilters
                       fileItemTest: testForFilterSet];
}

@end // @implementation FilterSet (PrivateMethods)
