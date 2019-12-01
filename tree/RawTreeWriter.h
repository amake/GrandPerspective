#import <Foundation/Foundation.h>

#import "TreeWriter.h"
#import "RawTreeWriterOptions.h"

NS_ASSUME_NONNULL_BEGIN

/* Writes a tree to file in raw format. Each file is on its own line, with tab-separated fields:
 * First, the full path of the file. Second, its size in bytes.
 */
@interface RawTreeWriter : TreeWriter {
  RawTreeWriterOptions  *options;

  NSAutoreleasePool  *autoreleasePool;
}

- (void) writeTree:(AnnotatedTreeContext *)tree options:(id)options;

@end

NS_ASSUME_NONNULL_END
