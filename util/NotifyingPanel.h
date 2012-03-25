#import <Cocoa/Cocoa.h>
#import "Compatibility.h"

/**
 * Panel which notifies its delegate when its first responder changed.
 */
@interface NotifyingPanel : NSPanel <NSWindowDelegate> {

}

// Method which can be implemented by delegate
- (void) windowFirstResponderChanged: (NSNotification*) notification;

@end
