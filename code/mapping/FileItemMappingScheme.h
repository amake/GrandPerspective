#import <Cocoa/Cocoa.h>


/* Event that is fired when there have been changes to the mapping scheme
 * that may cause one or more file items to map to a different hash value.
 */
extern NSString  *MappingSchemeChangedEvent;


@protocol FileItemMapping;
@class DirectoryItem;

/* A file item mapping scheme. It represents a particular algorithm for 
 * mapping file items to hash values.
 *
 * File item mapping schemes can safely be used from multiple threads by 
 * multiple different views.
 */
@protocol FileItemMappingScheme

/* Returns a file item mapping instance that implements the scheme for the given
 * tree. When the implementation cannot be shared by multiple different views, a 
 * new instance is returned for each invocation. 
 *
 * The tree on which the mapping should operate is provided for mappings that
 * depend on the tree (e.g. to optimize the mapping) 
 */
- (NSObject <FileItemMapping> *) fileItemMappingForTree: (DirectoryItem *)tree;

@end
