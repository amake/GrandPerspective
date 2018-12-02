#import <Cocoa/Cocoa.h>

#import "MainMenuControl.h"

@interface StartWindowControl : NSWindowController <NSTableViewDataSource, NSTableViewDelegate> {

  IBOutlet NSTableView  *recentScansView;
  IBOutlet NSTextField  *tagLine;

  MainMenuControl  *mainMenuControl;

  int  numTagLines;
  int  tagLineIndex;
}

- (instancetype) initWithMainMenuControl:(MainMenuControl *)mainMenuControl NS_DESIGNATED_INITIALIZER;

- (IBAction) scanAction:(id)sender;
- (IBAction) helpAction:(id)sender;
- (IBAction) repeatRecentScanAction:(id)sender;

- (void) changeTagLine;

@end
