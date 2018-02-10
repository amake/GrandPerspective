#import "NotItemTest.h"

#import "FileItemTestVisitor.h"


@implementation NotItemTest

// Overrides designated initialiser
- (instancetype) init {
  NSAssert(NO, @"Use initWithSubItemTest: instead.");
  return nil;
}

- (instancetype) initWithSubItemTest:(FileItemTest *)subTestVal {
  if (self = [super init]) {
    subTest = [subTestVal retain];
  }

  return self;
}

- (void) dealloc {
  [subTest release];
  
  [super dealloc];
}


/* Note: Special case. Does not call own designated initialiser. It should be overridden and only
 * called by initialisers with the same signature.
 */
- (instancetype) initWithPropertiesFromDictionary:(NSDictionary *)dict {
  if (self = [super initWithPropertiesFromDictionary: dict]) {
    NSDictionary  *subTestDict = dict[@"subTest"];
    
    subTest = [[FileItemTest fileItemTestFromDictionary: subTestDict] retain];
  }
  
  return self;
}

- (void) addPropertiesToDictionary:(NSMutableDictionary *)dict {
  [super addPropertiesToDictionary: dict];
  
  dict[@"class"] = @"NotItemTest";

  dict[@"subTest"] = [subTest dictionaryForObject];
}


- (FileItemTest *)subItemTest {
  return subTest;
}


- (TestResult) testFileItem:(FileItem *)item context:(id) context {
  TestResult  result = [subTest testFileItem: item context: context];
  
  return (result == TEST_NOT_APPLICABLE
          ? TEST_NOT_APPLICABLE
          : (result == TEST_FAILED ? TEST_PASSED : TEST_FAILED));
}

- (BOOL) appliesToDirectories {
  return [subTest appliesToDirectories];
}

- (void) acceptFileItemTestVisitor:(NSObject <FileItemTestVisitor> *)visitor {
  [visitor visitNotItemTest: self];
}


- (NSString *)description {
  NSString  *fmt = NSLocalizedStringFromTable(@"not (%@)" , @"Tests", @"NOT-test with 1: sub test");

  return [NSString stringWithFormat: fmt, subTest.description];
}


+ (FileItemTest *)fileItemTestFromDictionary:(NSDictionary *)dict {
  NSAssert([dict[@"class"] isEqualToString: @"NotItemTest"],
           @"Incorrect value for class in dictionary.");

  return [[[NotItemTest alloc] initWithPropertiesFromDictionary: dict] autorelease];
}

@end
