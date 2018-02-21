#import "StringContainmentTest.h"


@implementation StringContainmentTest

- (void) addPropertiesToDictionary:(NSMutableDictionary *)dict {
  [super addPropertiesToDictionary: dict];
  
  dict[@"class"] = @"StringContainmentTest";
}


- (BOOL) testString:(NSString *)string matches:(NSString *)matchTarget {
  return [string rangeOfString: matchTarget
                       options: self.isCaseSensitive ? 0 : NSCaseInsensitiveSearch].location
            != NSNotFound;
}

- (NSString *)descriptionFormat {
  return self.isCaseSensitive
    ? NSLocalizedStringFromTable(@"%@ conTains %@", @"Tests",
                                 @"Case-sensitive string test with 1: subject, and 2: match targets")
    : NSLocalizedStringFromTable(@"%@ contains %@", @"Tests",
                                 @"String test with 1: subject, and 2: match targets");
}


+ (StringTest *)stringTestFromDictionary:(NSDictionary *)dict {
  NSAssert([dict[@"class"] isEqualToString: @"StringContainmentTest"],
           @"Incorrect value for class in dictionary.");

  return [[[StringContainmentTest alloc] initWithPropertiesFromDictionary: dict] autorelease];
}

@end
