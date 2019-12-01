#import "ExportAsTextDialogControl.h"

#include "RawTreeWriterOptions.h"

@interface ExportAsTextDialogControl (PrivateMethods)

- (void) updateButton:(NSButton *)button basedOnOptions:(RawTreeWriterOptions *)options;
- (void) updateOptions:(RawTreeWriterOptions *)options basedOnButton:(NSButton *)button;

@end

@implementation ExportAsTextDialogControl

- (NSString *)windowNibName {
  return @"ExportAsTextDialog";
}

- (void)windowDidLoad {
  [super windowDidLoad];

  RawTreeWriterOptions*  initialOptions = [RawTreeWriterOptions defaultOptions];

  [self updateButton: addPathColumn basedOnOptions: initialOptions];
  [self updateButton: addFilenameColumn basedOnOptions: initialOptions];
  [self updateButton: addSizeColumn basedOnOptions: initialOptions];
  [self updateButton: addTypeColumn basedOnOptions: initialOptions];
  [self updateButton: addCreationTimeColumn basedOnOptions: initialOptions];
  [self updateButton: addModificationTimeColumn basedOnOptions: initialOptions];
  [self updateButton: addLastAccessTimeColumn basedOnOptions: initialOptions];

  addHeaders.state = [initialOptions headersEnabled] ? NSOnState : NSOffState;

  [self.window center];
  [self.window makeKeyAndOrderFront: self];
}

- (IBAction) okAction:(id)sender {
  [NSApp stopModal];
}

- (IBAction) cancelAction:(id)sender {
  [NSApp abortModal];
}

- (RawTreeWriterOptions *)rawTreeWriterOptions {
  RawTreeWriterOptions*  options = [RawTreeWriterOptions defaultOptions];

  [self updateOptions: options basedOnButton: addPathColumn];
  [self updateOptions: options basedOnButton: addFilenameColumn];
  [self updateOptions: options basedOnButton: addSizeColumn];
  [self updateOptions: options basedOnButton: addTypeColumn];
  [self updateOptions: options basedOnButton: addCreationTimeColumn];
  [self updateOptions: options basedOnButton: addModificationTimeColumn];
  [self updateOptions: options basedOnButton: addLastAccessTimeColumn];

  [options setHeadersEnabled: addHeaders.state == NSOnState];

  return options;
}

@end // @implementation ExportAsTextDialogControl

@implementation ExportAsTextDialogControl (PrivateMethods)

- (void) updateButton:(NSButton *)button basedOnOptions:(RawTreeWriterOptions *)options {
  button.state = [options isColumnShown: button.tag] ? NSOnState : NSOffState;
}

- (void) updateOptions:(RawTreeWriterOptions *)options basedOnButton:(NSButton *)button {
  if (button.state == NSOnState) {
    [options showColumn: button.tag];
  } else {
    [options hideColumn: button.tag];
  }
}

@end // @implementation ExportAsTextDialogControl (PrivateMethods)
