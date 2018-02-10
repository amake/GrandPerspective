#import <Cocoa/Cocoa.h>

#import "FileItemTest.h"

@class StringTest;

/**
 * (Abstract) item string-based test.
 */
@interface ItemStringTest : FileItemTest  {

  StringTest  *stringTest;

}

- (instancetype) initWithStringTest:(StringTest *)stringTest NS_DESIGNATED_INITIALIZER;
- (instancetype) initWithPropertiesFromDictionary:(NSDictionary *)dict NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly, strong) StringTest *stringTest;

@end
