#import "MultiMatchStringTest.h"

#import "TestDescriptions.h"


@interface MultiMatchStringTest (PrivateMethods) 

/* Not implemented. Needs to be provided by subclass.
 */
- (BOOL) testString:(NSString *)string matches:(NSString *)match;

/* Not implemented. Needs to be provided by subclass.
 *
 * It should return a string with two "%@" arguments. The first for the subject of the test and the
 * second for the description of the match targets.
 *
 * Furthermore, the descriptionFormat should somehow indicate whether or not the matching is
 * case-sensitive.
 */
@property (nonatomic, readonly, copy) NSString *descriptionFormat;

@end


@implementation MultiMatchStringTest

// Overrides designated initialiser
- (instancetype) init {
  NSAssert(NO, @"Use initWithMatchTargets: instead.");
  return [self initWithMatchTargets: nil];
}

- (instancetype) initWithMatchTargets:(NSArray *)matchesVal {
  return [self initWithMatchTargets: matchesVal caseSensitive: YES];
}
  
- (instancetype) initWithMatchTargets:(NSArray *)matchesVal caseSensitive:(BOOL)caseFlag {
  if (self = [super init]) {
    NSAssert([matchesVal count] >= 1, @"There must at least be one possible match.");

    // Make the array immutable
    matches = [[NSArray alloc] initWithArray: matchesVal];
    caseSensitive = caseFlag;
  }
  
  return self;
}

- (instancetype) initWithPropertiesFromDictionary:(NSDictionary *)dict {
  if (self = [super initWithPropertiesFromDictionary: dict]) {
    NSArray  *tmpMatches = dict[@"matches"];

    // Make the array immutable
    matches = [[NSArray alloc] initWithArray: tmpMatches];

    caseSensitive = [dict[@"caseSensitive"] boolValue];
  }

  return self;
}

- (void) dealloc {
  [matches release];

  [super dealloc];
}


- (void) addPropertiesToDictionary:(NSMutableDictionary *)dict {
  [super addPropertiesToDictionary: dict];
  
  dict[@"matches"] = matches;
  
  dict[@"caseSensitive"] = @(caseSensitive);
}


- (NSDictionary *)dictionaryForObject {
  NSMutableDictionary  *dict = [NSMutableDictionary dictionaryWithCapacity: 8];
  
  [self addPropertiesToDictionary: dict];
  
  return dict;
}


- (NSArray *)matchTargets {
  return matches;
}

- (BOOL) isCaseSensitive {
  return caseSensitive;
}


- (BOOL) testString:(NSString *)string {
  NSUInteger  i = matches.count;
  while (i-- > 0) {
    if ([self testString: string matches: matches[i]]) {
      return YES;
    }
  }
  
  return NO;
}


- (NSString *)descriptionWithSubject:(NSString *)subject {
  // Note: Whether or not the matching is case-sensitive is not indicated here.
  // This is the responsibility of the descriptionFormat method. 

  NSString  *matchesDescr = descriptionForMatches( matches );
  NSString  *format = [self descriptionFormat];
  
  return [NSString stringWithFormat: format, subject, matchesDescr];
}

@end // @implementation MultiMatchStringTest

