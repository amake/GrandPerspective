#import "CompoundItemTest.h"

#import "LocalizableStrings.h"


@interface CompoundItemTest (PrivateMethods) 

/* Not implemented. Needs to be provided by subclass.
 *
 * It should return a template for describing a test consisting of two sub-tests. The string should
 * have two "%@" arguments. The first for the description of the first sub-test, and the second for
 * the second sub-test.
 */
@property (nonatomic, readonly, copy) NSString *bootstrapDescriptionTemplate;

/* Not implemented. Needs to be provided by subclass.
 *
 * It should return a template for describing a test consisting of three or more sub-tests. The
 * string should have two "%@" arguments. The first for the description of the first sub-test, and
 * the second for the description of the remaining sub-tests. The template will be applied
 * iteratively.
 */
@property (nonatomic, readonly, copy) NSString *repeatingDescriptionTemplate;

@end // CompoundItemTest (PrivateMethods) 


@implementation CompoundItemTest

// Overrides designated initialiser
- (instancetype) init {
  NSAssert(NO, @"Use initWithSubItemTests: instead.");
  return [self initWithSubItemTests: nil];
}

- (instancetype) initWithSubItemTests:(NSArray*)subTestsVal {
  if (self = [super init]) {
    NSAssert([subTestsVal count] >= 2, @"Compound test should have two or more sub-tests");
  
    // Make the array immutable
    subTests = [[NSArray alloc] initWithArray:subTestsVal];
  }
  
  return self;
}

- (instancetype) initWithPropertiesFromDictionary:(NSDictionary *)dict {
  if (self = [super initWithPropertiesFromDictionary: dict]) {
    NSArray  *subTestDicts = dict[@"subTests"];
    
    NSMutableArray  *tmpSubTests = [NSMutableArray arrayWithCapacity: subTestDicts.count];
    NSEnumerator  *subTestsDictsEnum = [subTestDicts objectEnumerator];
    NSDictionary  *subTestDict;
    while ((subTestDict = [subTestsDictsEnum nextObject]) != nil) {
      [tmpSubTests addObject: [FileItemTest fileItemTestFromDictionary: subTestDict]];
    }
    
    // Make the array immutable
    subTests = [[NSArray alloc] initWithArray: tmpSubTests];
  }
  
  return self;
}

- (void) dealloc {
  [subTests release];

  [super dealloc];
}


- (void) addPropertiesToDictionary:(NSMutableDictionary *)dict {
  [super addPropertiesToDictionary: dict];
  
  NSMutableArray  *subTestsDicts = [NSMutableArray arrayWithCapacity: subTests.count];
  NSEnumerator  *subTestsEnum = [subTests objectEnumerator];
  FileItemTest  *subTest;

  while ((subTest = [subTestsEnum nextObject]) != nil) {
    [subTestsDicts addObject: [subTest dictionaryForObject]];
  }

  dict[@"subTests"] = subTestsDicts;
}


- (NSArray *)subItemTests {
  return subTests;
}

- (BOOL) testFileItem:(FileItem *)item {
  NSAssert(NO, @"This method must be overridden.");
  return NO;
}

- (BOOL) appliesToDirectories {
  NSUInteger  max = subTests.count;
  NSUInteger  i = 0;
  
  while (i < max) {
    if ([subTests[i++] appliesToDirectories]) {
      return YES;
    }
  }
  return NO;
}


- (NSString *)description {
  return [LocalizableStrings localizedEnumerationString: subTests
                                           pairTemplate: [self bootstrapDescriptionTemplate]
                                      bootstrapTemplate: [self bootstrapDescriptionTemplate]
                                      repeatingTemplate: [self repeatingDescriptionTemplate]];
}

@end
