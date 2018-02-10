#import <Cocoa/Cocoa.h>

#import "FileItemTest.h"


@interface ItemTypeTest : FileItemTest {

  // Array of UniformTypes
  NSArray  *matches;
  
  // Conrols if the matching is strict, or if conformance is tested.
  BOOL  strict;

}

- (instancetype) initWithMatchTargets:(NSArray *)matches;

- (instancetype) initWithMatchTargets:(NSArray *)matches
                               strict:(BOOL)strict NS_DESIGNATED_INITIALIZER;


@property (nonatomic, readonly, copy) NSArray *matchTargets;
@property (nonatomic, getter=isStrict, readonly) BOOL strict;

+ (FileItemTest *)fileItemTestFromDictionary:(NSDictionary *)dict;

@end
