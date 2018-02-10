#import <Cocoa/Cocoa.h>


@class DirectoryViewControl;

/* A one-shot image saving device. It disposes after having done its job.
 */
@interface SaveImageDialogControl : NSWindowController {
  IBOutlet NSTextField  *widthField;
  IBOutlet NSTextField  *heightField;

  DirectoryViewControl  *dirViewControl;
}

- (instancetype) initWithDirectoryViewControl:(DirectoryViewControl *)dirViewControl NS_DESIGNATED_INITIALIZER;

- (IBAction)valueEntered:(id)sender;
- (IBAction)cancelSaveImage:(id)sender;
- (IBAction)saveImage:(id)sender;

@end
