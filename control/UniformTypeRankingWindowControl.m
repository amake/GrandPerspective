#import "UniformTypeRankingWindowControl.h"

#import "UniformTypeRanking.h"
#import "UniformType.h"


NSString  *InternalTableDragType = @"EditUniformTypeRankingWindowInternalDrag";


@interface TypeCell : NSObject {
  UniformType  *type;
  BOOL  dominated;
}

- (instancetype) initWithUniformType:(UniformType *)type
                           dominated:(BOOL)dominated NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly, strong) UniformType *uniformType;
@property (nonatomic, getter=isDominated) BOOL dominated;

@end // @interface TypeCell


@interface UniformTypeRankingWindowControl (PrivateMethods)

- (void) fetchCurrentTypeList;
- (void) commitChangedTypeList;

- (void) closeWindow;

- (void) updateWindowState;

- (void) moveCellUpFromIndex:(NSUInteger)index;
- (void) moveCellDownFromIndex:(NSUInteger)index;
- (void) movedCellToIndex:(NSUInteger)index;

- (NSUInteger) getRowNumberFromDraggingInfo:(id <NSDraggingInfo>)info;

@end // @interface UniformTypeRankingWindowControl (PrivateMethods)


@implementation UniformTypeRankingWindowControl

// Override designated initialisers
- (instancetype) initWithWindow:(NSWindow *)window {
  NSAssert(NO, @"Use init instead");
  return [self init];
}
- (instancetype) initWithCoder:(NSCoder *)coder {
  NSAssert(NO, @"Use init instead");
  return [self init];
}

- (instancetype) init {
  return [self initWithUniformTypeRanking: [UniformTypeRanking defaultUniformTypeRanking]];
}

- (instancetype) initWithUniformTypeRanking: (UniformTypeRanking *)typeRankingVal {
  if (self = [super initWithWindow: nil]) {
    typeRanking = [typeRankingVal retain];
    typeCells =
      [[NSMutableArray arrayWithCapacity: [typeRanking rankedUniformTypes].count] retain];

    updateTypeList = YES;
  }
  
  return self;
}

- (void) dealloc {
  [typeRanking release];
  [typeCells release];

  [super dealloc];
}


- (NSString *)windowNibName {
  return @"UniformTypeRankingWindow";
}

- (void) windowDidLoad {
  typesTable.delegate = self;
  typesTable.dataSource = self;
  
  [typesTable registerForDraggedTypes: @[InternalTableDragType]];
}


- (IBAction) cancelAction:(id)sender {
  [self closeWindow];
}

- (IBAction) okAction:(id)sender {
  [self commitChangedTypeList];

  [self closeWindow];
}

- (IBAction) moveToTopAction:(id)sender {
  NSInteger  i = typesTable.selectedRow;
  
  while (i > 0) {
    [self moveCellUpFromIndex: i];
    i--;
  }
  
  [self movedCellToIndex: i];
}

- (IBAction) moveToBottomAction:(id)sender {
  NSInteger  i = typesTable.selectedRow;
  NSAssert(i >= 0, @"No row selected");
  
  NSUInteger  max_i = typeCells.count - 1;
  while (i < max_i) {
    [self moveCellDownFromIndex: i];
    i++;
  }

  [self movedCellToIndex: i];
}

- (IBAction) moveToRevealAction:(id)sender {
  NSInteger  i = typesTable.selectedRow;
  NSAssert(i >= 0, @"No row selected");

  while (i > 0 && [typeCells[i] isDominated]) {
    [self moveCellUpFromIndex: i];
    i--;
  }
  
  [self movedCellToIndex: i];
}

- (IBAction) moveToHideAction:(id)sender {
  NSInteger  i = typesTable.selectedRow;
  NSAssert(i >= 0, @"No row selected");

  NSUInteger  max_i = typeCells.count - 1;
  while (i < max_i && ![typeCells[i] isDominated]) {
    [self moveCellDownFromIndex: i];
    i++;
  }
  
  [self movedCellToIndex: i];
}

- (IBAction) moveUpAction:(id)sender {
  NSInteger  i = typesTable.selectedRow;
  NSAssert(i >= 0, @"No row selected");
  
  if (i > 0) {
    [self moveCellUpFromIndex: i];
    i--;
  }
  
  [self movedCellToIndex: i];
}

- (IBAction) moveDownAction:(id)sender {
  NSInteger  i = typesTable.selectedRow;
  NSAssert(i >= 0, @"No row selected");

  NSUInteger  max_i = typeCells.count - 1;
  if (i < max_i) {
    [self moveCellDownFromIndex: i];
    i++;
  }
  
  [self movedCellToIndex: i];
}


- (IBAction) showTypeDescriptionChanged:(id)sender {
  NSButton  *button = sender;
  if (button.state == NSOffState) {
    [typeDescriptionDrawer close];
  }
  else if (button.state == NSOnState) {
    [typeDescriptionDrawer open];
  }
}


//----------------------------------------------------------------------------
// Delegate methods for NSWindow

- (void) windowDidBecomeKey: (NSNotification *)notification { 
  if (updateTypeList) {
    // The window has just been opened. Fetch the latest type list. This resets any uncommitted
    // changes made the last time the window was shown.
    
    [self fetchCurrentTypeList];
    [self updateWindowState];

    // Reset because the NSWindowDidBecomeKeyNotification is also fired when the window is already
    // open (but lost and subsequently regained its key status). In this case, the state should not
    // be reset.
    updateTypeList = NO;
  }
}

//----------------------------------------------------------------------------
// NSTableSource

- (NSInteger) numberOfRowsInTableView: (NSTableView *)tableView {
  return typeCells.count;
}

- (id) tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)column
             row:(NSInteger)row {
  return [[typeCells[row] uniformType] uniformTypeIdentifier];
}


- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes
     toPasteboard:(NSPasteboard *)pboard {

  // Get the source row number of the type that is being dragged.
  NSNumber  *rowNum = @(rowIndexes.firstIndex);
  NSData  *data = [NSKeyedArchiver archivedDataWithRootObject: rowNum];

  [pboard declareTypes: @[InternalTableDragType] owner: self];
  [pboard setData: data forType: InternalTableDragType];

  return YES;
}

- (NSDragOperation) tableView:(NSTableView *)tableView
                 validateDrop:(id <NSDraggingInfo>)info
                  proposedRow:(NSInteger)row
        proposedDropOperation:(NSTableViewDropOperation)op {
  if (op == NSTableViewDropAbove) {
    // Only allow drops in between two existing rows as otherwise it is not clear to the user where
    // the dropped item will be moved to.
  
    NSUInteger  fromRow = [self getRowNumberFromDraggingInfo: info];
    if (row < fromRow || row > fromRow + 1) {
      // Only allow drops that actually result in a move.
      
      return NSDragOperationMove;
    }
  }

  return NSDragOperationNone;
}

- (BOOL) tableView:(NSTableView *)tableView
        acceptDrop:(id <NSDraggingInfo>)info
               row:(NSInteger)row
     dropOperation:(NSTableViewDropOperation)op {

  NSUInteger  i = [self getRowNumberFromDraggingInfo: info];

  if (i > row) {
    while (i > row) {
      [self moveCellUpFromIndex: i];
      i--;
    }
  }
  else {
    NSUInteger  max_i = row - 1;
    while (i < max_i) {
      [self moveCellDownFromIndex: i];
      i++;
    }
  }
  
  [self movedCellToIndex: i];
  
  return YES;
}


//----------------------------------------------------------------------------
// Delegate methods for NSTable

- (void) tableView:(NSTableView *)tableView
   willDisplayCell:(id)cell
    forTableColumn:(NSTableColumn *)aTableColumn
               row:(NSInteger)row {
  NSAssert2(row < [typeCells count], @"%ld >= %ld", row, [typeCells count]);

  TypeCell  *typeCell = typeCells[row];
  NSString  *uti = [[typeCell uniformType] uniformTypeIdentifier];

  NSMutableAttributedString  *cellValue = 
    [[[NSMutableAttributedString alloc] initWithString: uti] autorelease];

  if ([typeCell isDominated]) {
    [cellValue addAttribute: NSForegroundColorAttributeName
                      value: [NSColor grayColor]
                      range: NSMakeRange(0, cellValue.length)];
  }
  
  [cell setAttributedStringValue: cellValue];
}

- (void) tableViewSelectionDidChange: (NSNotification *)notification {
  [self updateWindowState];
}

@end // @implementation UniformTypeRankingWindowControl


@implementation UniformTypeRankingWindowControl (PrivateMethods)

// Updates the window state to reflect the state of the uniform type ranking
- (void) fetchCurrentTypeList {
  [typeCells removeAllObjects];
  
  NSArray  *currentRanking = [typeRanking rankedUniformTypes];
  
  NSEnumerator  *typeEnum = [currentRanking objectEnumerator];
  UniformType  *type;
  while (type = [typeEnum nextObject]) {
    BOOL  dominated = [typeRanking isUniformTypeDominated: type];
    TypeCell  *typeCell = [[[TypeCell alloc] initWithUniformType: type
                                                       dominated: dominated] autorelease];

    [typeCells addObject: typeCell];
  }
  
  [typesTable reloadData]; 
  [typesTable selectRowIndexes: [NSIndexSet indexSetWithIndex: 0]
          byExtendingSelection: NO];
}

// Commits changes made in the window to the uniform type ranking.
- (void) commitChangedTypeList {
  NSMutableArray  *newRanking = [NSMutableArray arrayWithCapacity: typeCells.count];
    
  NSEnumerator  *typeCellEnum = [typeCells objectEnumerator];
  TypeCell  *typeCell;
  while (typeCell = [typeCellEnum nextObject]) {
    [newRanking addObject: [typeCell uniformType]];
  }
  
  [typeRanking updateRankedUniformTypes: newRanking];
}


- (void) closeWindow {
  [self.window close];
  
  // Force update of the type list again when the window appears again. This ensures that any
  // changes are undone if the user closed the window by pressing "Cancel".
  updateTypeList = YES;
}


- (void) updateWindowState {
  NSInteger  i = typesTable.selectedRow;
  NSUInteger  numCells =  typeCells.count;
  
  NSAssert(i >= 0 && i < numCells, @"Invalid selected type.");
  
  TypeCell  *typeCell = typeCells[i];
  
  revealButton.enabled = [typeCell isDominated];
  hideButton.enabled = ( ![typeCell isDominated] && (i < numCells -1) ) ;

  moveUpButton.enabled = i > 0;
  moveToTopButton.enabled = i > 0;

  moveDownButton.enabled = i < numCells - 1;
  moveToBottomButton.enabled = i < numCells - 1;
  
  UniformType  *type = [typeCell uniformType];
  
  typeIdentifierField.stringValue = [type uniformTypeIdentifier];
  
  NSString  *descr = [type description];
  typeDescriptionField.stringValue = (descr != nil) ? descr : @"";

  NSMutableString  *conformsTo = [NSMutableString stringWithCapacity: 64];
  NSEnumerator  *parentEnum = [[type parentTypes] objectEnumerator];
  UniformType  *parentType;
  while (parentType = [parentEnum nextObject]) {
    if (conformsTo.length > 0) {
      [conformsTo appendString: @", "];
    }
    [conformsTo appendString: [parentType uniformTypeIdentifier]];
  }
  typeConformsToField.stringValue = conformsTo;
}


- (void) moveCellUpFromIndex:(NSUInteger)index {
  TypeCell  *upCell = typeCells[index];
  TypeCell  *downCell = typeCells[index - 1];
  
  // Swap the cells
  [typeCells exchangeObjectAtIndex: index withObjectAtIndex: index - 1];

  // Check if the dominated status of upCell changed.
  if ([upCell isDominated]) {
    NSSet  *ancestors = [[upCell uniformType] ancestorTypes];

    if ([ancestors containsObject: [downCell uniformType]]) {
      // downCell was an ancestor of upCell, so upCell may not be dominated anymore.
      
      NSUInteger  i = 0;
      NSUInteger  max_i = index - 1;
      BOOL  dominated = NO;
      while (i < max_i && !dominated) {
        UniformType  *higherType = [typeCells[i] uniformType];
        
        if ([ancestors containsObject: higherType]) {
          dominated = YES;
        }
        
        i++;
      }
      
      if (! dominated) {
        [upCell setDominated: NO];
      }
    }
  }
  
  // Check if the dominated status of downCell changed.
  if (! [downCell isDominated]) {
    NSSet  *ancestors = [[downCell uniformType] ancestorTypes];
    
    if ([ancestors containsObject: [upCell uniformType]]) {
      [downCell setDominated: YES];
    }
  }
}

- (void) moveCellDownFromIndex:(NSUInteger)index {
  [self moveCellUpFromIndex: index + 1];
}

/* Update the window after a cell has been moved.
 */
- (void) movedCellToIndex:(NSUInteger)index {
  [typesTable selectRowIndexes: [NSIndexSet indexSetWithIndex: index]
          byExtendingSelection: NO];
  [typesTable reloadData];
  [self updateWindowState];
}


- (NSUInteger) getRowNumberFromDraggingInfo:(id <NSDraggingInfo>)info {
  NSPasteboard  *pboard = [info draggingPasteboard];
  NSData  *data = [pboard dataForType: InternalTableDragType];
  NSNumber  *rowNum = [NSKeyedUnarchiver unarchiveObjectWithData: data];
  
  return rowNum.unsignedIntegerValue;
}

@end // @implementation UniformTypeRankingWindowControl (PrivateMethods)


@implementation TypeCell

// Overrides designated initialiser
- (instancetype) init {
  NSAssert(NO, @"Use initWithUniformType:dominated: instead");
  return [self initWithUniformType: nil dominated: NO];
}

- (instancetype) initWithUniformType:(UniformType *)typeVal dominated:(BOOL)dominatedVal {
  if (self = [super init]) {
    type = [typeVal retain];
    dominated = dominatedVal;
  }
  
  return self;
}

- (void) dealloc {
  [type release];
  
  [super dealloc];
}

- (UniformType *)uniformType {
  return type;
}

- (BOOL) isDominated {
  return dominated;
}

- (void) setDominated:(BOOL)flag {
  dominated = flag;
}

@end // @implementation TypeCell
