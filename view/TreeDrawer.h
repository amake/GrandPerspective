#import <Cocoa/Cocoa.h>

#include "TreeDrawerBase.h"

@class GradientRectangleDrawer;
@class TreeDrawerSettings;
@class FileItemTest;
@protocol FileItemMapping;

@interface TreeDrawer : TreeDrawerBase {
  GradientRectangleDrawer  *rectangleDrawer;
  NSObject <FileItemMapping>  *colorMapper;
  
  UInt32  freeSpaceColor;
  UInt32  usedSpaceColor;
  UInt32  visibleTreeBackgroundColor;
}

- (instancetype) initWithScanTree:(DirectoryItem *)scanTree
               treeDrawerSettings:(TreeDrawerSettings *)settings NS_DESIGNATED_INITIALIZER;

@property (nonatomic, strong) FileItemTest *maskTest;

@property (nonatomic, strong) NSObject<FileItemMapping> *colorMapper;

@property (nonatomic) BOOL showPackageContents;

// Updates the drawer according to the given settings.
- (void) updateSettings:(TreeDrawerSettings *)settings;

@end
