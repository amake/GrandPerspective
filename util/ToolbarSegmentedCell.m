#import "ToolbarSegmentedCell.h"

@implementation ToolbarSegmentedCell

- (void) setImagesToTemplate {
  NSUInteger  i = self.segmentCount;
  while (i-- > 0) {
    [[self imageForSegment: i] setTemplate: YES];
  }
}

@end

