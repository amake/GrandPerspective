#import "StartWindowControl.h"

#import "RecentDocumentTableCellView.h"

NSString*  TaglineTable = @"Taglines";
NSString*  NumTaglines = @"num-taglines";
NSString*  TaglineFormat = @"tagline-%d";

@interface StartWindowControl (PrivateMethods)

- (void) setTagLineField;

@end // @interface StartWindowControl (PrivateMethods)

@implementation StartWindowControl

// Override designated initialisers
- (instancetype) initWithWindow:(NSWindow *)window {
  NSAssert(NO, @"Use initWithMainMenuControl: instead");
  return [self initWithMainMenuControl: nil];
}
- (instancetype) initWithCoder:(NSCoder *)coder {
  NSAssert(NO, @"Use initWithMainMenuControl: instead");
  return [self initWithMainMenuControl: nil];
}

- (instancetype) initWithMainMenuControl:(MainMenuControl *)mainMenuControlVal {
  if (self = [super initWithWindow: nil]) {
    mainMenuControl = [mainMenuControlVal retain];

    numTagLines = [[NSBundle mainBundle] localizedStringForKey: NumTaglines
                                                         value: @"1"
                                                         table: TaglineTable].intValue;

    // Show a random tagline
    tagLineIndex = arc4random_uniform(numTagLines);
  }
  return self;
}

- (void) dealloc {
  NSLog(@"StartWindowControl.dealloc");
  [mainMenuControl release];

  [super dealloc];
}

- (NSString *)windowNibName {
  return @"StartWindow";
}

- (void)windowDidLoad {
  [super windowDidLoad];
  
  recentScansView.delegate = self;
  recentScansView.dataSource = self;
  recentScansView.doubleAction = @selector(repeatRecentScanAction:);

  [self setTagLineField];
}


//----------------------------------------------------------------------------
// NSTableSource

- (NSInteger) numberOfRowsInTableView:(NSTableView *)tableView {
  return [NSDocumentController sharedDocumentController].recentDocumentURLs.count;
}

- (NSView *)tableView:(NSTableView *)tableView
   viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row {
  
  NSURL *docUrl = [NSDocumentController sharedDocumentController].recentDocumentURLs[row];
  
  RecentDocumentTableCellView *cellView =
    [tableView makeViewWithIdentifier: @"RecentScanView" owner: self];

  cellView.textField.stringValue =
    [[NSFileManager defaultManager] displayNameAtPath: docUrl.path];
  cellView.imageView.image = [[NSWorkspace sharedWorkspace] iconForFile: docUrl.path];
  cellView.secondTextField.stringValue = docUrl.path;
  
  return cellView;
}

//----------------------------------------------------------------------------

- (IBAction) scanAction:(id)sender {
  [self.window close];

  [mainMenuControl scanDirectoryView: sender];
}

- (IBAction) repeatRecentScanAction:(id)sender {
  [self.window close];

  NSUInteger row = recentScansView.clickedRow;
  NSURL *docUrl = [NSDocumentController sharedDocumentController].recentDocumentURLs[row];

  [mainMenuControl scanFolder: docUrl.path];
}

- (IBAction) helpAction:(id)sender {
  [self.window close];

  [[NSApplication sharedApplication] showHelp: sender];
}

- (void) cancelOperation:(id)sender {
  [self.window close];
}

// Invoked because the controller is the delegate for the window.
- (void) windowWillClose:(NSNotification *)notification {
  [NSApp stopModal];
}

- (void) changeTagLine {
  tagLineIndex = (tagLineIndex + 1) % numTagLines;
  [self setTagLineField];
}

@end


@implementation StartWindowControl (PrivateMethods)

- (void) setTagLineField {
  NSString  *tagLineKey = [NSString stringWithFormat: TaglineFormat, tagLineIndex + 1];
  NSString  *localizedTagLine = [[NSBundle mainBundle] localizedStringForKey: tagLineKey
                                                                       value: nil
                                                                       table: TaglineTable];
  // Nil-check to avoid problems if tag lines are not properly localized
  if (localizedTagLine != nil) {
    tagLine.stringValue = localizedTagLine;
  }
}

@end // @interface StartWindowControl (PrivateMethods)

