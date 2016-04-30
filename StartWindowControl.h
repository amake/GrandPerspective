#import <Cocoa/Cocoa.h>

#import "MainMenuControl.h"

@interface StartWindowControl : NSWindowController <NSTableViewDataSource, NSTableViewDelegate> {

  IBOutlet NSTableView  *recentScansView;

  MainMenuControl  *mainMenuControl;

}

- (id) initWithMainMenuControl:(MainMenuControl *)mainMenuControl;

- (IBAction) scanAction:(id) sender;
- (IBAction) helpAction:(id) sender;
- (IBAction) repeatRecentScanAction:(id) sender;

@end
