#import "RawTreeWriterOptions.h"

@implementation RawTreeWriterOptions

// Constructs instance with default settings
- (id)init {
  if (self = [super init]) {
    // By default, only show full path and size
    columnFlags = ColumnPath|ColumnSize;

    _headersEnabled = YES;
  }

  return self;
}

+ (RawTreeWriterOptions *)defaultOptions {
  return [[[RawTreeWriterOptions alloc] init] autorelease];
}

// Toggle given column(s) so that they are output
- (void)showColumn:(RawTreeColumnFlags)flags {
  columnFlags |= flags;
}

// Toggle given column(s) so that they are hidden
- (void)hideColumn:(RawTreeColumnFlags)flags {
  columnFlags &= ~flags;
}

// Returns YES if the given column is shown (or if more flags are set, all given columns are shown)
- (BOOL)isColumnShown:(RawTreeColumnFlags)flags {
  return (columnFlags & flags) == flags;
}

@end
