#import <Cocoa/Cocoa.h>

#import "FileItem.h"
#import "FileItemTest.h"


@interface ItemFlagsTest : FileItemTest {
}

- (instancetype) initWithFlagsMask:(FileItemOptions)mask
                     desiredResult:(FileItemOptions)result NS_DESIGNATED_INITIALIZER;
- (instancetype) initWithPropertiesFromDictionary:(NSDictionary *)dict NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly) UInt8 flagsMask;
@property (nonatomic, readonly) UInt8 desiredResult;

+ (FileItemTest *)fileItemTestFromDictionary:(NSDictionary *)dict;

@end
