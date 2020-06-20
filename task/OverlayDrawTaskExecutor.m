#import "OverlayDrawTaskExecutor.h"

#import "OverlayDrawer.h"
#import "OverlayDrawTaskInput.h"

@implementation OverlayDrawTaskExecutor

// Overrides designated initialiser
- (instancetype) init {
  NSAssert(NO, @"Use initWithScanTree: instead");

  #pragma clang diagnostic push
  #pragma clang diagnostic ignored "-Wnonnull"
  return [self initWithScanTree: nil];
  #pragma clang diagnostic pop
}

- (instancetype) initWithScanTree:(DirectoryItem *)scanTree {
  if (self = [super init]) {
    overlayDrawer = [[OverlayDrawer alloc] initWithScanTree: scanTree];
  }
  return self;
}

- (void) dealloc {
  [overlayDrawer release];

  [super dealloc];
}

- (void) prepareToRunTask {
  [overlayDrawer clearAbortFlag];
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
