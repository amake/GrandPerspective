#import <Cocoa/Cocoa.h>

#import "FileItemTest.h"


@interface NotItemTest : FileItemTest {
  FileItemTest  *subTest;
}

- (instancetype) initWithSubItemTest:(FileItemTest *)subTest NS_DESIGNATED_INITIALIZER;
- (instancetype) initWithPropertiesFromDictionary:(NSDictionary *)dict NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly, strong) FileItemTest *subItemTest;

+ (FileItemTest *)fileItemTestFromDictionary:(NSDictionary *)dict;

@end
