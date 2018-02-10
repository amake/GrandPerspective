#import <Cocoa/Cocoa.h>


@class Item;

@interface TreeBalancer : NSObject {

  BOOL  excludeZeroSizedItems;

@private
  NSMutableArray  *tmpArray;
}

@property (nonatomic) BOOL excludeZeroSizedItems;

// Note: assumes that array may be modified for sorting!
- (Item *)createTreeForItems:(NSMutableArray *)items;

@end
