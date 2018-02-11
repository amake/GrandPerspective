#import "NotItemTest.h"

#import "FileItemTestVisitor.h"


@implementation NotItemTest

// Overrides designated initialiser
- (instancetype) init {
  NSAssert(NO, @"Use initWithSubItemTest: instead.");
  return [self initWithSubItemTest: nil];
}

- (instancetype) initWithSubItemTest:(FileItemTest *)subItemTest {
  if (self = [super init]) {
    _subItemTest = [subItemTest retain];
  }

  return self;
}

- (instancetype) initWithPropertiesFromDictionary:(NSDictionary *)dict {
  if (self = [super initWithPropertiesFromDictionary: dict]) {
    NSDictionary  *subTestDict = dict[@"subTest"];
    
    _subItemTest = [[FileItemTest fileItemTestFromDictionary: subTestDict] retain];
  }
  
  return self;
}

- (void) dealloc {
  [_subItemTest release];

  [super dealloc];
}


- (void) addPropertiesToDictionary:(NSMutableDictionary *)dict {
  [super addPropertiesToDictionary: dict];
  
  dict[@"class"] = @"NotItemTest";

  dict[@"subTest"] = [self.subItemTest dictionaryForObject];
}


- (TestResult) testFileItem:(FileItem *)item context:(id) context {
  TestResult  result = [self.subItemTest testFileItem: item context: context];
  
  return (result == TEST_NOT_APPLICABLE
          ? TEST_NOT_APPLICABLE
          : (result == TEST_FAILED ? TEST_PASSED : TEST_FAILED));
}

- (BOOL) appliesToDirectories {
  return [self.subItemTest appliesToDirectories];
}

- (void) acceptFileItemTestVisitor:(NSObject <FileItemTestVisitor> *)visitor {
  [visitor visitNotItemTest: self];
}


- (NSString *)description {
  NSString  *fmt = NSLocalizedStringFromTable(@"not (%@)" , @"Tests", @"NOT-test with 1: sub test");

  return [NSString stringWithFormat: fmt, self.subItemTest.description];
}


+ (FileItemTest *)fileItemTestFromDictionary:(NSDictionary *)dict {
  NSAssert([dict[@"class"] isEqualToString: @"NotItemTest"],
           @"Incorrect value for class in dictionary.");

  return [[[NotItemTest alloc] initWithPropertiesFromDictionary: dict] autorelease];
}

@end
