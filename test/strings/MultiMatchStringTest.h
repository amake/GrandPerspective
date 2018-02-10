#import <Cocoa/Cocoa.h>

#import "StringTest.h"

/**
 * (Abstract) string test with one or more possible matches.
 */
@interface MultiMatchStringTest : StringTest {

  NSArray  *matches;
  BOOL  caseSensitive;

}

- (instancetype) initWithMatchTargets:(NSArray *)matches;
- (instancetype) initWithMatchTargets:(NSArray *)matches
                        caseSensitive:(BOOL)caseFlag NS_DESIGNATED_INITIALIZER;
- (instancetype) initWithPropertiesFromDictionary:(NSDictionary *)dict NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly, copy) NSArray *matchTargets;
@property (nonatomic, getter=isCaseSensitive, readonly) BOOL caseSensitive;

@end
