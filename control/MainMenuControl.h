#import <Cocoa/Cocoa.h>

@class WindowManager;
@class VisibleAsynchronousTaskManager;
@class FiltersWindowControl;
@class UniformTypeRankingWindowControl;
@class FilterSelectionPanelControl;
@class PreferencesPanelControl;
@class StartWindowControl;
@class ExportAsTextDialogControl;

@interface MainMenuControl : NSObject {
  WindowManager  *windowManager;
  
  VisibleAsynchronousTaskManager  *scanTaskManager;
  VisibleAsynchronousTaskManager  *filterTaskManager;
  VisibleAsynchronousTaskManager  *rawWriteTaskManager;
  VisibleAsynchronousTaskManager  *xmlWriteTaskManager;
  VisibleAsynchronousTaskManager  *xmlReadTaskManager;

  StartWindowControl  *startWindowControl;
  PreferencesPanelControl  *preferencesPanelControl;
  FilterSelectionPanelControl  *filterSelectionPanelControl;
  FiltersWindowControl  *filtersWindowControl;
  UniformTypeRankingWindowControl  *uniformTypeWindowControl;
  ExportAsTextDialogControl  *exportAsTextDialogControl;
  
  BOOL  showWelcomeWindow;
  // The number of open directory view windows
  int  viewCount;
}

+ (MainMenuControl *)singletonInstance;

+ (NSArray *)rescanActionNames;
+ (NSArray *)rescanBehaviourNames;
+ (NSArray *)noViewsBehaviourNames;

+ (void) reportUnboundFilters:(NSArray *)unboundFilters;
+ (void) reportUnboundTests:(NSArray *)unboundTests;

- (IBAction) scanDirectoryView:(id)sender;
- (IBAction) scanFilteredDirectoryView:(id)sender;

// Default rescan action
- (IBAction) rescan:(id)sender;

// Rescan entire scan tree
- (IBAction) rescanAll:(id)sender;

// Rescan visible tree
- (IBAction) rescanVisible:(id)sender;

// Rescan selected item (file or directory)
- (IBAction) rescanSelected:(id)sender;

// Rescan the entire scan tree, with the current mask as a filter
- (IBAction) rescanWithMaskAsFilter:(id)sender;

- (IBAction) filterDirectoryView:(id)sender;
- (IBAction) duplicateDirectoryView:(id)sender;
- (IBAction) twinDirectoryView:(id)sender;

// Saves and loads XML scan data
- (IBAction) saveScanData:(id)sender;
- (IBAction) loadScanData:(id)sender;

// Saves scan data as text
- (IBAction) saveScanDataAsText:(id)sender;

- (IBAction) saveDirectoryViewImage:(id)sender;

- (IBAction) editPreferences:(id)sender;
- (IBAction) editFilters:(id)sender;
- (IBAction) editUniformTypeRanking:(id)sender;

- (IBAction) toggleToolbarShown:(id)sender;
- (IBAction) customizeToolbar:(id)sender;

- (IBAction) toggleControlPanelShown:(id)sender;

- (IBAction) openWebsite:(id)sender;

- (void) scanFolder:(NSString *)path;

@end
