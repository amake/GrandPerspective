#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class RawTreeWriterOptions;

@interface ExportAsTextDialogControl : NSWindowController {
  IBOutlet NSButton  *addPathColumn;
  IBOutlet NSButton  *addFilenameColumn;
  IBOutlet NSButton  *addSizeColumn;
  IBOutlet NSButton  *addTypeColumn;
  IBOutlet NSButton  *addCreationTimeColumn;
  IBOutlet NSButton  *addModificationTimeColumn;
  IBOutlet NSButton  *addLastAccessTimeColumn;

  IBOutlet NSButton  *addHeaders;
}

- (IBAction) okAction:(id)sender;
- (IBAction) cancelAction:(id)sender;

- (RawTreeWriterOptions *)rawTreeWriterOptions;

@end

NS_ASSUME_NONNULL_END
