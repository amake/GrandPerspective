#import "ProgressPanelControl.h"

#import "PreferencesPanelControl.h"


extern NSString  *NumFoldersProcessedKey;
extern NSString  *CurrentFolderPathKey;
extern NSString  *EstimatedProgressKey;


@interface ProgressPanelControl (PrivateMethods)

- (void) updatePanel;

- (void) updateProgressDetails:(NSString *)currentPath;
- (void) updateProgressSummary:(int)numProcessed;
- (void) updateProgressEstimate:(float)progressEstimate;

@end


@implementation ProgressPanelControl

// Override designated initialisers
- (instancetype) initWithWindow:(NSWindow *)window {
  NSAssert(NO, @"Use initWithTaskExecutor: instead.");
  return [self initWithTaskExecutor: nil];
}
- (instancetype) initWithCoder:(NSCoder *)coder {
  NSAssert(NO, @"Use initWithTaskExecutor: instead.");
  return [self initWithTaskExecutor: nil];
}

- (instancetype) initWithTaskExecutor:(NSObject <TaskExecutor> *)taskExecutorVal {
  if (self = [super initWithWindow: nil]) {
    taskExecutor = [taskExecutorVal retain];
    
    refreshRate = [[NSUserDefaults standardUserDefaults] floatForKey: ProgressPanelRefreshRateKey];
    if (refreshRate <= 0) {
      NSLog(@"Invalid value for progressPanelRefreshRate.");
      refreshRate = 1;
    }
  }
  
  return self;
}


- (void) dealloc {
  [taskExecutor release];

  NSAssert(cancelCallback==nil, @"cancelCallback not nil.");
  
  [super dealloc]; 
}


- (NSString *)windowNibName {
  return @"ProgressPanel";
}

- (void) windowDidLoad {
  if (@available(macOS 10.11, *)) {
    self->progressSummary.font = [NSFont monospacedDigitSystemFontOfSize: 0 weight: NSFontWeightRegular];
  }

  [self updateProgressDetails: @""];
  [self updateProgressSummary: 0];
  
  self.window.title = [self windowTitle];
}


- (NSObject <TaskExecutor> *)taskExecutor {
  return taskExecutor;
}


- (void) taskStartedWithInput:(id)taskInput
               cancelCallback:(NSObject *)callback
                     selector:(SEL)selector {
  NSAssert(cancelCallback == nil, @"Callback already set.");
  
  cancelCallback = [callback retain];
  cancelCallbackSelector = selector;

  [self.window center];
  [self.window orderFront: self];

  [self updateProgressDetails: [self pathFromTaskInput: taskInput]];
  [self updateProgressSummary: 0];
  [self updateProgressEstimate: 0];
  
  taskRunning = YES;
  [self updatePanel];
}

- (void) taskStopped {
  NSAssert(cancelCallback != nil, @"Callback already nil.");
  
  [cancelCallback release];
  cancelCallback = nil;
  
  [self.window close];

  taskRunning = NO; 
}


- (IBAction) abort:(id)sender {
  [cancelCallback performSelector: cancelCallbackSelector];
 
  // No need to invoke "taskStopped". This is the responsibility of the caller of "taskStarted".
}

@end // @implementation ProgressPanelControl


@implementation ProgressPanelControl (PrivateMethods)

- (void) updatePanel {
  if (!taskRunning) {
    return;
  }

  NSDictionary  *dict = [self progressInfo];
  if (dict != nil) {
    [self updateProgressDetails: dict[CurrentFolderPathKey]];
    [self updateProgressSummary: [dict[NumFoldersProcessedKey] intValue]];
    [self updateProgressEstimate: [dict[EstimatedProgressKey] floatValue]];
  }

  // Schedule another update 
  [self performSelector: @selector(updatePanel) withObject: 0 afterDelay: refreshRate];
}


- (void) updateProgressDetails:(NSString *)currentPath {
  progressDetails.stringValue =
    (currentPath != nil)
    ? [NSString stringWithFormat: self.progressDetailsFormat, currentPath]
    : @"";
}

- (void) updateProgressSummary:(int)numProcessed {
  progressSummary.stringValue =
    [NSString localizedStringWithFormat: self.progressSummaryFormat, numProcessed];
}

- (void) updateProgressEstimate:(float)progressEstimate {
  progressIndicator.doubleValue = progressEstimate;
}

@end // @implementation ProgressPanelControl (PrivateMethods)


