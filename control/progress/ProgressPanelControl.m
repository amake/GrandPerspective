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

- (instancetype) init {
  NSAssert(NO, @"Use initWithTaskExecutor: instead.");
  return nil;
}

- (instancetype) initWithTaskExecutor:(NSObject <TaskExecutor> *)taskExecutorVal {
  if (self = [super initWithWindowNibName: @"ProgressPanel" owner: self]) {
    taskExecutor = [taskExecutorVal retain];
    
    refreshRate = [[NSUserDefaults standardUserDefaults] floatForKey: ProgressPanelRefreshRateKey];
    if (refreshRate <= 0) {
      NSLog(@"Invalid value for progressPanelRefreshRate.");
      refreshRate = 1;
    }
    
    detailsFormat = [[self progressDetailsFormat] retain];
    summaryFormat = [[self progressSummaryFormat] retain];
  }
  
  return self;
}


- (void) dealloc {
  [taskExecutor release];
  
  [detailsFormat release];
  [summaryFormat release];

  NSAssert(cancelCallback==nil, @"cancelCallback not nil.");
  
  [super dealloc]; 
}


- (void) windowDidLoad {
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
                     ? [NSString stringWithFormat: detailsFormat, currentPath]
                     : @"";
}

- (void) updateProgressSummary:(int)numProcessed {
  progressSummary.stringValue = [NSString stringWithFormat: summaryFormat, numProcessed];
}

- (void) updateProgressEstimate:(float)progressEstimate {
  progressIndicator.doubleValue = progressEstimate;
}

@end // @implementation ProgressPanelControl (PrivateMethods)


