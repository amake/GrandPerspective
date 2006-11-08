#import <Cocoa/Cocoa.h>

#import "TreeLayoutTraverser.h"

@class Item;
@class TreeLayoutBuilder;
@class FileItemHashing;
@class ColorPalette;
@protocol FileItemTest;

@interface ItemTreeDrawer : NSObject <TreeLayoutTraverser> {

  FileItemHashing  *fileItemHashing;
  NSObject<FileItemTest>  *fileItemMask;
  
  TreeLayoutBuilder  *layoutBuilder;

  NSColorList  *colorPalette;
  UInt32  *gradientColors;
  int  numGradientColors;

  NSBitmapImageRep  *drawBitmap;
  BOOL  abort;
}

- (id) initWithFileItemHashing:(FileItemHashing*)fileItemHashing;

- (id) initWithFileItemHashing: (FileItemHashing*)fileItemHashing
         colorPalette: (NSColorList*)colorPalette
         layoutBuilder: (TreeLayoutBuilder*)layoutBuilder;

- (void) setTreeLayoutBuilder: (TreeLayoutBuilder*)layoutBuilder;
- (TreeLayoutBuilder*) treeLayoutBuilder;

- (void) setFileItemMask:(NSObject <FileItemTest>*)fileItemMask;
- (NSObject <FileItemTest> *) fileItemMask;

- (void) setFileItemHashing:(FileItemHashing*)fileItemHashing;
- (FileItemHashing*) fileItemHashing;

- (void) setColorPalette: (NSColorList*)colorPalette;
- (NSColorList*) colorPalette;

// The tree starting at "itemTreeRoot" should be immutable.
- (NSImage*) drawImageOfItemTree: (Item*)itemTreeRoot inRect: (NSRect)bounds;

- (void) abortDrawing;

@end
