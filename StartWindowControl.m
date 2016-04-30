#import "StartWindowControl.h"

#import "RecentDocumentTableCellView.h"

@implementation StartWindowControl

- (id) initWithMainMenuControl:(MainMenuControl *)mainMenuControlVal {
  if (self = [super initWithWindowNibName: @"StartWindow"
                                    owner: self]) {
    mainMenuControl = [mainMenuControlVal retain];
  }
  return self;
}

- (void) dealloc {
  NSLog(@"StartWindowControl.dealloc");
  [mainMenuControl release];

  [super dealloc];
}

- (void)windowDidLoad {
  [super windowDidLoad];
  
  NSLog(@"windowDidLoad");
  
  [recentScansView setDelegate: self];
  [recentScansView setDataSource: self];
  [recentScansView setDoubleAction: @selector(repeatRecentScanAction:)];
}


//----------------------------------------------------------------------------
// NSTableSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
  return [[[NSDocumentController sharedDocumentController] recentDocumentURLs] count];
}

- (NSView *)tableView:(NSTableView *)tableView
   viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row {
  
  NSURL *docUrl = [[[NSDocumentController sharedDocumentController] recentDocumentURLs]
                   objectAtIndex: row];
  
  RecentDocumentTableCellView *cellView =
    [tableView makeViewWithIdentifier: @"RecentScanView" owner: self];

  cellView.textField.stringValue = [[docUrl path] lastPathComponent];
  
  NSString  *fileType = [[NSWorkspace sharedWorkspace] typeOfFile:[docUrl path] error: nil];
  cellView.imageView.image = [[NSWorkspace sharedWorkspace] iconForFileType:fileType];
  cellView.secondTextField.stringValue = [docUrl path];
  
  return cellView;
}

//----------------------------------------------------------------------------

- (IBAction) scanAction:(id) sender {
  [[self window] close];

  [mainMenuControl scanDirectoryView: sender];
}

- (IBAction) repeatRecentScanAction:(id) sender {
  [[self window] close];

  int row = [recentScansView clickedRow];
  NSURL *docUrl = [[[NSDocumentController sharedDocumentController] recentDocumentURLs]
                   objectAtIndex: row];

  [mainMenuControl scanFolder: [docUrl path]];
}

- (IBAction) helpAction:(id) sender {
  [[self window] close];

  [[NSApplication sharedApplication] showHelp: sender];
}

// Invoked because the controller is the delegate for the window.
- (void) windowWillClose:(NSNotification *)notification {
  [NSApp stopModal];
}

@end

