#import <Cocoa/Cocoa.h>

#import "Item.h"

/* Bitmasks used for the flags field of the FileItem
 */
// Note: Using "NOT_PHYSICAL" as a mask as opposed to "PHYSICAL" so that a set
// bit signals an exceptional setting. 
#define FILE_IS_NOT_PHYSICAL 0x01
#define FILE_IS_HARDLINKED 0x02
#define FILE_IS_PACKAGE 0x04


@class DirectoryItem;

@interface FileItem : Item {
  /* The label of the item. For physical file items this is the system representation of its path
   * component. For other non-physical items, it is a non-localized string identifier.
   */
  NSString  *label;
  DirectoryItem  *parent;

  // Bitmask for storing boolean properties of the file
  UInt8  flags;
  
  CFAbsoluteTime  creationTime;
  CFAbsoluteTime  modificationTime;
  CFAbsoluteTime  accessTime;
}

/* The supported values for the fileSizeUnitSystem preference. These affect how the file size
 * strings are constructed.
 */
+ (NSArray *) fileSizeUnitSystemNames;

/* Returns the number of bytes per kilobyte. It can be either 1024 or 1000 based on the 
 * fileSizeMeasurePreference.
 */
+ (int) bytesPerKilobyte;

- (id) initWithLabel: (NSString *)label
              parent: (DirectoryItem *)parent
                size: (ITEM_SIZE) size
               flags: (UInt8) flags
        creationTime: (CFAbsoluteTime) creationTime
    modificationTime: (CFAbsoluteTime) modificationTime
          accessTime: (CFAbsoluteTime) accessTime;


/* Creates a duplicate item, for use in a new tree (so with a new parent).
 *
 * Note: If the item is a directory, its contents still need to be set, as
 * these can be different from the original item, e.g. by applying a filter.
 */
- (FileItem *)duplicateFileItem:(DirectoryItem *)newParent;


- (NSString *)label;

- (DirectoryItem *) parentDirectory;

- (BOOL) isAncestorOfFileItem:(FileItem *)fileItem;
  
/* Returns YES iff the file item is a directory.
 */
- (BOOL) isDirectory;


/* Time when the file item was created.
 */
- (CFAbsoluteTime) creationTime;

/* Time when the file item was last modified.
 */
- (CFAbsoluteTime) modificationTime;

/* Time when the file item was last accessed.
 */
- (CFAbsoluteTime) accessTime;


/* Bit-mask flags. Lower-level representation for the file's physical, 
 * hard-linked, and package status.
 */
- (UInt8) fileItemFlags;

/* Returns YES iff the file item is physical, i.e. it is an actual file on the
 * file system. A file item that is not physical may for example represent the
 * free space on a volume. 
 */
- (BOOL) isPhysical;

/* Returns YES iff the file item is hardlinked.
 */
- (BOOL) isHardLinked;

/* Return YES iff the file item is a package.
 *
 * Note: Although packages are always directories in the underlying file 
 * system, they may be represented by file items that are plain files 
 * (namely when package contents are hidden). This is the reason that this
 * method is introduced by the FileItem class.
 */
- (BOOL) isPackage;


/* Returns the path component that the item contributes to the path. The path
 * component is nil if the item is not physical.
 */
- (NSString *)pathComponent;

/* Returns the path to the file item. It is the path as shown to the user. The
 * system representation of the path can be different. This is for example the
 * case when a path component contains slash characters.
 *
 * See also: -systemPath
 */
- (NSString *)path;

/* Returns the path to the file item, in the file system representation.
 * 
 * See also: -path
 */
- (NSString *)systemPath;


/* Returns a short string, approximating the given size. E.g. "1.23 MB"
 */
+ (NSString *)stringForFileItemSize:(ITEM_SIZE) size;

/* Returns a string, specifying the file size exactly. E.g. "12345678 bytes"
 */
+ (NSString *)exactStringForFileItemSize:(ITEM_SIZE) size;

/* Returns a string for the provided time.
 */
+ (NSString *)stringForTime:(CFAbsoluteTime) absTime;

/* Returns path component as it is displayed to user, with colons replaced by slashes.
 */
+ (NSString *)friendlyPathComponentFor: (NSString *)pathComponent;

/* Returns path component as it is used by system, with slashes replaced by colons.
 */
+ (NSString *)systemPathComponentFor: (NSString *)pathComponent;

@end // @interface FileItem


@interface FileItem (ProtectedMethods) 

/* Returns the path component that the item contributes to the path, in the 
 * file system representation.
 *
 * See also -pathComponent.
 */
- (NSString *)systemPathComponent;

@end // @interface FileItem (ProtectedMethods)
