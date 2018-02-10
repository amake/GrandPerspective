#import <Cocoa/Cocoa.h>


@interface PeekingEnumerator : NSObject {

  NSEnumerator  *enumerator;
  id  nextObject;
  
}

- (instancetype) initWithEnumerator:(NSEnumerator *)enumerator NS_DESIGNATED_INITIALIZER;

- (id) nextObject;

- (id) peekObject;

@end
