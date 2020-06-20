#import "OverlayDrawer.h"

#import "FileItem.h"
#import "FilteredTreeGuide.h"
#import "TreeLayoutBuilder.h"

@interface OverlayDrawer (PrivateMethods)

- (CGContextRef) createContextWithImage:(NSImage *)image;

@end

@implementation OverlayDrawer

- (NSImage *)drawOverlayImageOfVisibleTree:(FileItem *)visibleTree
                            startingAtTree:(FileItem *)treeRoot
                        usingLayoutBuilder:(TreeLayoutBuilder *)layoutBuilder
                                   onTopOf:(NSImage *)sourceImage
                               overlayTest:(FileItemTest *)overlayTest; {
  [treeGuide setFileItemTest: overlayTest];

  cgContext = [self createContextWithImage: sourceImage];

  NSRect bounds = NSMakeRect(0, 0, sourceImage.size.width, sourceImage.size.height);
  [super drawImageOfVisibleTree: visibleTree
                 startingAtTree: treeRoot
             usingLayoutBuilder: layoutBuilder
                         inRect: bounds];

  CGImageRef cgImage = CGBitmapContextCreateImage(cgContext);
  NSImage *image = [[NSImage alloc] initWithCGImage: cgImage size: NSZeroSize];
  CGImageRelease(cgImage);

  CGContextRelease(cgContext);
  cgContext = nil;

  return image;
}

- (void)drawFile:(PlainFileItem *)fileItem atRect:(NSRect) rect depth:(int) depth {
  // Plain file that passed the test. Highlight it
  CGContextSetBlendMode(cgContext, kCGBlendModeColorDodge);
  CGContextSetRGBFillColor(cgContext, 0.5, 0.5, 0.5, 1.0);
  CGContextFillRect(cgContext, rect);
}

- (void)skippingFileItem:(FileItem *)fileItem atRect:(NSRect) rect {
  // File item that failed the test. Darken it
  CGContextSetBlendMode(cgContext, kCGBlendModeColorBurn);
  CGContextSetRGBFillColor(cgContext, 0.9, 0.9, 0.9, 1.0);
  CGContextFillRect(cgContext, rect);
}

@end


@implementation OverlayDrawer (PrivateMethods)

- (CGContextRef) createContextWithImage:(NSImage *)image {
  CGContextRef context = CGBitmapContextCreate
    (nil, // Data: nil -> allocated automatically
     (int)image.size.width,
     (int)image.size.height,
     8, // Bits per component
     0, // Bytes per row: 0 -> calculated automatically
     CGColorSpaceCreateDeviceRGB(),
     // Should be 32-bits. Unclear if SkipFirst or SkipLast is better
     kCGImageAlphaNoneSkipFirst);

  CGRect cgImageRect = CGRectMake(0, 0, image.size.width, image.size.height);
  CGImageRef cgImage = [image CGImageForProposedRect: nil context: nil hints: nil];
  CGContextDrawImage(context, cgImageRect, cgImage);
  //CGImageRelease(cgImage); // TODO: Confirm not needed.

  return context;
}

@end // OverlayDrawer (PrivateMethods)
