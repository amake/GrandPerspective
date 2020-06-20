#import "StartWindowControl.h"

#import "NSURL.h"
#import "RecentDocumentTableCellView.h"

NSString*  TaglineTable = @"Taglines";
NSString*  NumTaglines = @"num-taglines";
NSString*  TaglineFormat = @"tagline-%d";

@interface StartWindowControl (PrivateMethods)

- (void) setTagLineField;
- (void) startScan:(NSInteger)selectedRow sender:(id)sender;

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

    forceReloadOnShow = NO;
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
  recentScansView.doubleAction = @selector(scanActionAfterDoubleClick:);

  [recentScansView registerForDraggedTypes: NSURL.supportedPasteboardTypes];

  [self setTagLineField];
}


//----------------------------------------------------------------------------
// NSTableSource

- (NSInteger) numberOfRowsInTableView:(NSTableView *)tableView {
  return [NSDocumentController sharedDocumentController].recentDocumentURLs.count + 1;
}

- (NSView *)tableView:(NSTableView *)tableView
   viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row {
  
  RecentDocumentTableCellView *cellView =
    [tableView makeViewWithIdentifier: @"RecentScanView" owner: self];

  NSInteger  numRecent = [NSDocumentController sharedDocumentController].recentDocumentURLs.count;

  if (row < numRecent) {
    NSURL *docUrl = [NSDocumentController sharedDocumentController].recentDocumentURLs[row];

    cellView.textField.stringValue =
      [[NSFileManager defaultManager] displayNameAtPath: docUrl.path];
    cellView.imageView.image = [[NSWorkspace sharedWorkspace] iconForFile: docUrl.path];
    cellView.secondTextField.stringValue = docUrl.path;
  } else {
    NSString  *msg = ((numRecent > 0) ?
                      NSLocalizedString(@"Select Other Folder",
                                        @"Entry in Start window, alongside other options") :
                      NSLocalizedString(@"Select Folder", @"Solitairy entry in Start window"));

    cellView.textField.stringValue = msg;
    cellView.secondTextField.stringValue = @"...";
  }

  return cellView;
}

- (NSDragOperation) tableView:(NSTableView *)tableView
                 validateDrop:(id <NSDraggingInfo>)info
                  proposedRow:(NSInteger)row
        proposedDropOperation:(NSTableViewDropOperation)op {

  NSURL *filePathURL = [NSURL getFileURLFromPasteboard: info.draggingPasteboard];
  //NSLog(@"Drop request with %@", filePathURL);

  if ([filePathURL isDirectory]) {
    return NSDragOperationGeneric;
  }

  return NSDragOperationNone;
}

- (BOOL) tableView:(NSTableView *)tableView
        acceptDrop:(id <NSDraggingInfo>)info
               row:(NSInteger)row
     dropOperation:(NSTableViewDropOperation)op {

  NSURL *filePathURL = [NSURL getFileURLFromPasteboard: info.draggingPasteboard];
  //NSLog(@"Accepting drop request with %@", filePathURL);

  [mainMenuControl scanFolder: filePathURL.path];

  return YES;
}

//----------------------------------------------------------------------------

- (IBAction) scanAction:(id)sender {
  [self startScan: recentScansView.selectedRow sender: sender];
}

- (IBAction) scanActionAfterDoubleClick:(id)sender {
  [self startScan: recentScansView.clickedRow sender: sender];
}

- (IBAction) clearRecentScans:(id)sender {
  [[NSDocumentController sharedDocumentController] clearRecentDocuments: sender];

  [recentScansView reloadData];
  clearHistoryButton.enabled = false;
}

- (IBAction) helpAction:(id)sender {
  [self.window close];

  [[NSApplication sharedApplication] showHelp: sender];
}

- (void) cancelOperation:(id)sender {
  [self.window close];
}

- (void) showWindow:(id)sender {
  // Except when the window is first shown, always reload the data as the number and order of recent
  // documents may have changed.
  if (forceReloadOnShow) {
    [recentScansView reloadData];
  } else {
    forceReloadOnShow = YES;
  }

  clearHistoryButton.enabled =
    [NSDocumentController sharedDocumentController].recentDocumentURLs.count > 0;

  [super showWindow: sender];
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

- (void) startScan:(NSInteger)selectedRow sender:(id)sender {
  [self.window close];

  NSDocumentController  *controller = [NSDocumentController sharedDocumentController];

  if (selectedRow >= 0 && selectedRow < controller.recentDocumentURLs.count) {
    // Scan selected folder
    NSURL *docUrl = controller.recentDocumentURLs[selectedRow];

    [mainMenuControl scanFolder: docUrl.path];
  } else {
    // Let user select the folder to scan
    [mainMenuControl scanDirectoryView: sender];
  }
}

@end // @interface StartWindowControl (PrivateMethods)

