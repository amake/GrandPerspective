#import <Cocoa/Cocoa.h>

#import "FileItemTest.h"
#import "Item.h"

/**
 * Item size test.
 */
@interface ItemSizeTest : FileItemTest  {

  ITEM_SIZE  lowerBound;
  ITEM_SIZE  upperBound;

}

- (instancetype) initWithLowerBound:(ITEM_SIZE)lowerBound;

- (instancetype) initWithUpperBound:(ITEM_SIZE)upperBound;

- (instancetype) initWithLowerBound:(ITEM_SIZE)lowerBound
                         upperBound:(ITEM_SIZE)upperBound NS_DESIGNATED_INITIALIZER;
- (instancetype) initWithPropertiesFromDictionary:(NSDictionary *)dict NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly) BOOL hasLowerBound;
@property (nonatomic, readonly) BOOL hasUpperBound;

@property (nonatomic, readonly) unsigned long long lowerBound;
@property (nonatomic, readonly) unsigned long long upperBound;

+ (FileItemTest *)fileItemTestFromDictionary:(NSDictionary *)dict;

@end
