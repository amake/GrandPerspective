#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class AnnotatedTreeContext;
@class ProgressTracker;

@interface TreeWriter : NSObject {
  BOOL  abort;
  NSError  *error;

  ProgressTracker  *progressTracker;
}

/* Writes the tree to file (in XML format). Returns YES if the operation completed successfully.
 * Returns NO if an error occurred, or if the operation has been aborted. In the latter case the
 * file will still be valid. It simply will not contain all files/folders in the tree.
 */
- (BOOL) writeTree:(AnnotatedTreeContext *)tree toFile:(NSString *)path;

/* Aborts writing (when it is carried out in a different execution thread).
 */
- (void) abort;

/* Returns YES iff the writing task was aborted externally (i.e. using -abort).
 */
@property (nonatomic, readonly) BOOL aborted;

/* Returns details of the error iff there was an error when carrying out the writing task.
 */
@property (nonatomic, readonly, copy, nullable) NSError *error;

/* Returns a dictionary containing information about the progress of the ongoing tree-writing task.
 *
 * It can safely be invoked from a different thread than the one that invoked -writeTree:toFile:
 * (and not doing so would actually be quite silly).
 */
@property (nonatomic, readonly, copy) NSDictionary *progressInfo;

@end

@interface TreeWriter (ProtectedMethods)

/* Formatter used to create (locale-independent) string reprentations for time values.
 */
+ (CFDateFormatterRef) timeFormatter CF_RETURNS_NOT_RETAINED;

/* Formatter used to create (locale-independent) string reprentations for time values. Has same
 * format as timeFormatter.
 */
+ (NSDateFormatter *)nsTimeFormatter;

+ (NSString *)stringForTime:(CFAbsoluteTime)time;

@end

NS_ASSUME_NONNULL_END
