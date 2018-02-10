#import "SelectiveItemTest.h"

#import "FileItemTestVisitor.h"


@implementation SelectiveItemTest

// Overrides designated initialiser
- (instancetype) init {
  NSAssert(NO, @"Use initWithSubItemTest:onlyFiles: instead.");
  return nil;
}

- (instancetype) initWithSubItemTest:(FileItemTest *)subTestVal
                           onlyFiles:(BOOL)onlyFilesVal {
  if (self = [super init]) {
    subTest = [subTestVal retain];
    
    onlyFiles = onlyFilesVal;
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
    onlyFiles = [dict[@"onlyFiles"] boolValue];
  }
  
  return self;
}

- (void) addPropertiesToDictionary:(NSMutableDictionary *)dict {
  [super addPropertiesToDictionary: dict];
  
  dict[@"class"] = @"SelectiveItemTest";
  dict[@"subTest"] = [subTest dictionaryForObject];
  dict[@"onlyFiles"] = @(onlyFiles);
}


- (FileItemTest *)subItemTest {
  return subTest;
}

- (BOOL) applyToFilesOnly {
  return onlyFiles;
}


- (TestResult) testFileItem:(FileItem *)item context:(id) context {
  if (item.directory == onlyFiles) {
    // Test should not be applied to this type of item.
    return TEST_NOT_APPLICABLE;
  }
  
  return [subTest testFileItem: item context: context] ? TEST_PASSED : TEST_FAILED;
}

- (BOOL) appliesToDirectories {
  return !onlyFiles;
}


- (void) acceptFileItemTestVisitor:(NSObject <FileItemTestVisitor> *)visitor {
  [visitor visitSelectiveItemTest: self];
}


- (NSString *)description {
  NSString  *format = (onlyFiles
                       ? NSLocalizedStringFromTable(@"files: %@", @"Tests",
                                                    @"Selective test with 1: sub test")
                       : NSLocalizedStringFromTable(@"folders: %@", @"Tests",
                                                    @"Selective test with 1: sub test"));
  
  return [NSString stringWithFormat: format, subTest.description];
}


+ (FileItemTest *)fileItemTestFromDictionary:(NSDictionary *)dict { 
  NSAssert([dict[@"class"] isEqualToString: @"SelectiveItemTest"],
           @"Incorrect value for class in dictionary.");

  return [[[SelectiveItemTest alloc] initWithPropertiesFromDictionary: dict] autorelease];
}

@end

