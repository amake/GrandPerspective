#import "SaveImageDialogControl.h"

#import "ControlConstants.h"

#import "DirectoryView.h"
#import "DirectoryViewControl.h"
#import "TreeDrawer.h"
#import "ItemPathModel.h"
#import "DirectoryItem.h"

#define MINIMUM_SIZE 16


@implementation SaveImageDialogControl

- (id) init {
  NSAssert(NO, @"Use -initWithDirectoryViewControl: instead");
  return nil;
}

// Special case: should not cover (override) super's designated initialiser in NSWindowController's
// case
- (id) initWithDirectoryViewControl: (DirectoryViewControl*)dirViewControlVal {
         
  if (self = [super initWithWindowNibName: @"SaveImageDialog" owner: self]) {
    dirViewControl = [dirViewControlVal retain];
    
    // Trigger loading of window.
    [self window];
  }

  return self;
}

- (void) dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  
  [dirViewControl release];
  
  [super dealloc];
}


- (void) windowDidLoad {
  [[NSNotificationCenter defaultCenter] addObserver: self
                                           selector: @selector(windowWillClose:)
                                               name: NSWindowWillCloseNotification
                                             object: [self window]];

  [[self window] center];
  [[self window] makeKeyAndOrderFront: self];

  NSRect  bounds = [[dirViewControl directoryView] bounds];
  // Setting string value directly instead of using setIntValue, as the latter adds a decimal
  // separator. Even worse, the reverse operation using intValue to retrieve the integer value can
  // give a different number.
  // On my system, the following happened on OS X 10.11: 1920 -> "1.920" -> 1
  [widthField setStringValue: [NSString stringWithFormat: @"%d", (int)bounds.size.width]];
  [heightField setStringValue: [NSString stringWithFormat: @"%d", (int)bounds.size.height]];
}


- (void) windowWillClose:(NSNotification *)notification {
   [self autorelease];
}


// Auto-corrects the width/height fields so that they contain a valid numeric value.
- (IBAction)valueEntered:(id)sender {
  int  value = [sender intValue];
  
  if (value < MINIMUM_SIZE) {
    [sender setIntValue: MINIMUM_SIZE];
  }
}


- (IBAction)cancelSaveImage:(id)sender {
  [[self window] close];
}


- (IBAction)saveImage:(id)sender {
  [[self window] close];

  // Retrieve the desired size of the image.
  // Note: Cannot rely on valueEntered: for making sure that the size is valid. The action event is
  // not fired when the user modifies a text field and directly clicks OK. Therefore using MAX to
  // ensure that both dimensions are positive.
  NSRect  bounds = NSMakeRect(0, 0, MAX(MINIMUM_SIZE, [widthField intValue]),
                                    MAX(MINIMUM_SIZE, [heightField intValue]));

  // Get a filename for the image.
  NSSavePanel  *savePanel = [NSSavePanel savePanel]; 
  [savePanel setAllowedFileTypes: [NSArray arrayWithObject: @"tiff"]];
  [savePanel setTitle: NSLocalizedString( @"Save image", @"Title of save panel") ];
  
  if ([savePanel runModal] == NSModalResponseOK) {
    NSURL  *destURL = [savePanel URL];
    
    // Draw the image.
    DirectoryView  *dirView = [dirViewControl directoryView];
    ItemPathModelView  *pathModelView = [dirView pathModelView];
    TreeDrawer  *treeDrawer = [[[TreeDrawer alloc] initWithScanTree: [pathModelView scanTree]
                                                 treeDrawerSettings: [dirView treeDrawerSettings]]
                               autorelease];
    NSImage  *image = [treeDrawer drawImageOfVisibleTree: [pathModelView visibleTree]
                                          startingAtTree: [dirView treeInView]
                                      usingLayoutBuilder: [dirView layoutBuilder]
                                                  inRect: bounds];
    
    // Save the image.
    NSBitmapImageRep  *imageBitmap = (NSBitmapImageRep *)[[image representations] objectAtIndex: 0];
    NSData  *imageData = [imageBitmap representationUsingType: NSTIFFFileType
                                                   properties: @{}];

    if (! [imageData  writeToURL: destURL atomically: NO] ) {
      NSAlert *alert = [[[NSAlert alloc] init] autorelease];

      [alert addButtonWithTitle: OK_BUTTON_TITLE];
      [alert setMessageText: NSLocalizedString(@"Failed to save the image.", @"Alert message")];

      [alert runModal];
    }
  }
}

@end
