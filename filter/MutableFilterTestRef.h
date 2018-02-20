#import <Cocoa/Cocoa.h>

#import "FilterTestRef.h"

/* A FilterTestRef whose inverted state can be changed. Toggling of the state can, however, be
 * disabled when it is not appropriate (given the filter test it represents).
 */
@interface MutableFilterTestRef : FilterTestRef {
  // Using own toggle instead of manipulating private property of parent class
  BOOL  invertedToggle;
}

/* Can the inverted state be changed?
 */
@property (nonatomic) BOOL canToggleInverted;

- (void) toggleInverted;

@end // @interface MutableFilterTestRef
