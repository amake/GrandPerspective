#import "ItemStringTest.h"

#import "StringTest.h"


@implementation ItemStringTest

// Overrides designated initialiser
- (instancetype) init {
  NSAssert(NO, @"Use initWithStringTest: instead.");
  return nil;
}

- (instancetype) initWithStringTest:(StringTest *)stringTestVal {
  if (self = [super init]) {
    stringTest = [stringTestVal retain];
  }
  return self;
}

- (void) dealloc {
  [stringTest release];
  
  [super dealloc];
}


/* Note: Special case. Does not call own designated initialiser. It should be overridden and only
 * called by initialisers with the same signature.
 */
- (instancetype) initWithPropertiesFromDictionary:(NSDictionary *)dict {
  if (self = [super initWithPropertiesFromDictionary: dict]) {
    NSDictionary  *stringTestDict = dict[@"stringTest"];
    
    stringTest = [[StringTest stringTestFromDictionary: stringTestDict] retain];
  }
  
  return self;
}

- (void) addPropertiesToDictionary:(NSMutableDictionary *)dict {
  [super addPropertiesToDictionary: dict];
  
  dict[@"stringTest"] = [stringTest dictionaryForObject];
}


- (StringTest *)stringTest {
  return stringTest;
}

- (BOOL) testFileItem:(FileItem *)item {
  NSAssert(NO, @"This method must be overridden.");
  return NO;
}

@end
