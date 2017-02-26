#import <Cocoa/Cocoa.h>
#import "Compatibility.h"

@class DirectoryViewControl;

@interface DirectoryViewToolbarControl : NSObject <NSToolbarDelegate> {

  IBOutlet NSWindow  *dirViewWindow;

  IBOutlet NSSegmentedControl  *zoomControls;
  IBOutlet NSSegmentedControl  *focusControls;
  
  NSUInteger  zoomInSegment;
  NSUInteger  zoomOutSegment;
  NSUInteger  zoomResetSegment;

  NSUInteger  focusUpSegment;
  NSUInteger  focusDownSegment;
  NSUInteger  focusResetSegment;

  DirectoryViewControl  *dirViewControl;

}

@end
