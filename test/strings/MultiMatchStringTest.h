#import <Cocoa/Cocoa.h>

#import "StringTest.h"

/**
 * (Abstract) string test with one or more possible matches.
 */
@interface MultiMatchStringTest : StringTest {
}

- (instancetype) initWithMatchTargets:(NSArray *)matchTargets;
- (instancetype) initWithMatchTargets:(NSArray *)matchTargets
                        caseSensitive:(BOOL)caseSensitive NS_DESIGNATED_INITIALIZER;
- (instancetype) initWithPropertiesFromDictionary:(NSDictionary *)dict NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly, copy) NSArray *matchTargets;
@property (nonatomic, getter=isCaseSensitive, readonly) BOOL caseSensitive;

@end
