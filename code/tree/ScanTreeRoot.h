#import <Cocoa/Cocoa.h>

#import "DirectoryItem.h"

/* The directory item that is at the root of the scan tree.
 *
 * It requires a special class to be able to provide both a system-representation and friendly
 * representation of its name. The reason is that it may consist of multiple path components.
 */
@interface ScanTreeRoot : DirectoryItem {
  NSString  *systemName;
}

@end // @interface ScanTreeRoot
