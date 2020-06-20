#import "OverlayDrawer.h"

#import "FileItem.h"
#import "FilteredTreeGuide.h"
#import "GradientRectangleDrawer.h"
#import "TreeLayoutBuilder.h"

@implementation OverlayDrawer

- (instancetype) initWithScanTree:(DirectoryItem *)scanTreeVal
                     colorPalette:(NSColorList *)colorPalette {
  if (self = [super initWithScanTree: scanTreeVal colorPalette: colorPalette]) {
    overlayColor = [rectangleDrawer intValueForColor: NSColor.lightGrayColor];
  }
  return self;
}

- (NSImage *)drawOverlayImageOfVisibleTree:(FileItem *)visibleTree
                            startingAtTree:(FileItem *)treeRoot
                        usingLayoutBuilder:(TreeLayoutBuilder *)layoutBuilder
                                    inRect:(NSRect) bounds
                               overlayTest:(FileItemTest *)overlayTest; {
  [treeGuide setFileItemTest: overlayTest];

  return [super drawImageOfVisibleTree: visibleTree
                        startingAtTree: treeRoot
                    usingLayoutBuilder: layoutBuilder
                                inRect: bounds];
}

- (void)drawFile:(PlainFileItem *)fileItem atRect:(NSRect) rect depth:(int) depth {
  // Plain file that passed the test. Highlight it
  [rectangleDrawer drawBasicFilledRect: rect intColor: overlayColor];
}

@end
