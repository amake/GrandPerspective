#import "DrawTaskInput.h"

NS_ASSUME_NONNULL_BEGIN

@class FileItemTest;

@interface OverlayDrawTaskInput : DrawTaskInput {
}

- (instancetype) initWithVisibleTree:(FileItem *)visibleTree
                          treeInView:(FileItem *)treeInView
                       layoutBuilder:(TreeLayoutBuilder *)layoutBuilder
                         sourceImage:(NSImage *)sourceImage
                         overlayTest:(FileItemTest *)overlayTest;

@property (nonatomic, readonly, strong) NSImage *sourceImage;
@property (nonatomic, readonly, strong) FileItemTest *overlayTest;

@end

NS_ASSUME_NONNULL_END
