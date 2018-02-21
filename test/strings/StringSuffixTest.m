#import "StringSuffixTest.h"


@implementation StringSuffixTest

- (void) addPropertiesToDictionary:(NSMutableDictionary *)dict {
  [super addPropertiesToDictionary: dict];
  
  dict[@"class"] = @"StringSuffixTest";
}


- (BOOL) testString:(NSString *)string matches:(NSString *)matchTarget {
  NSUInteger  stringLen = string.length;
  NSUInteger  matchTargetLen = matchTarget.length;
  
  if (stringLen < matchTargetLen) {
    return NO;
  }
  else {
    return [string compare: matchTarget
                   options: (self.isCaseSensitive ? 0 : NSCaseInsensitiveSearch)
                     range: NSMakeRange(stringLen - matchTargetLen, matchTargetLen)
            ] == NSOrderedSame;
  }
}

- (NSString *)descriptionFormat {
  return self.isCaseSensitive
    ? NSLocalizedStringFromTable(@"%@ enDs with %@", @"Tests",
                                 @"Case-sensitive string test with 1: subject, and 2: match targets")
    : NSLocalizedStringFromTable(@"%@ ends with %@", @"Tests",
                                 @"String test with 1: subject, and 2: match targets");
}


+ (StringTest *)stringTestFromDictionary:(NSDictionary *)dict {
  NSAssert([dict[@"class"] isEqualToString: @"StringSuffixTest"],
           @"Incorrect value for class in dictionary.");

  return [[[StringSuffixTest alloc] initWithPropertiesFromDictionary: dict] autorelease];
}

@end
