#import <Cocoa/Cocoa.h>

#import "FileItemMapping.h"


@protocol FileItemMappingScheme;

/* Base class for file item mapping implementations that maintain state, which are therefore not
 * thread-safe.
 */
@interface StatefulFileItemMapping : NSObject <FileItemMapping> {

  // Backing field for property defined by FileItemMapping
  NSObject <FileItemMappingScheme>  *_scheme;

}

- (instancetype) initWithFileItemMappingScheme:(NSObject <FileItemMappingScheme> *)scheme NS_DESIGNATED_INITIALIZER;

@end
