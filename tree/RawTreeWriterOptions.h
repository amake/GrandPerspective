#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(UInt8, RawTreeColumnFlags) {
  ColumnPath             = 0x01,
  ColumnName             = 0x02,
  ColumnSize             = 0x04,
  ColumnType             = 0x08,
  ColumnCreationTime     = 0x10,
  ColumnModificationTime = 0x20,
  ColumnAccessTime       = 0x40
};

@interface RawTreeWriterOptions : NSObject {
  RawTreeColumnFlags  columnFlags;
}

@property (nonatomic, readwrite) BOOL headersEnabled;

// Constructs instance with default settings
- (id)init;

+ (RawTreeWriterOptions *)defaultOptions;

// Toggle given column(s) so that they are output
- (void)showColumn:(RawTreeColumnFlags)flags;

// Toggle given column(s) so that they are hidden
- (void)hideColumn:(RawTreeColumnFlags)flags;

// Returns YES if the given column is shown (or if more flags are set, all given columns are shown)
- (BOOL)isColumnShown:(RawTreeColumnFlags)flags;

@end

NS_ASSUME_NONNULL_END
