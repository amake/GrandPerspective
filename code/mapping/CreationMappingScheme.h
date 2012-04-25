#import <Foundation/Foundation.h>

#import "FileItemMappingScheme.h"

/* Mapping scheme that maps each file item to a hash based on its creation time.
 */
@interface CreationMappingScheme : NSObject <FileItemMappingScheme>

@end
