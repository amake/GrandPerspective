#import "StringPrefixTest.h"


@implementation StringPrefixTest

- (void) addPropertiesToDictionary:(NSMutableDictionary *)dict {
  [super addPropertiesToDictionary: dict];
  
  dict[@"class"] = @"StringPrefixTest";
}


- (BOOL) testString:(NSString *)string matches:(NSString *)matchTarget {
  NSUInteger  stringLen = string.length;
  NSUInteger  matchTargetLen = matchTarget.length;
  
  if (stringLen < matchTargetLen) {
    return NO;
  }
  else {
    return [string compare: matchTarget
                   options: self.isCaseSensitive ? 0 : NSCaseInsensitiveSearch
                     range: NSMakeRange( 0, matchTargetLen)
            ] == NSOrderedSame;
  }
}

- (NSString *)descriptionFormat {
  return self.isCaseSensitive
    ? NSLocalizedStringFromTable(@"%@ starTs with %@", @"Tests",
                                 @"Case-sensitive string test with 1: subject, and 2: match targets")
    : NSLocalizedStringFromTable(@"%@ starts with %@", @"Tests",
                                 @"String test with 1: subject, and 2: match targets");
}


+ (StringTest *)stringTestFromDictionary:(NSDictionary *)dict {
  NSAssert([dict[@"class"] isEqualToString: @"StringPrefixTest"],
           @"Incorrect value for class in dictionary.");

  return [[[StringPrefixTest alloc] initWithPropertiesFromDictionary: dict] autorelease];
}

@end
