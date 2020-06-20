#import "TreeDrawer.h"

#import "DirectoryItem.h"
#import "FileItemMapping.h"
#import "FilteredTreeGuide.h"
#import "GradientRectangleDrawer.h"
#import "TreeDrawerSettings.h"


@implementation TreeDrawer

// Overrides designated initialiser of base class
- (instancetype) initWithScanTree:(DirectoryItem *)scanTreeVal
                     colorPalette:(NSColorList *)colorPalette {
  TreeDrawerSettings  *defaultSettings = [[[TreeDrawerSettings alloc] init] autorelease];
  if (colorPalette) {
    defaultSettings = [defaultSettings copyWithColorPalette: colorPalette];
  }

  return [self initWithScanTree: scanTreeVal treeDrawerSettings: defaultSettings];
}

- (instancetype) initWithScanTree:(DirectoryItem *)scanTreeVal
               treeDrawerSettings:(TreeDrawerSettings *)settings {
  if (self = [super initWithScanTree: scanTreeVal
                        colorPalette: settings.colorPalette]) {
    // Make sure values are set before calling updateSettings.
    colorMapper = nil;

    [self updateSettings: settings];
    
    freeSpaceColor = [rectangleDrawer intValueForColor: NSColor.blackColor];
    usedSpaceColor = [rectangleDrawer intValueForColor: NSColor.darkGrayColor];
    visibleTreeBackgroundColor = [rectangleDrawer intValueForColor: NSColor.grayColor];
  }
  return self;
}

- (void) dealloc {
  [colorMapper release];

  [super dealloc];
}


- (void) setColorMapper:(NSObject <FileItemMapping> *)colorMapperVal {
  NSAssert(colorMapperVal != nil, @"Cannot set an invalid color mapper.");

  if (colorMapperVal != colorMapper) {
    [colorMapper release];
    colorMapper = [colorMapperVal retain];
  }
}

- (NSObject <FileItemMapping> *)colorMapper {
  return colorMapper;
}


- (void) setMaskTest:(FileItemTest *)maskTest {
  [treeGuide setFileItemTest: maskTest];
}

- (FileItemTest *)maskTest {
  return [treeGuide fileItemTest];
}


- (void) setShowPackageContents:(BOOL)showPackageContents {
  [treeGuide setPackagesAsFiles: !showPackageContents];
}

- (BOOL) showPackageContents {
  return ! [treeGuide packagesAsFiles];
}


- (void) updateSettings:(TreeDrawerSettings *)settings {
  [self setColorMapper: settings.colorMapper];
  [rectangleDrawer setColorPalette: settings.colorPalette];
  [rectangleDrawer setColorGradient: settings.colorGradient];
  [self setMaskTest: settings.maskTest];
  [self setShowPackageContents: settings.showPackageContents];
}


// Overrides of protected methods

- (void) drawVisibleTreeAtRect:(FileItem *)visibleTree rect:(NSRect) rect {
  [rectangleDrawer drawBasicFilledRect: rect intColor: visibleTreeBackgroundColor];
}

- (void)drawUsedSpaceAtRect:(NSRect) rect {
  [rectangleDrawer drawBasicFilledRect: rect intColor: usedSpaceColor];
}

- (void)drawFreeSpaceAtRect:(NSRect) rect {
  [rectangleDrawer drawBasicFilledRect: rect intColor: freeSpaceColor];
}

- (void)drawFreedSpaceAtRect:(NSRect) rect {
  [rectangleDrawer drawBasicFilledRect: rect intColor: freeSpaceColor];
}

- (void)drawFile:(PlainFileItem *)fileItem atRect:(NSRect) rect depth:(int) depth {
  NSUInteger  colorIndex = [colorMapper hashForFileItem: fileItem atDepth: depth];
  if ( [colorMapper canProvideLegend] ) {
    colorIndex = MIN(colorIndex, rectangleDrawer.numGradientColors - 1);
  }
  else {
    colorIndex = colorIndex % rectangleDrawer.numGradientColors;
  }

  [rectangleDrawer drawGradientFilledRect: rect colorIndex: colorIndex];
}

@end // @implementation TreeDrawer
