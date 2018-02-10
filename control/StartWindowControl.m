#import "StartWindowControl.h"

#import "RecentDocumentTableCellView.h"

NSString*  TaglineTable = @"Taglines";
NSString*  NumTaglines = @"num-taglines";
NSString*  TaglineFormat = @"tagline-%d";

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
  
  // Show a random tagline
  NSBundle  *mainBundle = [NSBundle mainBundle];
  int  numTaglines =
    [mainBundle localizedStringForKey: NumTaglines value: nil table: TaglineTable].intValue;
  int  taglineIndex = 1 + arc4random_uniform(numTaglines);
  NSString  *localizedTagLine =
    [mainBundle localizedStringForKey: [NSString stringWithFormat: TaglineFormat, taglineIndex]
                                value: nil
                                table: TaglineTable];
  tagLine.stringValue = localizedTagLine;
  
  recentScansView.delegate = self;
  recentScansView.dataSource = self;
  recentScansView.doubleAction = @selector(repeatRecentScanAction:);
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

- (void)cancelOperation:(id)sender {
  [self.window close];
}

// Invoked because the controller is the delegate for the window.
- (void) windowWillClose:(NSNotification *)notification {
  [NSApp stopModal];
}

@end

