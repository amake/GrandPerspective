#import "SelectiveItemTest.h"

#import "FileItemTestVisitor.h"
#import "FileItem.h"


@implementation SelectiveItemTest

// Overrides designated initialiser
- (instancetype) init {
  NSAssert(NO, @"Use initWithSubItemTest:onlyFiles: instead.");
  return [self initWithSubItemTest: nil onlyFiles: YES];
}

- (instancetype) initWithSubItemTest:(FileItemTest *)subItemTest
                           onlyFiles:(BOOL)onlyFiles {
  if (self = [super init]) {
    _subItemTest = [subItemTest retain];

    _applyToFilesOnly = onlyFiles;
  }
  
  return self;
}

- (instancetype) initWithPropertiesFromDictionary:(NSDictionary *)dict {
  if (self = [super initWithPropertiesFromDictionary: dict]) {
    NSDictionary  *subTestDict = dict[@"subTest"];
    
    _subItemTest = [[FileItemTest fileItemTestFromDictionary: subTestDict] retain];
    _applyToFilesOnly = [dict[@"onlyFiles"] boolValue];
  }
  
  return self;
}

- (void) dealloc {
  [_subItemTest release];

  [super dealloc];
}


- (void) addPropertiesToDictionary:(NSMutableDictionary *)dict {
  [super addPropertiesToDictionary: dict];
  
  dict[@"class"] = @"SelectiveItemTest";
  dict[@"subTest"] = [self.subItemTest dictionaryForObject];
  dict[@"onlyFiles"] = @(self.applyToFilesOnly);
}


- (TestResult) testFileItem:(FileItem *)item context:(id) context {
  if (item.isDirectory == self.applyToFilesOnly) {
    // Test should not be applied to this type of item.
    return TEST_NOT_APPLICABLE;
  }
  
  return [self.subItemTest testFileItem: item context: context] ? TEST_PASSED : TEST_FAILED;
}

- (BOOL) appliesToDirectories {
  return !self.applyToFilesOnly;
}


- (void) acceptFileItemTestVisitor:(NSObject <FileItemTestVisitor> *)visitor {
  [visitor visitSelectiveItemTest: self];
}


- (NSString *)description {
  NSString  *format = (self.applyToFilesOnly
                       ? NSLocalizedStringFromTable(@"files: %@", @"Tests",
                                                    @"Selective test with 1: sub test")
                       : NSLocalizedStringFromTable(@"folders: %@", @"Tests",
                                                    @"Selective test with 1: sub test"));
  
  return [NSString stringWithFormat: format, self.subItemTest.description];
}


+ (FileItemTest *)fileItemTestFromDictionary:(NSDictionary *)dict { 
  NSAssert([dict[@"class"] isEqualToString: @"SelectiveItemTest"],
           @"Incorrect value for class in dictionary.");

  return [[[SelectiveItemTest alloc] initWithPropertiesFromDictionary: dict] autorelease];
}

@end

