#import "StringTest.h"

#import "StringPrefixTest.h"
#import "StringSuffixTest.h"
#import "StringEqualityTest.h"
#import "StringContainmentTest.h"


@implementation StringTest

+ (StringTest *)stringTestFromDictionary:(NSDictionary *)dict {
  NSString  *classString = dict[@"class"];
  
  if ([classString isEqualToString: @"StringContainmentTest"]) {
    return [StringContainmentTest stringTestFromDictionary: dict];
  }
  else if ([classString isEqualToString: @"StringSuffixTest"]) {
    return [StringSuffixTest stringTestFromDictionary: dict];
  }
  else if ([classString isEqualToString: @"StringPrefixTest"]) {
    return [StringPrefixTest stringTestFromDictionary: dict];
  }
  else if ([classString isEqualToString: @"StringEqualityTest"]) {
    return [StringEqualityTest stringTestFromDictionary: dict];
  }

  NSAssert1(NO, @"Unrecognized string test class \"%@\".", classString);
  return nil;
}

- (instancetype) init {
  return [super init];
}
- (instancetype) initWithPropertiesFromDictionary:(NSDictionary *)dict {
  return [super init];
}

@end


@implementation StringTest (ProtectedMethods)

- (void) addPropertiesToDictionary:(NSMutableDictionary *)dict {
  // void
}

@end
