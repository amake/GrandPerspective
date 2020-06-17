#import "OverlayDrawTaskInput.h"

#import "FileItemTest.h"

@implementation OverlayDrawTaskInput

// Override designated initializer of super.
- (instancetype) initWithVisibleTree:(FileItem *)visibleTree
                          treeInView:(FileItem *)treeInView
                       layoutBuilder:(TreeLayoutBuilder *)layoutBuilder
                              bounds:(NSRect) bounds {
  NSAssert(NO, @"Use initWithVisibleTree:..:sourceImage:overlayTest instead.");
//  return [self initWithVisibleTree: visibleTree
//                        treeInView: treeInView
//                     layoutBuilder: layoutBuilder
//                       sourceImage: [[[NSImage alloc] initWithSize: NSMakeSize(0, 0)] autorelease]
//                       overlayTest: nil];
  return nil;
}

- (instancetype) initWithVisibleTree:(FileItem *)visibleTree
                          treeInView:(FileItem *)treeInView
                       layoutBuilder:(TreeLayoutBuilder *)layoutBuilder
                         sourceImage:(NSImage *)sourceImage
                         overlayTest:(FileItemTest *)overlayTest {
  NSRect bounds = NSMakeRect(0, 0, sourceImage.size.width, sourceImage.size.height);

  if (self = [super initWithVisibleTree: visibleTree
                             treeInView: treeInView
                          layoutBuilder: layoutBuilder
                                 bounds: bounds]) {
    _sourceImage = sourceImage;
    _overlayTest = overlayTest;
  }

  return self;
}

@end
