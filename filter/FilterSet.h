#import <Cocoa/Cocoa.h>

@class NamedFilter;
@class FilterRepository;
@class FilterTestRepository;
@class FileItemTest;

/* Set of file item filters. The file item test representing the set of filters is determined when
 * the set is initialised and remains fixed. It is not affected by changes to the file item tests of
 * any of its filters.
 */
@interface FilterSet : NSObject {
  // Array of NamedFilters
  NSArray  *filters;
  
  FileItemTest  *fileItemTest;
}

+ (instancetype) filterSet;

/* Creates a new filter set for the given filter.
 *
 * The default filter and filter test repositories are used.
 */
+ (instancetype) filterSetWithNamedFilter:(NamedFilter *)namedFilter
                           unboundFilters:(NSMutableArray *)unboundFilters
                             unboundTests:(NSMutableArray *)unboundTests;

/* Creates a new filter set for the given filters.
 *
 * The default filter and filter test repositories are used.
 */
+ (instancetype) filterSetWithNamedFilters:(NSArray *)namedFilters
                            unboundFilters:(NSMutableArray *)unboundFilters
                              unboundTests:(NSMutableArray *)unboundTests;

/* Creates a new filter set for the given filters.
 *
 * The specified filter and filter test repositories are used.
 *
 * When "filterRepository" is nil, the filters are not re-instantiated; the existing instances are
 * re-used instead. This is useful when reading stored scan results which store filters as well as
 * their filter tests. In this case, it is best if the filter test resembles the original filter set
 * as much as possible).
 */
+ (instancetype) filterSetWithNamedFilters:(NSArray *)namedFilters
                          filterRepository:(FilterRepository *)filterRepository
                            testRepository:(FilterTestRepository *)testRepository
                            unboundFilters:(NSMutableArray *)unboundFilters
                              unboundTests:(NSMutableArray *)unboundTests;


/* Initialises an empty filter set.
 */
- (instancetype) init;

/* Designated initialiser. It should not be called directly. Use the public initialiser methods and
 * factory methods instead.
 *
 * The "filters" array is assumed to be immutable. This is the caller's responsibility.
 */
- (instancetype) initWithNamedFilters:(NSArray *)filters
                         fileItemTest:(FileItemTest *)fileItemTest NS_DESIGNATED_INITIALIZER;


/* Creates an updated set of filters. See
 * updatedFilterSetUsingFilterRepository:testRepository:unboundFilters:unboundTests.
 */
- (FilterSet *)updatedFilterSetUnboundFilters:(NSMutableArray *)unboundFilters
                                 unboundTests:(NSMutableArray *)unboundTests;
 
/* Creates an updated set of filters. First, each filter is updated to its current specification in
 * the filter repository. If the filter does not exist anymore, its original definition is used.
 * Subsequently, all filter tests are re-instantiated so that it is based on the tests as they are
 * currently defined in the test repository.
 *
 * If any filter could not be found in the filter repository, its name will be added to
 * "unboundFilters".
 *
 * If any test cannot be found in the test repository its name will be added to "unboundTests".
 */
- (FilterSet *)updatedFilterSetUsingFilterRepository:(FilterRepository *)filterRepository
                                      testRepository:(FilterTestRepository *)testRepository
                                      unboundFilters:(NSMutableArray *)unboundFilters
                                        unboundTests:(NSMutableArray *)unboundTests;
                                
/* Creates a new set with an extra filter. The item test corresponding to the existing filters is
 * not re-instantiated but re-used. This way, the resulting filter set is really an extension of the
 * current one and not affected by any changes to filters and filter tests since the latter was
 * created.
 */
- (FilterSet *)filterSetWithAddedNamedFilter:(NamedFilter *)filter
                                unboundTests:(NSMutableArray *)unboundTests;

@property (nonatomic, readonly) NSUInteger numFilters;

/* Returns an array of NamedFilters.
 */
@property (nonatomic, readonly, copy) NSArray *filters;

/* The item test corresponding to the filter set. It is instantiated when the set is created and
 * immutable. It is not affected by any subsequent changes to filters and filter tests.
 */
@property (nonatomic, readonly, strong) FileItemTest *fileItemTest;

@end // @interface FilterSet
