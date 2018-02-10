#import "StringEqualityTest.h"


@implementation StringEqualityTest

- (void) addPropertiesToDictionary:(NSMutableDictionary *)dict {
  [super addPropertiesToDictionary: dict];
  
  dict[@"class"] = @"StringEqualityTest";
}


- (BOOL) testString:(NSString *)string matches:(NSString *)match {
  if (caseSensitive) {
    return [string isEqualToString: match];
  }
  else {
    return [string caseInsensitiveCompare: match] == NSOrderedSame;
  }
}

- (NSString *)descriptionFormat {
  return caseSensitive
    ? NSLocalizedStringFromTable(@"%@ eQuals %@", @"Tests",
                                 @"Case-sensitive string test with 1: subject, and 2: match targets")
    : NSLocalizedStringFromTable(@"%@ equals %@", @"Tests",
                                 @"String test with 1: subject, and 2: match targets");
}


+ (StringTest *)stringTestFromDictionary:(NSDictionary *)dict {
  NSAssert([dict[@"class"] isEqualToString: @"StringEqualityTest"],
           @"Incorrect value for class in dictionary.");

  return [[[StringEqualityTest alloc] initWithPropertiesFromDictionary: dict] autorelease];
}

@end
