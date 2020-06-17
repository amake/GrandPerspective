#import "OverlayDrawTaskExecutor.h"

#import "OverlayDrawer.h"
#import "OverlayDrawTaskInput.h"

@implementation OverlayDrawTaskExecutor

- (instancetype) init {
  if (self = [super init]) {
    overlayDrawer = [[OverlayDrawer alloc] init];
  }
  return self;
}

- (void) dealloc {
  [overlayDrawer release];

  [super dealloc];
}

- (void) prepareToRunTask {
  // TODO: clear abort flag
}

- (id) runTaskWithInput:(id)input {
  OverlayDrawTaskInput  *overlayInput = input;

  NSImage  *image = [overlayDrawer drawOverlayImageOfVisibleTree: [overlayInput visibleTree]
                                                  startingAtTree: [overlayInput treeInView]
                                              usingLayoutBuilder: [overlayInput layoutBuilder]
                                                         onTopOf: [overlayInput sourceImage]
                                                     overlayTest: [overlayInput overlayTest]];

  return image;
}

- (void) abortTask {
  // TODO: set abort flag
}

@end
