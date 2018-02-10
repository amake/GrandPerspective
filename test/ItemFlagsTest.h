#import <Cocoa/Cocoa.h>

#import "FileItemTest.h"


@interface ItemFlagsTest : FileItemTest {

  UInt8  flagsMask;
  UInt8  desiredResult;

}

- (instancetype) initWithFlagsMask:(UInt8)mask desiredResult:(UInt8)result NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly) UInt8 flagsMask;
@property (nonatomic, readonly) UInt8 desiredResult;

+ (FileItemTest *)fileItemTestFromDictionary:(NSDictionary *)dict;

@end
