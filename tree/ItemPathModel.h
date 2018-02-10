#import <Cocoa/Cocoa.h>


extern NSString  *SelectedItemChangedEvent;
extern NSString  *VisibleTreeChangedEvent;
extern NSString  *VisiblePathLockingChangedEvent;


@class Item;
@class FileItem;
@class DirectoryItem;
@class TreeContext;


@interface ItemPathModel : NSObject<NSCopying> {
  TreeContext  *treeContext;

  // Contains the Items from the root until the end of the path.
  NSMutableArray  *path;

  // The index in the path array where the subtree starts (always a FileItem)
  NSUInteger  visibleTreeIndex;
  
  // The root of the scan tree. The visible tree should always be inside the
  // scan tree.
  NSUInteger  scanTreeIndex;

  // The index in the path array where the selected file item is.
  //
  // Note: It is always part of the visible item path)
  NSUInteger  selectedItemIndex;
  
  // The index in the path array where the visible file path ends (always a FileItem).
  //
  // Note: It is not necessarily always the last item in the array, as one or more virtual items may
  // still follow (in particular when the path is being extended).
  NSUInteger  lastFileItemIndex;
  
  // Controls if "selectedItemChanged" notifications are being (temporarily) supressed. If it is set
  // to nil, they are posted as they occur. Otherwise it will suppress notifications, but remember
  // the current selection state. As soon as notifications are enabled again, it will check if a
  // notification needs to be fired.
  FileItem  *lastNotifiedSelectedItem;

  // Controls if "visibleTreeChanged" notifications are being (temporarily) supressed.
  FileItem  *lastNotifiedVisibleTree;

  // If it is set to "NO", the visible item path cannot be changed. (Note: the invisible part can
  // never be changed directly. Only by first making it visible can it be changed).
  BOOL  visiblePathLocked;
}

+ (id) pathWithTreeContext:(TreeContext *)treeContext;

- (instancetype) initWithTreeContext:(TreeContext *)treeContext NS_DESIGNATED_INITIALIZER;


/* Returns the file items in the path.
 */
@property (nonatomic, readonly, copy) NSArray *fileItemPath;

/* Returns the file items in the path using the provided array.
 */
- (NSArray *)fileItemPath:(NSMutableArray *)array;


/* Returns all items in the path.
 *
 * Note: For efficiency returns its own array instead of a copy. The contents may change. This does
 * not matter if it is used directly, but otherwise, it should be copied before retaining it.
 */
@property (nonatomic, readonly, copy) NSArray *itemPath;

/* Returns all items in the path up until the selected item.
 *
 * Note: It creates a new array, which will not change when the selection changes.
 */
@property (nonatomic, readonly, copy) NSArray *itemPathToSelectedFileItem;


@property (nonatomic, readonly, strong) TreeContext *treeContext;

/* Returns the volume tree.
 */
@property (nonatomic, readonly, strong) DirectoryItem *volumeTree;

/* Returns the root of the scanned tree.
 */
@property (nonatomic, readonly, strong) DirectoryItem *scanTree;

/* Returns the root of the visible tree. The visible tree is the part of the volume tree whose
 * treemap is drawn.
 */
@property (nonatomic, readonly, strong) FileItem *visibleTree;

/* Returns the selected file item. It is always part of the visible path.
 */
@property (nonatomic, readonly, strong) FileItem *selectedFileItem;

/* Returns the last file item on the path.
 */
@property (nonatomic, readonly, strong) FileItem *lastFileItem;

/* Selects the given file item. It should be an item that is already on the path. If it is not yet
 * on the visible part of the path, the visible tree will be moved up so that the selected item will
 * be on the visible path.
 */
- (void) selectFileItem:(FileItem *)fileItem;

@property (nonatomic, getter=isVisiblePathLocked, readonly) BOOL visiblePathLocked;
- (void) setVisiblePathLocking:(BOOL)value;

- (void) suppressSelectedItemChangedNotifications:(BOOL)option;
- (void) suppressVisibleTreeChangedNotifications:(BOOL)option;


@property (nonatomic, readonly) BOOL clearVisiblePath;
- (void) extendVisiblePath:(Item *)nextItem;

/* Attemps to extend the path with a file item equal to the specified one.
 *
 * Note: The path is extended with at most one file item. I.e. it does not recurse into
 * subdirectories.
 */
- (BOOL) extendVisiblePathToFileItem: (FileItem *)item;

/* Attemps to extend the path with a file item similar to the specified one. A file item is similar
 * if it has the same name, and the "isPhysical" and "isDirectory" attributes match.
 *
 * Note: The path is extended with at most one file item. I.e. it does not recurse into
 * subdirectories.
 */
- (BOOL) extendVisiblePathToSimilarFileItem:(FileItem *)item;

@property (nonatomic, readonly) BOOL canMoveVisibleTreeUp;
@property (nonatomic, readonly) BOOL canMoveVisibleTreeDown;
- (void) moveVisibleTreeUp;
- (void) moveVisibleTreeDown;

@end
