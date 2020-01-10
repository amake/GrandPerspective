#import <Cocoa/Cocoa.h>
#import "Compatibility.h"

@class UniformTypeRanking;

@interface UniformTypeRankingWindowControl 
  : NSWindowController <NSTableViewDataSource, NSTableViewDelegate> {

  IBOutlet NSTableView  *typesTable;

  IBOutlet NSButton  *moveToTopButton;
  IBOutlet NSButton  *moveToBottomButton;

  IBOutlet NSButton  *revealButton;
  IBOutlet NSButton  *hideButton;

  IBOutlet NSButton  *moveUpButton;
  IBOutlet NSButton  *moveDownButton;

  UniformTypeRanking  *typeRanking;
  NSMutableArray  *typeCells;
  BOOL  updateTypeList;
}

- (IBAction) cancelAction:(id)sender;
- (IBAction) okAction:(id)sender;

- (IBAction) moveToTopAction:(id)sender;
- (IBAction) moveToBottomAction:(id)sender;

- (IBAction) moveToRevealAction:(id)sender;
- (IBAction) moveToHideAction:(id)sender;

- (IBAction) moveUpAction:(id)sender;
- (IBAction) moveDownAction:(id)sender;


- (instancetype) initWithUniformTypeRanking:(UniformTypeRanking *)typeRanking NS_DESIGNATED_INITIALIZER;

@end
