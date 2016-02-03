#import "MainMenuControl.h"

#import "DirectoryItem.h"

#import "ControlConstants.h"
#import "LocalizableStrings.h"
#import "DirectoryViewControl.h"
#import "DirectoryViewControlSettings.h"
#import "SaveImageDialogControl.h"
#import "PreferencesPanelControl.h"
#import "FiltersWindowControl.h"
#import "UniformTypeRankingWindowControl.h"
#import "FilterSelectionPanelControl.h"

#import "ItemPathModel.h"
#import "ItemPathModelView.h"
#import "TreeFilter.h"
#import "TreeWriter.h"
#import "TreeReader.h"
#import "TreeContext.h"
#import "AnnotatedTreeContext.h"
#import "TreeBuilder.h"

#import "WindowManager.h"

#import "VisibleAsynchronousTaskManager.h"
#import "ScanProgressPanelControl.h"
#import "ScanTaskInput.h"
#import "ScanTaskExecutor.h"
#import "FilterProgressPanelControl.h"
#import "FilterTaskInput.h"
#import "FilterTaskExecutor.h"
#import "ReadProgressPanelControl.h"
#import "ReadTaskInput.h"
#import "ReadTaskExecutor.h"
#import "WriteProgressPanelControl.h"
#import "WriteTaskInput.h"
#import "WriteTaskExecutor.h"

#import "FilterRepository.h"
#import "FilterTestRepository.h"
#import "NamedFilter.h"
#import "FilterSet.h"
#import "Filter.h"

#import "UniformTypeRanking.h"
#import "UniformTypeInventory.h"


NSString  *RescanClosesOldWindow = @"close old window";
NSString  *RescanKeepsOldWindow = @"keep old window";
NSString  *RescanReusesOldWindow = @"reuse old window"; // Not (yet?) supported

NSString  *RescanAll = @"rescan all";
NSString  *RescanVisible = @"rescan visible";

@interface ReadTaskCallback : NSObject {
  WindowManager  *windowManager;
  ReadTaskInput  *taskInput;
}

- (id) initWithWindowManager:(WindowManager *)windowManager 
         readTaskInput:(ReadTaskInput *)taskInput;

- (void) readTaskCompleted:(TreeReader *)treeReader;

@end // @interface ReadTaskCallback


@interface WriteTaskCallback : NSObject {
  WriteTaskInput  *taskInput;
}

- (id) initWithWriteTaskInput:(WriteTaskInput *)taskInput;

- (void) writeTaskCompleted:(id) result;

@end // @interface WriteTaskCallback


@interface FreshDirViewWindowCreator : NSObject {
  WindowManager  *windowManager;
}

- (id) initWithWindowManager:(WindowManager *)windowManager;

- (void) createWindowForTree:(TreeContext *)treeContext;
- (void) createWindowForAnnotatedTree:(AnnotatedTreeContext *)annTreeContext;

- (DirectoryViewControl *)createDirectoryViewControlForAnnotatedTree: 
                            (AnnotatedTreeContext *)annTreeContext;

@end // @interface FreshDirViewWindowCreator


@interface DerivedDirViewWindowCreator : FreshDirViewWindowCreator {
  ItemPathModel  *targetPath;
  DirectoryViewControlSettings  *settings;
}

- (id) initWithWindowManager:(WindowManager *)windowManager
         targetPath:(ItemPathModel *)targetPath
         settings:(DirectoryViewControlSettings *)settings;

@end // @interface DerivedDirViewWindowCreator


@interface MainMenuControl (PrivateMethods)

- (void) autoScanTimeoutPassed;
- (void) scanFolderUsingFilter:(BOOL) useFilter;
- (void) scanFolder:(NSString *)path namedFilter:(NamedFilter *)filter;
- (void) scanFolder:(NSString *)path filterSet:(FilterSet *)filterSet;
- (void) rescanItem:(FileItem *)item 
           deriveFrom:(DirectoryViewControl *)oldControl;

- (void) loadScanDataFromFile:(NSString *)path;

- (void) duplicateCurrentWindowSharingPath:(BOOL) sharePathModel;

- (NamedFilter *)getNamedFilter:(NamedFilter *)initialFilter;

+ (NSString *)getPathFromPasteboard:(NSPasteboard *)pboard;

/* Helper method for reporting the names of unbound filters or filter tests.
 */
+ (void) reportUnbound:(NSArray *)unboundNames messageFormat:(NSString *)format
           infoText:(NSString *)infoText;

/* Creates window title based on scan location, scan time and filter (if any).
 */
+ (NSString *)windowTitleForDirectoryView:(DirectoryViewControl *)control;

@end // @interface MainMenuControl (PrivateMethods)


@implementation MainMenuControl

+ (void) initialize {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

  // Load application-defaults from the information properties file.
  NSBundle  *bundle = [NSBundle mainBundle];
      
  NSDictionary  *appDefaults = 
    [bundle objectForInfoDictionaryKey: @"GPApplicationDefaults"];

  [defaults registerDefaults: appDefaults];
  
  // Load the ranked list of uniform types and observe the inventory to ensure 
  // that it will be extended when new types are encountered (as a result of
  // scanning).
  UniformTypeRanking  *uniformTypeRanking = 
    [UniformTypeRanking defaultUniformTypeRanking];
  UniformTypeInventory  *uniformTypeInventory = 
    [UniformTypeInventory defaultUniformTypeInventory];
    
  [uniformTypeRanking loadRanking: uniformTypeInventory];

  // Observe the inventory for newly added types. Note: we do not want to
  // receive notifications about types that have been added to the
  // inventory as a result of the recent invocation of -loadRanking:. Calling 
  // -observerUniformTypeInventory: using -performSelectorOnMainThread:...
  // ensures that any pending notifications are fired before uniformTypeRanking
  // is added as an observer. 
  [uniformTypeRanking 
     performSelectorOnMainThread: @selector(observeUniformTypeInventory:)
     withObject: uniformTypeInventory waitUntilDone: NO];
}

static MainMenuControl  *singletonInstance = nil;

+ (MainMenuControl *)singletonInstance {
  return singletonInstance;
}

+ (NSArray *) rescanActionNames {
  return [NSArray arrayWithObjects: RescanAll, 
                                    RescanVisible, nil];
}

+ (NSArray *) rescanBehaviourNames {
  return [NSArray arrayWithObjects: RescanClosesOldWindow, 
                                    RescanKeepsOldWindow, nil];
}

+ (void) reportUnboundFilters:(NSArray *)unboundFilters {
  NSString  *format = 
    NSLocalizedString( @"Failed to update one or more filters:\n%@", 
                       @"Alert message" );
  NSString  *infoText = 
    NSLocalizedString( @"These filters do not exist anymore. Their old definition is used instead.", 
                       @"Alert informative text" );
  [self reportUnbound: unboundFilters messageFormat: format infoText: infoText];
}

+ (void) reportUnboundTests:(NSArray *)unboundTests {
  NSString  *format = 
    NSLocalizedString( @"Failed to bind one or more filter tests:\n%@", 
                       @"Alert message" );
  NSString  *infoText = 
    NSLocalizedString( @"The unbound tests have been omitted from the filter.", 
                       @"Alert informative text" );
  [self reportUnbound: unboundTests messageFormat: format infoText: infoText];
}


- (id) init {
  NSAssert(singletonInstance == nil, @"Can only create one MainMenuControl.");

  if (self = [super init]) {
    windowManager = [[WindowManager alloc] init]; 

    ProgressPanelControl  *scanProgressPanelControl = 
      [[[ScanProgressPanelControl alloc] 
           initWithTaskExecutor: [[[ScanTaskExecutor alloc] init] autorelease] 
       ] autorelease];

    scanTaskManager =
      [[VisibleAsynchronousTaskManager alloc] 
          initWithProgressPanel: scanProgressPanelControl]; 

    ProgressPanelControl  *filterProgressPanelControl = 
      [[[FilterProgressPanelControl alloc] 
           initWithTaskExecutor: [[[FilterTaskExecutor alloc] init] autorelease]
       ] autorelease];

    filterTaskManager =
      [[VisibleAsynchronousTaskManager alloc] 
          initWithProgressPanel: filterProgressPanelControl];
          
    ProgressPanelControl  *writeProgressPanelControl = 
      [[[WriteProgressPanelControl alloc] 
           initWithTaskExecutor: [[[WriteTaskExecutor alloc] init] autorelease]
       ] autorelease];

    writeTaskManager =
      [[VisibleAsynchronousTaskManager alloc] 
          initWithProgressPanel: writeProgressPanelControl];
          
    ProgressPanelControl  *readProgressPanelControl = 
      [[[ReadProgressPanelControl alloc] 
           initWithTaskExecutor: [[[ReadTaskExecutor alloc] init] autorelease]
       ] autorelease];

    readTaskManager =
      [[VisibleAsynchronousTaskManager alloc] 
          initWithProgressPanel: readProgressPanelControl];
    
    // Lazily load the optional panels and windows
    preferencesPanelControl = nil;
    filterSelectionPanelControl = nil;
    filtersWindowControl = nil;
    uniformTypeWindowControl = nil;
    
    scanAfterLaunch = YES; // Default
  }
  
  singletonInstance = self;
  
  return self;
}

- (void) dealloc {
  singletonInstance = nil;

  [windowManager release];
  
  [scanTaskManager dispose];
  [scanTaskManager release];

  [filterTaskManager dispose];
  [filterTaskManager release];
  
  [writeTaskManager dispose];
  [writeTaskManager release];

  [readTaskManager dispose];
  [readTaskManager release];
  
  [preferencesPanelControl release];
  [filterSelectionPanelControl release];
  [filtersWindowControl release];
  [uniformTypeWindowControl release];
  
  [super dealloc];
}

- (BOOL) application:(NSApplication *)theApplication 
           openFile:(NSString *)filename {
  if ([TreeBuilder pathIsDirectory:filename]) {
    [self scanFolder: filename namedFilter: nil];
    scanAfterLaunch = NO;
  }
  else if ([[[filename pathExtension] lowercaseString] 
                isEqualToString: @"gpscan"]) {
    [self loadScanDataFromFile: filename];
    scanAfterLaunch = NO;
  }
  // Loading is done asynchronously, so always assume it succeeds here
  return YES;
}

- (void) applicationDidFinishLaunching:(NSNotification *)notification {
  [NSApp setServicesProvider: self];
  
  if (scanAfterLaunch) {
    NSTimeInterval delay = [[NSUserDefaults standardUserDefaults] 
                              floatForKey: DelayBeforeAutomaticScanAfterStartupKey];
    if (delay == 0) {
      [self scanDirectoryView: self];
    } else if (delay > 0) {
      // Set a watchdog. If it times out before service activity is detected, pop-up scan dialog.
      [NSTimer 
         scheduledTimerWithTimeInterval: delay
         target: self 
         selector: @selector(autoScanTimeoutPassed) 
         userInfo: nil 
         repeats: NO];
    }
  }
}

- (void) applicationWillTerminate:(NSNotification *)notification {
  [[FilterRepository defaultInstance] storeUserCreatedFilters];
  [[FilterTestRepository defaultInstance] storeUserCreatedTests];
       
  [[UniformTypeRanking defaultUniformTypeRanking] storeRanking];
       
  [self release];
}


// Service method for handling dock drags.
- (void)scanFolder:(NSPasteboard *)pboard 
          userData:(NSString *)userData
          error:(NSString **)error {
  NSLog(@"scanFolder:userData:error:");
  scanAfterLaunch = NO; // Do not automatically pop-up scan dialog

  NSString  *path = [MainMenuControl getPathFromPasteboard: pboard];
  if (path == nil) {
    *error = NSLocalizedString( @"Failed to get path from pasteboard.",
                                @"Error message" );
    NSLog(@"%@", *error); // Also logging. Setting *error does not seem to work?
    return;
  }
  
  if (! [TreeBuilder pathIsDirectory: path]) {
    *error = NSLocalizedString( @"Expected a folder.",
                                @"Error message" );
    NSLog(@"%@", *error); // Also logging. Setting *error does not seem to work?
    return;
  }
  
  [self scanFolder: path namedFilter: nil];
}


// Service method for handling dock drags.
- (void)loadScanData:(NSPasteboard *)pboard 
          userData:(NSString *)userData
          error:(NSString **)error {
  NSLog(@"loadScanData:userData:error:");
  scanAfterLaunch = NO; // Do not automatically pop-up scan dialog

  NSString  *path = [MainMenuControl getPathFromPasteboard: pboard];
  if (path == nil) {
    *error = NSLocalizedString( @"Failed to get path from pasteboard.",
                                @"Error message" );
    NSLog(@"%@", *error); // Also logging. Setting *error does not seem to work?
    return;
  }
  
  if (! [[[path pathExtension] lowercaseString] isEqualToString: @"gpscan"]) {
    *error = NSLocalizedString( @"Expected scandata file.",
                                @"Error message" );
    NSLog(@"%@", *error); // Also logging. Setting *error does not seem to work?
    return;
  }
  
  [self loadScanDataFromFile: path];
}


- (BOOL) validateMenuItem:(NSMenuItem *)item {
  SEL  action = [item action];

  if ( action == @selector(toggleToolbarShown:) ) {
    NSWindow  *window = [[NSApplication sharedApplication] mainWindow];

    if (window == nil) {
      return NO;
    }
    [item setTitle:
       [[window toolbar] isVisible]
       ? NSLocalizedStringFromTable(@"Hide Toolbar", @"Toolbar", @"Menu item")
       : NSLocalizedStringFromTable(@"Show Toolbar", @"Toolbar", @"Menu item")];

    return YES;
  }

  if ( action == @selector(duplicateDirectoryView:) ||
       action == @selector(twinDirectoryView:)  ||

       action == @selector(customizeToolbar:) || 
       
       action == @selector(saveScanData:) ||
       action == @selector(saveDirectoryViewImage:) ||
       action == @selector(rescan:) ||
       action == @selector(filterDirectoryView:) ) {
    return ([[NSApplication sharedApplication] mainWindow] != nil);
  }
  
  return YES;
}


- (IBAction) scanDirectoryView:(id) sender {
  [self scanFolderUsingFilter: NO];
}

- (IBAction) scanFilteredDirectoryView:(id) sender {
  [self scanFolderUsingFilter: YES];
}


- (IBAction) rescan:(id) sender {
  NSUserDefaults  *userDefaults = [NSUserDefaults standardUserDefaults];
  NSString  *rescanAction = [userDefaults stringForKey: DefaultRescanActionKey];
  if ([rescanAction isEqualToString: RescanAll]) {
    [self rescanAll: sender];
  }
  else if ([rescanAction isEqualToString: RescanVisible]) {
    [self rescanVisible: sender];
  }
  else {
    NSLog(@"Unrecognized rescan action: %@", rescanAction);
  }
}

- (IBAction) rescanAll:(id) sender {
  DirectoryViewControl  *oldControl = 
    [[[NSApplication sharedApplication] mainWindow] windowController];
  if (oldControl == nil) {
    return;
  }

  NSUserDefaults  *userDefaults = [NSUserDefaults standardUserDefaults];
  NSString  *rescanBehaviour = [userDefaults stringForKey: RescanBehaviourKey];
  if ([rescanBehaviour isEqualToString: RescanClosesOldWindow]) {
    [[oldControl window] close];
  }
  
  TreeContext  *oldContext = [oldControl treeContext];
  [self rescanItem: [oldContext scanTree] deriveFrom: oldControl];
}

- (IBAction) rescanVisible:(id) sender {
  DirectoryViewControl  *oldControl = 
    [[[NSApplication sharedApplication] mainWindow] windowController];
  if (oldControl == nil) {
    return;
  }
  
  ItemPathModelView  *pathModelView = [oldControl pathModelView];
  [self rescanItem: [pathModelView visibleTree] deriveFrom: oldControl];
}

- (IBAction) rescanSelected:(id) sender {
  DirectoryViewControl  *oldControl = 
    [[[NSApplication sharedApplication] mainWindow] windowController];
  if (oldControl == nil) {
    return;
  }
  
  ItemPathModelView  *pathModelView = [oldControl pathModelView];
  [self rescanItem: [pathModelView selectedFileItem] deriveFrom: oldControl];  
}


- (IBAction) filterDirectoryView:(id) sender {
  DirectoryViewControl  *oldControl = 
    [[[NSApplication sharedApplication] mainWindow] windowController];

  NamedFilter  *namedFilter = [self getNamedFilter: [oldControl namedMask]];
  if (namedFilter == nil) {
    return;
  }
  
  Filter  *filter = [namedFilter filter];
  FileItemTest  *filterTest =
    [filter createFileItemTestFromRepository:
              [FilterTestRepository defaultInstance]];
  if (filterTest == nil) {
    NSLog(@"Filter test of new filter is nil.");
    return;
  }
  
  FilterSet  *filterSet = 
    [[[oldControl treeContext] filterSet]
         filterSetWithAddedNamedFilter: namedFilter];
      
  ItemPathModel  *pathModel = [[oldControl pathModelView] pathModel];
  DirectoryViewControlSettings  *settings = 
    [oldControl directoryViewControlSettings];
  if ([[namedFilter name] isEqualToString: [settings maskName]]) {
    // Don't retain the mask if it has the filter has the same name. It is
    // likely that the filter is the same as the mask, or if not, is at least
    // a modified version of it. It therefore does not make sense to retain
    // the mask. This is only confusing.
    [settings setMaskName: nil];
  }

  DerivedDirViewWindowCreator  *windowCreator =
    [[[DerivedDirViewWindowCreator alloc] 
         initWithWindowManager: windowManager 
           targetPath: pathModel 
           settings: settings]
         autorelease];

  FilterTaskInput  *input = 
    [[[FilterTaskInput alloc] 
         initWithTreeContext: [oldControl treeContext]
           filterSet: filterSet
           packagesAsFiles: ! [settings showPackageContents]]
         autorelease];

  [filterTaskManager asynchronouslyRunTaskWithInput: input
                       callback: windowCreator
                       selector: @selector(createWindowForTree:)];
}


- (IBAction) duplicateDirectoryView:(id) sender {
  [self duplicateCurrentWindowSharingPath: NO];
}

- (IBAction) twinDirectoryView:(id) sender {
  [self duplicateCurrentWindowSharingPath: YES];
}


- (IBAction) saveScanData:(id) sender {
  DirectoryViewControl  *dirViewControl = 
    [[[NSApplication sharedApplication] mainWindow] windowController];
    
  NSSavePanel  *savePanel = [NSSavePanel savePanel]; 
  [savePanel setAllowedFileTypes: [NSArray arrayWithObject: @"gpscan"]];
  [savePanel setTitle: 
     NSLocalizedString( @"Save scan data", @"Title of save panel") ];
  
  if ([savePanel runModal] == NSModalResponseOK) {
    NSURL  *destURL = [savePanel URL];
    
    if ([destURL isFileURL]) {
      WriteTaskInput  *input = 
        [[[WriteTaskInput alloc] 
             initWithAnnotatedTreeContext: [dirViewControl annotatedTreeContext] 
                                     path: [destURL path]] 
         autorelease];
           
      WriteTaskCallback  *callback = 
        [[[WriteTaskCallback alloc] initWithWriteTaskInput: input] autorelease];
    
      [writeTaskManager asynchronouslyRunTaskWithInput: input
                                              callback: callback
                                              selector: @selector(writeTaskCompleted:)];
    } else {
      NSLog(@"Destination '%@' is not a file?", destURL);
    }
  }
}


- (IBAction) loadScanData:(id) sender {
  DirectoryViewControl  *dirViewControl = 
    [[[NSApplication sharedApplication] mainWindow] windowController];
    
  NSOpenPanel  *openPanel = [NSOpenPanel openPanel];
  [openPanel setAllowedFileTypes: 
               [NSArray arrayWithObjects: @"xml", @"gpscan", nil]];

  [openPanel setTitle: 
     NSLocalizedString( @"Load scan data", @"Title of load panel") ];
  
  if ([openPanel runModal] == NSModalResponseOK) {
    NSURL  *sourceURL = [openPanel URL];
    if ([sourceURL isFileURL]) {
      [self loadScanDataFromFile: [sourceURL path]];
    } else {
      NSLog(@"Source '%@' is not a file?", sourceURL); 
    }
  }
}


- (IBAction) saveDirectoryViewImage:(id) sender {
  DirectoryViewControl  *dirViewControl = 
    [[[NSApplication sharedApplication] mainWindow] windowController];

  // Dialog auto-disposes when its job is done.
  SaveImageDialogControl  *saveImageDialogControl = 
    [[SaveImageDialogControl alloc] 
        initWithDirectoryViewControl: dirViewControl];
}

- (IBAction) editPreferences:(id) sender {
  if (preferencesPanelControl == nil) {
    // Lazily create the panel
    preferencesPanelControl = [[PreferencesPanelControl alloc] init];
    
    [[preferencesPanelControl window] center];
  }

  [[preferencesPanelControl window] makeKeyAndOrderFront: self];
}

- (IBAction) editFilters:(id) sender {
  if (filtersWindowControl == nil) {
    // Lazily create the window
    filtersWindowControl = [[FiltersWindowControl alloc] init];

    // Initially center it, subsequently keep position as chosen by user
    [[filtersWindowControl window] center];
  }
  
  [[filtersWindowControl window] makeKeyAndOrderFront: self];
}

- (IBAction) editUniformTypeRanking: (id) sender {
  if (uniformTypeWindowControl == nil) {
    // Lazily construct the window
    uniformTypeWindowControl = 
      [[UniformTypeRankingWindowControl alloc] init];
  }
  
  // [uniformTypeWindowControl refreshTypeList];
  [[uniformTypeWindowControl window] makeKeyAndOrderFront: self];
}


- (IBAction) toggleToolbarShown:(id) sender {
  [[[NSApplication sharedApplication] mainWindow] toggleToolbarShown: sender];
}

- (IBAction) customizeToolbar:(id) sender {
  [[[NSApplication sharedApplication] mainWindow] 
       runToolbarCustomizationPalette: sender];
}


- (IBAction) openWebsite:(id) sender {
  NSBundle  *bundle = [NSBundle mainBundle];

  NSURL  *url = [NSURL URLWithString: 
                   [bundle objectForInfoDictionaryKey: @"GPWebsiteURL"]];

  [[NSWorkspace sharedWorkspace] openURL: url];
}

@end // @implementation MainMenuControl


@implementation MainMenuControl (PrivateMethods)

- (void) autoScanTimeoutPassed {
  if (scanAfterLaunch) {
    // During initial delay after start-up no service invocation was received. Assume that 
    // application was started normally and pop-up scan dialog. This works okay as long as the
    // time-out is long enough that service invocations happen before it, but short enough for
    // user to have initiated any interaction.
    [self scanDirectoryView: self];
  }
}
       
- (void) scanFolderUsingFilter:(BOOL) useFilter {
  NSOpenPanel  *openPanel = [NSOpenPanel openPanel];
  [openPanel setCanChooseFiles: NO];
  [openPanel setCanChooseDirectories: YES];
  [openPanel setAllowsMultipleSelection: NO];
  
  NSUserDefaults  *userDefaults = [NSUserDefaults standardUserDefaults];
  [openPanel setTreatsFilePackagesAsDirectories: 
               [userDefaults boolForKey: ShowPackageContentsByDefaultKey]];
  
  [openPanel setTitle: NSLocalizedString(@"Scan folder", 
                                         @"Title of open panel") ];
  [openPanel setPrompt: NSLocalizedString(@"Scan", @"Prompt in open panel") ];

  if ([openPanel runModal] != NSModalResponseOK) {
    return; // Abort
  } 

  NSURL  *targetURL = [openPanel URL];
  if (! [targetURL isFileURL]) {
    NSLog(@"URL '%@' is not a file?", targetURL);
    return;
  }
  NamedFilter  *namedFilter = nil;
  if (useFilter) {
    namedFilter = [self getNamedFilter: nil];

    // Copy the filter, so that its test can be reinstantiated (it may already
    // have been instantiated)
    Filter  *filter = [Filter filterWithFilter: [namedFilter filter]];
    
    // Instantiate the test
    [filter createFileItemTestFromRepository: 
              [FilterTestRepository defaultInstance]];

    // Use the updated filter instead
    namedFilter = [NamedFilter namedFilter: filter name: [namedFilter name]];
  }

  [self scanFolder: [targetURL path] namedFilter: namedFilter];
}

- (void) scanFolder:(NSString *)path namedFilter:(NamedFilter *)namedFilter {
  NSAssert(namedFilter==nil || [[namedFilter filter] fileItemTest] != nil, 
           @"Filter must be nil or instantiated.");
  FilterSet  *filterSet =
    (namedFilter != nil) 
       ? [FilterSet filterSetWithNamedFilter: namedFilter] : nil;

  [self scanFolder: path filterSet: filterSet];
}

- (void) scanFolder:(NSString *)path filterSet:(FilterSet *)filterSet {
  NSString  *fileSizeMeasure =
    [[NSUserDefaults standardUserDefaults] stringForKey: FileSizeMeasureKey];

  FreshDirViewWindowCreator  *windowCreator =
    [[[FreshDirViewWindowCreator alloc] initWithWindowManager: windowManager]
         autorelease];
  ScanTaskInput  *input = 
    [[[ScanTaskInput alloc] initWithPath: path
                              fileSizeMeasure: fileSizeMeasure 
                              filterSet: filterSet] 
         autorelease];
    
  [scanTaskManager asynchronouslyRunTaskWithInput: input
                     callback: windowCreator
                     selector: @selector(createWindowForTree:)];
}

/* Used to implement various Rescan commands. The new view is derived from the
 * current/old control, and its settings are matched as much as possible.
 */
- (void) rescanItem:(FileItem *)item 
           deriveFrom:(DirectoryViewControl *)oldControl {
  // Make sure to always scan a directory.
  if (![item isDirectory]) {
    item = [item parentDirectory];
  }
           
  TreeContext  *oldContext = [oldControl treeContext];
  ItemPathModel  *pathModel = [[oldControl pathModelView] pathModel];
    
  DerivedDirViewWindowCreator  *windowCreator =
    [[[DerivedDirViewWindowCreator alloc] 
         initWithWindowManager: windowManager
           targetPath: pathModel
           settings: [oldControl directoryViewControlSettings]]
         autorelease];

  FilterSet  *filterSet = [oldContext filterSet];
  NSUserDefaults  *userDefaults = [NSUserDefaults standardUserDefaults];
  if ([userDefaults boolForKey: UpdateFiltersBeforeUse]) {
    NSMutableArray  *unboundFilters = [NSMutableArray arrayWithCapacity: 8];
    NSMutableArray  *unboundTests = [NSMutableArray arrayWithCapacity: 8];
    filterSet = [filterSet updatedFilterSetUnboundFilters: unboundFilters
                             unboundTests: unboundTests];
    [MainMenuControl reportUnboundFilters: unboundFilters];
    [MainMenuControl reportUnboundTests: unboundTests];
  }
  
  ScanTaskInput  *input = 
    [[[ScanTaskInput alloc] 
         initWithPath: [item systemPath]
           fileSizeMeasure: [oldContext fileSizeMeasure]
           filterSet: filterSet]
         autorelease];
    
  [scanTaskManager asynchronouslyRunTaskWithInput: input
                     callback: windowCreator
                     selector: @selector(createWindowForTree:)];
}


- (void) loadScanDataFromFile:(NSString *)path {
  ReadTaskInput  *input = 
    [[[ReadTaskInput alloc] initWithPath: path] autorelease];

  ReadTaskCallback  *callback = 
    [[[ReadTaskCallback alloc] 
         initWithWindowManager: windowManager readTaskInput: input] 
         autorelease];
    
  [readTaskManager asynchronouslyRunTaskWithInput: input
                      callback: callback
                      selector: @selector(readTaskCompleted:)];
}


- (void) duplicateCurrentWindowSharingPath:(BOOL) sharePathModel {
  DirectoryViewControl  *oldControl = 
    [[[NSApplication sharedApplication] mainWindow] windowController];

  // Share or clone the path model.
  ItemPathModel  *pathModel = [[oldControl pathModelView] pathModel];

  if (!sharePathModel) {
    pathModel = [[pathModel copy] autorelease];
  }

  DirectoryViewControl  *newControl = 
    [[DirectoryViewControl alloc] 
        initWithAnnotatedTreeContext: [oldControl annotatedTreeContext]
          pathModel: pathModel
          settings: [oldControl directoryViewControlSettings]];
  // Note: The control should auto-release itself when its window closes
    
  // Force loading (and showing) of the window.
  [windowManager addWindow: [newControl window] 
                   usingTitle: [[oldControl window] title]];
}


- (NamedFilter *)getNamedFilter:(NamedFilter *)initialFilter {
  if (filterSelectionPanelControl == nil) {
    filterSelectionPanelControl = [[FilterSelectionPanelControl alloc] init];
  }

  if (initialFilter != nil) {
    [filterSelectionPanelControl selectFilterNamed: [initialFilter name]];
  }
  
  NSWindow  *selectFilterWindow = [filterSelectionPanelControl window];
  int  status = [NSApp runModalForWindow: selectFilterWindow];
  [selectFilterWindow close];
  
  if (status == NSModalResponseStop) {
    return [filterSelectionPanelControl selectedNamedFilter];
  }
  return nil;
}


+ (NSString *)getPathFromPasteboard:(NSPasteboard *)pboard {
  NSArray *supportedTypes =
    [NSArray arrayWithObjects: NSFilenamesPboardType, NSStringPboardType, nil];
    
  NSString  *bestType = [pboard availableTypeFromArray: supportedTypes];
  if (bestType == nil) {
    return nil;
  }

  if ([bestType isEqualToString: NSFilenamesPboardType]) {
    NSArray  *files = [pboard propertyListForType: NSFilenamesPboardType];
    if ([files count] < 1) {
      return nil;
    }
    return [files objectAtIndex: 0];
  }
  else if ([bestType isEqualToString: NSStringPboardType]) {
    return [pboard stringForType: NSStringPboardType];
  }
  return nil;
}


+ (void) reportUnbound:(NSArray *)unboundNames messageFormat:(NSString *)format
           infoText:(NSString *)infoText {
  if ([unboundNames count] == 0) {
    // No unbound items. Nothing to report.
    return;
  }

  NSAlert *alert = [[[NSAlert alloc] init] autorelease];

  // Quote the names
  NSMutableArray  *quotedNames =
    [NSMutableArray arrayWithCapacity: [unboundNames count]];
  NSEnumerator  *nameEnum = [unboundNames objectEnumerator];
  NSString  *name;
  while (name = [nameEnum nextObject]) {
    [quotedNames addObject: [NSString stringWithFormat: @"\"%@\"", name]];
  }
    
  NSString  *nameList =
    [LocalizableStrings localizedAndEnumerationString: quotedNames]; 

  [alert addButtonWithTitle: OK_BUTTON_TITLE];
  [alert setMessageText: [NSString stringWithFormat: format, nameList]];
  [alert setInformativeText: infoText];

  [alert runModal];
}


+ (NSString *)windowTitleForDirectoryView:(DirectoryViewControl *)control {
  TreeContext  *treeContext = [control treeContext];
  NSString  *scanPath = [[treeContext scanTree] path];

  NSString  *scanTimeString = [treeContext stringForScanTime]; 
  FilterSet  *filterSet = [treeContext filterSet];

  if ([filterSet numFilters] == 0) {
    return [NSString stringWithFormat: @"%@ - %@", 
                                         scanPath, scanTimeString];
  }
  else {
    return [NSString stringWithFormat: @"%@ - %@ - %@", 
                                         scanPath, scanTimeString,
                                         [filterSet description] ];
  }
}

@end // @implementation MainMenuControl (PrivateMethods)


@implementation ReadTaskCallback

// Overrides designated initialiser
- (id) init {
  NSAssert(NO, @"Use initWithReadTaskInput: instead.");
}

- (id) initWithWindowManager:(WindowManager *)windowManagerVal 
         readTaskInput:(ReadTaskInput *)taskInputVal {
  if (self = [super init]) {
    windowManager = [windowManagerVal retain];
    taskInput = [taskInputVal retain];
  }
  
  return self;
}

- (void) dealloc {
  [windowManager release];
  [taskInput release];

  [super dealloc];
}


- (void) readTaskCompleted:(TreeReader *) treeReader {
  if ([treeReader aborted]) {
    // Reading was aborted. Silently ignore.
    return;
  }
  else if ([treeReader error]) {
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];

    NSString  *format = 
      NSLocalizedString( @"Failed to load the scan data from \"%@\"", 
                         @"Alert message (with filename arg)" );

    [alert addButtonWithTitle: OK_BUTTON_TITLE];
    [alert setMessageText: 
             [NSString stringWithFormat: format, 
                                         [[taskInput path] lastPathComponent]]];
    [alert setInformativeText: [[treeReader error] localizedDescription]];

    [alert runModal];
  }
  else {
    AnnotatedTreeContext  *tree = [treeReader annotatedTreeContext];
    NSAssert(tree != nil, @"Unexpected state.");
    
    [MainMenuControl reportUnboundTests: [treeReader unboundFilterTests]];
    
    FreshDirViewWindowCreator  *windowCreator =
      [[[FreshDirViewWindowCreator alloc] 
           initWithWindowManager: windowManager] autorelease];
      
    [windowCreator createWindowForAnnotatedTree: tree];
  }
}

@end // @interface ReadTaskCallback


@implementation WriteTaskCallback

// Overrides designated initialiser
- (id) init {
  NSAssert(NO, @"Use initWithWriteTaskInput: instead.");
}

- (id) initWithWriteTaskInput:(WriteTaskInput *)taskInputVal {
  if (self = [super init]) {
    taskInput = [taskInputVal retain];
  }
  
  return self;
}

- (void) dealloc {
  [taskInput release];

  [super dealloc];
}


- (void) writeTaskCompleted:(id) result {
  NSAlert  *alert = [[[NSAlert alloc] init] autorelease];
  NSString  *msgFormat = nil;

  if (result == SuccessfulVoidResult) {
    [alert setAlertStyle:  NSInformationalAlertStyle];
    
    msgFormat = 
      NSLocalizedString( @"Successfully saved the scan data to \"%@\"", 
                         @"Alert message (with filename arg)" );
  }
  else if (result == nil) {
    // Writing was aborted
    msgFormat = NSLocalizedString( @"Aborted saving the scan data to \"%@\"", 
                                   @"Alert message (with filename arg)" );
    [alert setInformativeText: 
       NSLocalizedString( @"The resulting file is valid but incomplete.", 
                          @"Alert informative text" )];
  }
  else {
    // An error occured while writing
    msgFormat = NSLocalizedString( @"Failed to save the scan data to \"%@\"", 
                                   @"Alert message (with filename arg)" );
    [alert setInformativeText: [((NSError *)result) localizedDescription]]; 
  }

  [alert setMessageText: 
           [NSString stringWithFormat: msgFormat, 
                                       [[taskInput path] lastPathComponent]]];
  
  [alert addButtonWithTitle: OK_BUTTON_TITLE];
  [alert runModal];
}

@end // @interface WriteTaskCallback


@implementation FreshDirViewWindowCreator

// Overrides designated initialiser.
- (id) init {
  NSAssert(NO, @"Use initWithWindowManager: instead.");
}

- (id) initWithWindowManager:(WindowManager *)windowManagerVal {
  if (self = [super init]) {
    windowManager = [windowManagerVal retain];
  }
  return self;
}

- (void) dealloc {
  [windowManager release];
  
  [super dealloc];
}


- (void) createWindowForTree:(TreeContext *)treeContext {
  [self createWindowForAnnotatedTree: 
          [AnnotatedTreeContext annotatedTreeContext: treeContext]]; 
}

- (void) createWindowForAnnotatedTree:(AnnotatedTreeContext *)annTreeContext {
  if (annTreeContext == nil) {
    // Reading failed or cancelled. Don't create a window.
    return;
  }

  // Note: The control should auto-release itself when its window closes 
  DirectoryViewControl  *dirViewControl = 
    [[self createDirectoryViewControlForAnnotatedTree: annTreeContext] retain];
  
  NSString  *title = 
    [MainMenuControl windowTitleForDirectoryView: dirViewControl];
  
  // Force loading (and showing) of the window.
  [windowManager addWindow: [dirViewControl window] usingTitle: title];
}

- (DirectoryViewControl *) createDirectoryViewControlForAnnotatedTree:
                             (AnnotatedTreeContext *)annTreeContext {
  return [[[DirectoryViewControl alloc] 
              initWithAnnotatedTreeContext: annTreeContext] autorelease];
}

@end // @implementation FreshDirViewWindowCreator


@implementation DerivedDirViewWindowCreator

// Overrides designated initialiser.
- (id) initWithWindowManager:(WindowManager *)windowManagerVal {
  NSAssert(NO, 
    @"Use initWithWindowManager:targetPath:settings instead.");
}

- (id) initWithWindowManager:(WindowManager *)windowManagerVal
         targetPath:(ItemPathModel *)targetPathVal
         settings:(DirectoryViewControlSettings *)settingsVal {
         
  if (self = [super initWithWindowManager: windowManagerVal]) {
    targetPath = [targetPathVal retain];
    // Note: The state of "targetPath" may change during scanning/filtering 
    // (which happens in the background). This is okay and even desired. When 
    // the callback occurs the path in the new window will match the current
    // path in the original window.
     
    settings = [settingsVal retain];
  }
  return self;
}

- (void) dealloc {
  [targetPath release];
  [settings release];
  
  [super dealloc];
}


- (DirectoryViewControl *)createDirectoryViewControlForAnnotatedTree:
                            (AnnotatedTreeContext *)annTreeContext {
  // Try to match the subjectPath to the targetPath
  ItemPathModel  *subjectPath = 
    [ItemPathModel pathWithTreeContext: [annTreeContext treeContext]];

  [subjectPath suppressVisibleTreeChangedNotifications: YES];

  NSEnumerator  *fileItemEnum = [[targetPath fileItemPath] objectEnumerator];
  FileItem  *targetItem;
  FileItem  *itemToSelect = nil;

  BOOL  insideTargetScanTree = NO;
  BOOL  insideSubjectScanTree = NO;
  BOOL  insideVisibleTree = NO;
  BOOL  hasVisibleItems = NO;
  
  NSString  *subjectScanTreePath = [[subjectPath scanTree] path];
  
  while (targetItem = [fileItemEnum nextObject]) {
    if (insideSubjectScanTree) {
      // Only try to extend the visible path once we are inside the subject's 
      // scan tree, as this is where the path starts. (Also, we need to be in
      // the target's scan tree as well, but this is implied). 
      if ( [subjectPath extendVisiblePathToSimilarFileItem: targetItem] ) {
        if (! insideVisibleTree) {
          [subjectPath moveVisibleTreeDown];
        }
        else {
          hasVisibleItems = YES;
        }
      }
      else {
        // Failure to match, so should stop matching remainder of path.
        break;
      }
    }
    if (itemToSelect == nil && targetItem == [targetPath selectedFileItem]) {
      // Found the selected item. It is the path's current end point. 
      itemToSelect = [subjectPath lastFileItem];
    }
    if (!insideVisibleTree && targetItem == [targetPath visibleTree]) {
      // The remainder of this path can remain visible.
      insideVisibleTree = YES;
    }
    if (!insideTargetScanTree && targetItem == [targetPath scanTree]) {
      insideTargetScanTree = YES;
    }
    if (insideTargetScanTree && 
        [[targetItem path] isEqualToString: subjectScanTreePath]) {
      // We can now start extending "subjectPath" to match "targetPath". 
      insideSubjectScanTree = YES;
    }
  }

  if (hasVisibleItems) {
    [subjectPath setVisiblePathLocking: YES];
  }
  
  if (itemToSelect != nil) {
    // Match the selection to that of the original path. 
    [subjectPath selectFileItem: itemToSelect];
  }
  else {
    // Did not manage to match the new path all the way up to the selected
    // item in the original path. The selected item of the new path can 
    // therefore be set to the path endpoint (as that is the closest it can 
    // come to matching the old selection).
    [subjectPath selectFileItem: [subjectPath lastFileItem]];
  }
        
  [subjectPath suppressVisibleTreeChangedNotifications: NO];

  return [[[DirectoryViewControl alloc] 
             initWithAnnotatedTreeContext: annTreeContext
               pathModel: subjectPath 
               settings: settings] autorelease];
}

@end // @implementation DerivedDirViewWindowCreator
