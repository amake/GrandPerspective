#import "ItemFlagsTest.h"

#import "FileItem.h"
#import "FileItemTestVisitor.h"


@implementation ItemFlagsTest

// Overrides designated initialiser
- (instancetype) init {
  NSAssert(NO, @"Use initWithFlagsMask:desiredResult: instead.");
  return nil;
}

- (instancetype) initWithFlagsMask:(UInt8)mask desiredResult:(UInt8)result {
  if (self = [super init]) {
    flagsMask = mask;
    desiredResult = result;
  }
  
  return self;

}


/* Note: Special case. Does not call own designated initialiser. It should be overridden and only
 * called by initialisers with the same signature.
 */
- (instancetype) initWithPropertiesFromDictionary:(NSDictionary *)dict {
  if (self = [super initWithPropertiesFromDictionary: dict]) {
    id  object;
    
    object = dict[@"flagsMask"];
    flagsMask = (object == nil) ? 0 : [object unsignedCharValue];
     
    object = dict[@"desiredResult"];
    desiredResult = (object == nil) ? 0 : [object unsignedCharValue];
  }
  
  return self;
}


- (void) addPropertiesToDictionary:(NSMutableDictionary *)dict {
  [super addPropertiesToDictionary: dict];
  
  dict[@"class"] = @"ItemFlagsTest";
  
  dict[@"flagsMask"] = @(flagsMask);
  dict[@"desiredResult"] = @(desiredResult);
}


- (UInt8) flagsMask {
  return flagsMask;
}

- (UInt8) desiredResult {
  return desiredResult;
}


- (TestResult) testFileItem:(FileItem *)item context:(id)context {
  return ([item fileItemFlags] & flagsMask) == desiredResult ? TEST_PASSED : TEST_FAILED;
}

- (BOOL) appliesToDirectories {
  return YES;
}

- (void) acceptFileItemTestVisitor:(NSObject <FileItemTestVisitor> *)visitor {
  [visitor visitItemFlagsTest: self];
}


- (NSString *)description {
  
  // The total description (so far)
  NSString  *s = nil;
  
  // Description of a single flags test.
  NSString  *sub;
  
  NSString  *andFormat = NSLocalizedStringFromTable
    (@"%@ and %@", @"Tests",
     @"AND-test for flags sub tests with 1: subtest, 2: one or more sub tests");
  
  if (flagsMask & FILE_IS_HARDLINKED) {
    if (desiredResult & FILE_IS_HARDLINKED) {
      sub = NSLocalizedStringFromTable(@"item is hard-linked", @"Tests",
                                       @"File/folder flags sub test");
    }
    else {
      sub = NSLocalizedStringFromTable(@"item is not hard-linked", @"Tests",
                                       @"File/folder flags sub test");
    }
    s = sub;
  }
  
  if (flagsMask & FILE_IS_PACKAGE) {
    if (desiredResult & FILE_IS_PACKAGE) {
      sub = NSLocalizedStringFromTable(@"item is a package", @"Tests",
                                       @"File/folder flags sub test");
    }
    else {
      sub = NSLocalizedStringFromTable(@"item is not a package", @"Tests",
                                       @"File/folder flags sub test");
      }

    if ( s == nil ) {
      s = sub;
    } 
    else {
      s = [NSString stringWithFormat: andFormat, s, sub];
    }
  }
  
  return s;
}


+ (FileItemTest *)fileItemTestFromDictionary:(NSDictionary *)dict {
  NSAssert([dict[@"class"] isEqualToString: @"ItemFlagsTest"],
           @"Incorrect value for class in dictionary.");

  return [[[ItemFlagsTest alloc] initWithPropertiesFromDictionary: dict] autorelease];
}

@end
