#import <Cocoa/Cocoa.h>


@class FilterTestWindowControl;
@class FilterTestRepository;
@class FilterTest;


/* Helper class for editing filter tests. Its purpose and functionality is very similar to that of
 * the FilterEditor class.
 */
@interface FilterTestEditor : NSObject {
  FilterTestRepository  *testRepository;
  
  FilterTestWindowControl  *filterTestWindowControl;
}

- (instancetype) init;
- (instancetype) initWithFilterTestRepository:(FilterTestRepository *)testRepository NS_DESIGNATED_INITIALIZER;

/* Edits a new filter test. It returns the new test, or "nil" if the action was cancelled. It
 * updates the repository. The repository's NotifyingDictionary will fire an "objectAdded" event in
 * response.
 */
@property (nonatomic, readonly, strong) FilterTest *newFilterTest;

/* Edits an existing test with the given name. The test should exist in the test repository. It
 * returns the modified test, or "nil" if the action was cancelled. It updates the filter in the
 * repository. Its NotifyingDictionary will fire the appropriate event(s) in response.
 */
- (FilterTest *)editFilterTestNamed:(NSString *)oldName;

@end
