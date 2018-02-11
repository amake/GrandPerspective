#import "DrawTaskInput.h"

#import "FileItem.h"
#import "TreeLayoutBuilder.h"


@implementation DrawTaskInput

// Overrides designated initialiser
- (instancetype) init {
  NSAssert(NO, @"Use initWithVisibleTree:treeInView:layoutBuilder... instead");
  return [self initWithVisibleTree: nil treeInView: nil layoutBuilder: nil
                            bounds: NSMakeRect(0, 0, 0, 0)];
}

- (instancetype) initWithVisibleTree:(FileItem *)visibleTree
                          treeInView:(FileItem *)treeInView
                       layoutBuilder:(TreeLayoutBuilder *)layoutBuilder
                              bounds:(NSRect) bounds {
  if (self = [super init]) {
    _visibleTree = [visibleTree retain];
    _treeInView = [treeInView retain];
    _layoutBuilder = [layoutBuilder retain];
    _bounds = bounds;
  }
  return self;
}

- (void) dealloc {
  [_visibleTree release];
  [_treeInView release];
  [_layoutBuilder release];
  
  [super dealloc];
}

@end
