#import <Cocoa/Cocoa.h>
#import "Compatibility.h"

@class DirectoryViewControl;

@interface DirectoryViewToolbarControl : NSObject <NSToolbarDelegate> {

  IBOutlet NSWindow  *dirViewWindow;

  IBOutlet NSSegmentedControl  *zoomControls;
  IBOutlet NSSegmentedControl  *focusControls;
  
  int  zoomInSegment;
  int  zoomOutSegment;
  int  focusUpSegment;
  int  focusDownSegment;

  DirectoryViewControl  *dirViewControl;

}

@end
