#import <Cocoa/Cocoa.h>


@class UniformTypeRanking;

@interface UniformTypeRankingWindowControl 
  : NSWindowController <NSTableViewDataSource, NSTableViewDelegate> {

  IBOutlet NSTableView  *typesTable;

  IBOutlet NSDrawer  *typeDescriptionDrawer;
  IBOutlet NSTextField  *typeIdentifierField;
  IBOutlet NSTextField  *typeDescriptionField;
  IBOutlet NSTextField  *typeConformsToField;
  
  IBOutlet NSButton  *moveToTopButton;
  IBOutlet NSButton  *moveToBottomButton;

  IBOutlet NSButton  *revealButton;
  IBOutlet NSButton  *hideButton;

  IBOutlet NSButton  *moveUpButton;
  IBOutlet NSButton  *moveDownButton;

  UniformTypeRanking  *typeRanking;
  NSMutableArray  *typeCells;
}

- (IBAction) cancelAction: (id) sender;
- (IBAction) okAction: (id) sender;

- (IBAction) moveToTopAction: (id) sender;
- (IBAction) moveToBottomAction: (id) sender;

- (IBAction) moveToRevealAction: (id) sender;
- (IBAction) moveToHideAction: (id) sender;

- (IBAction) moveUpAction: (id) sender;
- (IBAction) moveDownAction: (id) sender;

- (IBAction) showTypeDescriptionChanged: (id) sender;


- (id) initWithUniformTypeRanking: (UniformTypeRanking *)typeRanking;

@end
