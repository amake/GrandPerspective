#import <Cocoa/Cocoa.h>

#import "MainMenuControl.h"

@interface StartWindowControl : NSWindowController <NSTableViewDataSource, NSTableViewDelegate> {

  IBOutlet NSTableView  *recentScansView;
  IBOutlet NSTextField  *tagLine;
  IBOutlet NSButton  *clearHistoryButton;

  MainMenuControl  *mainMenuControl;

  int  numTagLines;
  int  tagLineIndex;

  BOOL  forceReloadOnShow;
}

- (instancetype) initWithMainMenuControl:(MainMenuControl *)mainMenuControl NS_DESIGNATED_INITIALIZER;

- (IBAction) scanAction:(id)sender;
- (IBAction) helpAction:(id)sender;
- (IBAction) scanActionAfterDoubleClick:(id)sender;
- (IBAction) clearRecentScans:(id)sender;

- (void) changeTagLine;

@end
