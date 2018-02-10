#import <Cocoa/Cocoa.h>

#import "ObjectPool.h"


/* Maintains a set of mutable arrays for re-use.
 */
@interface MutableArrayPool : ObjectPool {
  int  initialArrayCapacity;
}

- (instancetype) initWithCapacity:(int) maxSize
             initialArrayCapacity:(int) arraySize NS_DESIGNATED_INITIALIZER;

@end
