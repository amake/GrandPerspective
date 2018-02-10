#import <Cocoa/Cocoa.h>


/* Event fired when the color palette has changed. 
 */
extern NSString  *ColorPaletteChangedEvent;

/* Event fired when the color mapper has changed. This is the case when the color mapping scheme
 * changed, or when the scheme changed the way it maps file items to hash values.
 */
extern NSString  *ColorMappingChangedEvent;


@class AsynchronousTaskManager;
@class TreeLayoutBuilder;
@class FileItem;
@class TreeDrawerSettings;
@class ItemPathDrawer;
@class ItemPathModelView;
@class SelectedItemLocator;
@protocol FileItemMappingScheme;

@interface DirectoryView : NSView {
  AsynchronousTaskManager  *drawTaskManager;

  // Even though layout builder could also be considered part of the itemTreeDrawerSettings, it is
  // maintained here, as it is also needed by the pathDrawer, and other objects.
  TreeLayoutBuilder  *layoutBuilder;
  
  ItemPathDrawer  *pathDrawer;
  ItemPathModelView  *pathModelView;
  SelectedItemLocator  *selectedItemLocator;
  
  // The current color mapping, which is being observed for any changes to the scheme.
  NSObject <FileItemMappingScheme>  *observedColorMapping;

  BOOL  showEntireVolume;

  NSImage  *treeImage;
  
  // Indicates if the image has been resized to fit inside the current view. This is only a
  // temporary measure. A new image is already being constructed for the new size, but as long as
  // that's not yet ready, the scaled image can be used.
  BOOL  treeImageIsScaled;
  
  float  scrollWheelDelta;
}

// Initialises the instance-specific state after the view has been restored
// from the nib file (which invokes the generic initWithFrame: method).
- (void) postInitWithPathModelView:(ItemPathModelView *)pathModelView;

@property (nonatomic, readonly, strong) ItemPathModelView *pathModelView;
@property (nonatomic, readonly, strong) FileItem *treeInView;

- (NSRect) locationInViewForItemAtEndOfPath:(NSArray *)itemPath;
- (NSImage *)imageInViewForItemAtEndOfPath:(NSArray *)itemPath;

@property (nonatomic, strong) TreeDrawerSettings *treeDrawerSettings;

@property (nonatomic) BOOL showEntireVolume;

@property (nonatomic, readonly, strong) TreeLayoutBuilder *layoutBuilder;

@property (nonatomic, readonly) BOOL canZoomIn;
@property (nonatomic, readonly) BOOL canZoomOut;

- (void) zoomIn;
- (void) zoomOut;

@property (nonatomic, readonly) BOOL canMoveFocusUp;
@property (nonatomic, readonly) BOOL canMoveFocusDown;

- (void) moveFocusUp;
- (void) moveFocusDown;

@end
