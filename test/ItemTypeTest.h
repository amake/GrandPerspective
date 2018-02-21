#import <Cocoa/Cocoa.h>

#import "FileItemTest.h"


@interface ItemTypeTest : FileItemTest {
}

- (instancetype) initWithMatchTargets:(NSArray *)matchTargets;

- (instancetype) initWithMatchTargets:(NSArray *)matchTargets
                               strict:(BOOL)strict NS_DESIGNATED_INITIALIZER;
- (instancetype) initWithPropertiesFromDictionary:(NSDictionary *)dict NS_DESIGNATED_INITIALIZER;

// Array of UniformTypes
@property (nonatomic, readonly, copy) NSArray *matchTargets;

// Controls if the matching is strict, or if conformance is tested.
@property (nonatomic, getter=isStrict, readonly) BOOL strict;

+ (FileItemTest *)fileItemTestFromDictionary:(NSDictionary *)dict;

@end
