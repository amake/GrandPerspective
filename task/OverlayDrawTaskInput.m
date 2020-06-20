#import "OverlayDrawTaskInput.h"

#import "FileItemTest.h"

@implementation OverlayDrawTaskInput

// Override designated initializer of super.
- (instancetype) initWithVisibleTree:(FileItem *)visibleTree
                          treeInView:(FileItem *)treeInView
                       layoutBuilder:(TreeLayoutBuilder *)layoutBuilder
                              bounds:(NSRect) bounds {
  NSAssert(NO, @"Use initWithVisibleTree:..:overlayTest instead.");

  #pragma clang diagnostic push
  #pragma clang diagnostic ignored "-Wnonnull"
  return [self initWithVisibleTree: visibleTree
                        treeInView: treeInView
                     layoutBuilder: layoutBuilder
                            bounds: bounds
                       overlayTest: nil];
  #pragma clang diagnostic pop
}

- (instancetype) initWithVisibleTree:(FileItem *)visibleTree
                          treeInView:(FileItem *)treeInView
                       layoutBuilder:(TreeLayoutBuilder *)layoutBuilder
                              bounds:(NSRect) bounds
                         overlayTest:(FileItemTest *)overlayTest {

  if (self = [super initWithVisibleTree: visibleTree
                             treeInView: treeInView
                          layoutBuilder: layoutBuilder
                                 bounds: bounds]) {
    _overlayTest = overlayTest;
  }

  return self;
}

@end
