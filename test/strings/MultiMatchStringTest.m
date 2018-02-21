#import "MultiMatchStringTest.h"

#import "TestDescriptions.h"


@interface MultiMatchStringTest (PrivateMethods) 

/* Not implemented. Needs to be provided by subclass.
 */
- (BOOL) testString:(NSString *)string matches:(NSString *)matchTarget;

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

- (instancetype) initWithMatchTargets:(NSArray *)matchTargets {
  return [self initWithMatchTargets: matchTargets caseSensitive: YES];
}
  
- (instancetype) initWithMatchTargets:(NSArray *)matchTargets caseSensitive:(BOOL)caseSensitive {
  if (self = [super init]) {
    NSAssert([matchTargets count] >= 1, @"There must at least be one possible match.");

    // Make the array immutable
    _matchTargets = [[NSArray alloc] initWithArray: matchTargets];
    _caseSensitive = caseSensitive;
  }
  
  return self;
}

- (instancetype) initWithPropertiesFromDictionary:(NSDictionary *)dict {
  if (self = [super initWithPropertiesFromDictionary: dict]) {
    NSArray  *tmpMatches = dict[@"matches"];

    // Make the array immutable
    _matchTargets = [[NSArray alloc] initWithArray: tmpMatches];

    _caseSensitive = [dict[@"caseSensitive"] boolValue];
  }

  return self;
}

- (void) dealloc {
  [_matchTargets release];

  [super dealloc];
}


- (void) addPropertiesToDictionary:(NSMutableDictionary *)dict {
  [super addPropertiesToDictionary: dict];
  
  dict[@"matches"] = self.matchTargets;
  
  dict[@"caseSensitive"] = @(self.isCaseSensitive);
}


- (NSDictionary *)dictionaryForObject {
  NSMutableDictionary  *dict = [NSMutableDictionary dictionaryWithCapacity: 8];
  
  [self addPropertiesToDictionary: dict];
  
  return dict;
}


- (BOOL) testString:(NSString *)string {
  NSUInteger  i = self.matchTargets.count;
  while (i-- > 0) {
    if ([self testString: string matches: self.matchTargets[i]]) {
      return YES;
    }
  }
  
  return NO;
}


- (NSString *)descriptionWithSubject:(NSString *)subject {
  // Note: Whether or not the matching is case-sensitive is not indicated here.
  // This is the responsibility of the descriptionFormat method. 

  NSString  *matchTargetsDescr = descriptionForMatchTargets(self.matchTargets);

  return [NSString stringWithFormat: self.descriptionFormat, subject, matchTargetsDescr];
}

@end // @implementation MultiMatchStringTest

