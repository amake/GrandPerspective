#import "FilterWindowControl.h"

#import "ControlConstants.h"
#import "NameValidator.h"
#import "NotifyingDictionary.h"

#import "FileItemTest.h"

#import "FilterTestRepository.h"
#import "Filter.h"
#import "NamedFilter.h"
#import "FilterTest.h"
#import "MutableFilterTestRef.h"

#import "FilterTestEditor.h"


NSString  *NameColumn = @"name";
NSString  *MatchColumn = @"match";


@interface FilterWindowControl (PrivateMethods)

- (NSArray *)availableTests;

// Returns the non-localized name of the selected available test (if any).
- (NSString *)selectedAvailableTestName;

// Returns the selected filter test (if any).
- (MutableFilterTestRef *)selectedFilterTest;

// Returns NSNotFound when the test was not found
- (NSUInteger) indexOfTestInFilterNamed:(NSString *)name;

/* Helper method for creating FilterTests to be added to the filter. It sets
 * the inverted and canToggleInverted flags correctly.
 */
- (MutableFilterTestRef *)filterTestForTestNamed:(NSString *)name; 

- (void) testAddedToRepository:(NSNotification *)notification;
- (void) testRemovedFromRepository:(NSNotification *)notification;
- (void) testUpdatedInRepository:(NSNotification *)notification;
- (void) testRenamedInRepository:(NSNotification *)notification;

- (void) updateWindowState:(NSNotification *)notification;
- (void) updateWindowTitle;

- (void) textEditingStarted:(NSNotification *)notification;
- (void) textEditingStopped:(NSNotification *)notification;

- (void) appDidUpdate:(NSNotification *)notification;

- (BOOL) isNameKnownInvalid;

- (void) confirmTestRemovalAlertDidEnd:(NSAlert *)alert 
           returnCode:(int) returnCode contextInfo:(void *)contextInfo;

- (void) invalidNameAlertDidEnd:(NSAlert *)alert returnCode:(int) returnCode
           contextInfo:(void *)contextInfo;

@end // @interface FilterWindowControl (PrivateMethods)


@implementation FilterWindowControl

- (id) init {
  return [self initWithTestRepository: [FilterTestRepository defaultInstance]];
}

// Special case: should not cover (override) super's designated initialiser in
// NSWindowController's case
- (id) initWithTestRepository:(FilterTestRepository *)testRepositoryVal {
  if (self = [super initWithWindowNibName: @"FilterWindow" owner: self]) {
    testRepository = [testRepositoryVal retain];
    NotifyingDictionary  *repositoryTestsByName = 
      [testRepository testsByNameAsNotifyingDictionary];

    NSNotificationCenter  *nc = [repositoryTestsByName notificationCenter];
    
    [nc addObserver:self selector: @selector(testAddedToRepository:) 
          name: ObjectAddedEvent object: repositoryTestsByName];
    [nc addObserver:self selector: @selector(testRemovedFromRepository:) 
          name: ObjectRemovedEvent object: repositoryTestsByName];
    [nc addObserver:self selector: @selector(testUpdatedInRepository:) 
          name: ObjectUpdatedEvent object: repositoryTestsByName];
    [nc addObserver:self selector: @selector(testRenamedInRepository:) 
          name: ObjectRenamedEvent object: repositoryTestsByName];

    filterName = nil;
    filterTests = [[NSMutableArray alloc] initWithCapacity: 8];
    
    availableTests = [[NSMutableArray alloc] 
      initWithCapacity: [[testRepository testsByName]count] + 8];
    [availableTests
       addObjectsFromArray: [[testRepository testsByName] allKeys]];
    [availableTests sortUsingSelector: @selector(compare:)];

    testEditor = 
      [[FilterTestEditor alloc] initWithFilterTestRepository: testRepository];
    
    nameValidator = nil;
    invalidName = nil;
       
    allowEmptyFilter = NO; // Default
  }
  return self;
}

- (void) dealloc {
  [[[testRepository testsByNameAsNotifyingDictionary] notificationCenter] 
       removeObserver: self];
  [testRepository release];
  
  [[NSNotificationCenter defaultCenter] removeObserver: self];

  [testEditor release];

  [filterName release];
  [filterTests release];
  [availableTests release];
  
  [nameValidator release];
  [invalidName release];
  
  [selectedTestName release];
  
  [super dealloc];
}


- (void) windowDidLoad {
  [filterTestsView setDelegate: self];
  [filterTestsView setDataSource: self];
  
  [filterTestsView setTarget: self];
  [filterTestsView setDoubleAction: @selector(testDoubleClicked:)];
  
  [availableTestsView setDelegate: self];
  [availableTestsView setDataSource: self];
  
  [[[filterTestsView tableColumnWithIdentifier: MatchColumn] dataCell]
       setImageAlignment: NSImageAlignRight];
    
  [self updateWindowState: nil];
  
  NSNotificationCenter  *nc = [NSNotificationCenter defaultCenter];
  [nc addObserver: self selector: @selector(textEditingStarted:) 
          name: NSTextDidBeginEditingNotification object: nil];
  [nc addObserver: self selector: @selector(textEditingStopped:) 
          name: NSTextDidEndEditingNotification object: nil];

  [nc addObserver: self
         selector: @selector(appDidUpdate:)
             name: NSApplicationDidUpdateNotification
           object: nil];
}


- (void) setAllowEmptyFilter:(BOOL) flag {
  allowEmptyFilter = flag;
}

- (BOOL) allowEmptyFilter {
  return allowEmptyFilter;
}


- (void)windowDidBecomeKey:(NSNotification *)notification {
  finalNotificationFired = NO;

  NSResponder  *initialFirstResponder = nil;
  if ([self isNameKnownInvalid]) {
    initialFirstResponder = filterNameField;
  }
  else if ([filterTestsView selectedRow] != -1) {
    initialFirstResponder =  filterTestsView;
  }
  else {
    initialFirstResponder = availableTestsView;
  }
  [[self window] makeFirstResponder: initialFirstResponder];
}

- (void) windowWillClose:(NSNotification *)notification {
  if (! finalNotificationFired ) {
    // The window is closing while no "okPerformed" or "cancelPerformed" has
    // been fired yet. This means that the user is closing the window using
    // the window's red close button.
    
    [[NSNotificationCenter defaultCenter] 
        postNotificationName: ClosePerformedEvent object: self];
  }
}


- (IBAction) cancelAction:(id) sender {
  NSAssert( !finalNotificationFired, @"Final notification already fired." );

  finalNotificationFired = YES;
  [[NSNotificationCenter defaultCenter] 
      postNotificationName: CancelPerformedEvent object: self];
}

- (IBAction) okAction:(id) sender {
  NSAssert( !finalNotificationFired, @"Final notification already fired." );

  // Check if the name of the test is okay.
  NSString  *errorMsg = [nameValidator checkNameIsValid: [self filterName]];
      
  if (errorMsg != nil) {
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
  
    [alert addButtonWithTitle: OK_BUTTON_TITLE];
    [alert setMessageText: errorMsg];

    [alert beginSheetModalForWindow: [self window]
             modalDelegate: self 
             didEndSelector: 
               @selector(invalidNameAlertDidEnd:returnCode:contextInfo:) 
             contextInfo: nil];
    [invalidName release];
    invalidName = [[self filterName] retain];
  }
  else {
    finalNotificationFired = YES;
    [[NSNotificationCenter defaultCenter] 
        postNotificationName: OkPerformedEvent object: self];
  }
}


- (IBAction) filterNameChanged:(id) sender {
  [self updateWindowTitle];
  [self updateWindowState: nil];
}


- (IBAction) removeTestFromRepository:(id) sender {
  NSString  *testName = [self selectedAvailableTestName];
  
  NSAlert  *alert = [[[NSAlert alloc] init] autorelease];

  NSString  *fmt = NSLocalizedString( @"Remove the test named \"%@\"?",
                                      @"Alert message" );
  NSString  *infoMsg = 
    ([testRepository applicationProvidedTestForName: testName] != nil) ?
      NSLocalizedString(
        @"The test will be replaced by the default test with this name.",
        @"Alert informative text" ) :
      NSLocalizedString( 
        @"The test will be irrevocably removed from the test repository.",
        @"Alert informative text" );

  NSBundle  *mainBundle = [NSBundle mainBundle];
  NSString  *localizedName = 
    [mainBundle localizedStringForKey: testName value: nil table: @"Names"];
  
  [alert addButtonWithTitle: REMOVE_BUTTON_TITLE];
  [alert addButtonWithTitle: CANCEL_BUTTON_TITLE];
  [alert setMessageText: [NSString stringWithFormat: fmt, localizedName]];
  [alert setInformativeText: infoMsg];

  [alert beginSheetModalForWindow: [self window] modalDelegate: self
           didEndSelector: @selector(confirmTestRemovalAlertDidEnd: 
                                       returnCode:contextInfo:) 
           contextInfo: testName];
}


- (IBAction) addTestToRepository:(id) sender {
  FilterTest  *newTest = [testEditor newFilterTest];
  
  NSUInteger  index = [availableTests indexOfObject: [newTest name]];
  [availableTestsView selectRowIndexes: [NSIndexSet indexSetWithIndex: index]
                  byExtendingSelection: NO];
  [[self window] makeFirstResponder: availableTestsView];
  [self updateWindowState: nil];
}


- (IBAction) editTestInRepository:(id) sender {
  NSString  *oldName = [self selectedAvailableTestName];
  [testEditor editFilterTestNamed: oldName];
}


- (IBAction) addTestToFilter:(id) sender {
  NSString  *testName = [self selectedAvailableTestName];
  
  if (testName != nil) {
    FilterTestRef  *filterTest = [self filterTestForTestNamed: testName];
    NSAssert(filterTest != nil, @"Test not found in repository.");
        
    [filterTests addObject: filterTest];
    
    [filterTestsView reloadData];
    [availableTestsView reloadData];
    
    // Select the newly added test.
    NSUInteger  index = [filterTests indexOfObject: filterTest];
    [filterTestsView selectRowIndexes: [NSIndexSet indexSetWithIndex: index]
                 byExtendingSelection: NO];
    [[self window] makeFirstResponder: filterTestsView];

    [self updateWindowState: nil];
  }
}

- (IBAction) removeTestFromFilter:(id) sender {
  NSInteger  index = [filterTestsView selectedRow];
  
  if (index >= 0) {
    NSString  *testName = [[filterTests objectAtIndex: index] name];
    
    [filterTests removeObjectAtIndex: index];

    [filterTestsView reloadData];
    [availableTestsView reloadData];
    
    // Select the test in the repository (if it still exists there)
    NSUInteger  index = [availableTests indexOfObject: testName];
    if (index != NSNotFound) {
      [availableTestsView selectRowIndexes: [NSIndexSet indexSetWithIndex: index]
                      byExtendingSelection: NO];
      [[self window] makeFirstResponder: availableTestsView];
    }
    
    [self updateWindowState: nil];
  }
}

- (IBAction) removeAllTestsFromFilter:(id) sender {
  [filterTests removeAllObjects];
  
  [filterTestsView reloadData];
  [availableTestsView reloadData];

  [self updateWindowState: nil];
}

- (IBAction) showTestDescriptionChanged:(id) sender {
  NSButton  *button = sender;
  if ([button state] == NSOffState) {
    [testDescriptionDrawer close];
  }
  else if ([button state] == NSOnState) {
    [testDescriptionDrawer open];
  }
}

- (IBAction) testDoubleClicked:(id) sender {
  MutableFilterTestRef  *filterTest = [self selectedFilterTest];
  if (filterTest != nil && [filterTest canToggleInverted]) {
    [filterTest toggleInverted];
    [filterTestsView reloadData];
  }
}


//----------------------------------------------------------------------------
// NSTableSource

- (NSInteger) numberOfRowsInTableView:(NSTableView *)tableView {
  if (tableView == filterTestsView) {
    return [filterTests count];
  }
  else if (tableView == availableTestsView) {
    return [availableTests count];
  }
  else {
    NSAssert(NO, @"Unexpected sender.");
    return 0;
  }
}

- (id) tableView:(NSTableView *)tableView 
         objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger) row {
  NSBundle  *mainBundle = [NSBundle mainBundle];
  
  if (tableView == filterTestsView) {
    FilterTestRef  *filterTest = [filterTests objectAtIndex: row];

    if ([[column identifier] isEqualToString: NameColumn]) {
      return [mainBundle localizedStringForKey: [filterTest name] value: nil 
                           table: @"Names"];
    }
    else if ([[column identifier] isEqualToString: MatchColumn]) {
      return [NSImage imageNamed: 
                        ([filterTest isInverted] ? @"Cross" : @"Checkmark")];
    }
    else {
      NSAssert(NO, @"Unknown column.");
    }
  }
  else if (tableView == availableTestsView) {
    NSString  *name = [availableTests objectAtIndex: row]; 
    return [mainBundle localizedStringForKey: name value: nil table: @"Names"];
  }
  NSAssert(NO, @"Unknown tableView.");
  return nil;
}


//-----------------------------------------------------------------------------
// Delegate methods for NSTableView

- (void) tableView:(NSTableView *)tableView willDisplayCell:(id) cell 
           forTableColumn:(NSTableColumn *)column row:(NSInteger) row {
  if (tableView == availableTestsView) {
    NSString  *name = [availableTests objectAtIndex: row];

    [cell setEnabled: [self indexOfTestInFilterNamed: name] == NSNotFound];
  }
}

- (void) tableViewSelectionDidChange:(NSNotification *)notification {
  [self updateWindowState: nil];
}


- (NSString *)filterName {
  if ([filterNameField isEnabled]) {
    // No fixed "visible" name was set, so get the name from the text field.
    return [filterNameField stringValue];
  }
  else {
    // The test name field was showing the test's visible name. Return its
    // original name.
    return filterName;
  }
}


- (void) setNameValidator:(NSObject<NameValidator> *)validator {
  if (validator != nameValidator) {
    [nameValidator release];
    nameValidator = [validator retain];
  }
}


- (void) representEmptyFilter {
  NamedFilter  *emptyFilter = [NamedFilter emptyFilterWithName: @""];
  [self representNamedFilter: emptyFilter];
}


// Configures the window to represent the given filter.
- (void) representNamedFilter:(NamedFilter *)namedFilter {
  NSAssert(namedFilter != nil, @"Filter should not be nil.");
  
  Filter  *filter = [namedFilter filter];
  [filterTests removeAllObjects];
  
  NSUInteger  i = 0;
  NSUInteger  max = [filter numFilterTests];
  while (i < max) {
    FilterTestRef  *orgFilterTest = [filter filterTestAtIndex: i];
    NSString  *name = [orgFilterTest name];
    
    MutableFilterTestRef  *newFilterTest = [self filterTestForTestNamed: name];
    if (newFilterTest != nil) {
      if ( [newFilterTest canToggleInverted] &&
           [newFilterTest isInverted] != [orgFilterTest isInverted] ) {
        [newFilterTest toggleInverted];
      }
    
      [filterTests addObject: newFilterTest];
    }
    else {
      NSLog(@"Test \"%@\" does not exist anymore in repository.", name);

      // Simply omit it.
    }

    i++;
  }
  
  [filterTestsView reloadData];
  [availableTestsView reloadData];
  
  if (filterName != [namedFilter name]) {
    [filterName release];
    filterName = [[namedFilter name] retain];
  }
  [filterNameField setStringValue: filterName];
  [filterNameField setEnabled: YES];

  // Forget about any previously reported invalid names.
  [invalidName release];
  invalidName = nil;

  [self updateWindowTitle];
  [self updateWindowState: nil];
}

// Returns the filter that represents the current window state.
- (NamedFilter *)createNamedFilter {
  Filter  *filter = [Filter filterWithFilterTests: filterTests];
  return [NamedFilter namedFilter: filter name: [self filterName]];
}


- (void) setVisibleName:(NSString *)name {
  [filterNameField setStringValue: name];
  [filterNameField setEnabled: NO];
  [self updateWindowTitle];
}

@end // @implementation FilterWindowControl


@implementation FilterWindowControl (PrivateMethods)

- (NSArray *)availableTests {
  return availableTests;
}

// Returns the non-localized name of the selected available test (if any).
- (NSString *)selectedAvailableTestName {
  NSInteger  index = [availableTestsView selectedRow];
  
  return (index < 0) ? nil : [availableTests objectAtIndex: index];
}

// Returns the selected filter test (if any).
- (MutableFilterTestRef *)selectedFilterTest {
  NSInteger  index = [filterTestsView selectedRow];
  
  return (index < 0) ? nil : [filterTests objectAtIndex: index];
}

- (NSUInteger) indexOfTestInFilterNamed:(NSString *)name {
  NSUInteger  i = [filterTests count];

  while (i-- > 0) {
    if ([[[filterTests objectAtIndex: i] name] isEqualToString: name]) {
      return i;
    }
  }
  
  return NSNotFound;
}


- (MutableFilterTestRef *)filterTestForTestNamed:(NSString *)name {
  FileItemTest  *test = [[testRepository testsByName] objectForKey: name];

  if (test == nil) {
    return nil;
  }

  MutableFilterTestRef  *filterTest = 
    [[MutableFilterTestRef alloc] initWithName: name];

  if ([test appliesToDirectories]) {
    // Fix "inverted" state of the filter test. 
    
    if (! [filterTest isInverted]) {
      [filterTest setCanToggleInverted: YES]; // Not needed, but no harm.
      [filterTest toggleInverted];
    }
    [filterTest setCanToggleInverted: NO];
  }
  
  return filterTest;
}


- (void) testAddedToRepository:(NSNotification *)notification { 
  NSString  *testName = [[notification userInfo] objectForKey:@"key"];
  NSString  *selectedName = [self selectedAvailableTestName];

  [availableTests addObject: testName];
  // Ensure that the tests remain sorted.
  [availableTests sortUsingSelector: @selector(compare:)];
  [availableTestsView reloadData];
        
  if (selectedName != nil) {
    // Make sure that the same test is still selected.
    NSUInteger  index = [availableTests indexOfObject: selectedName];
    [availableTestsView selectRowIndexes: [NSIndexSet indexSetWithIndex: index]
                    byExtendingSelection: NO];
  }
                
  [self updateWindowState: nil];
}


- (void) testRemovedFromRepository:(NSNotification *)notification {
  NSString  *testName = [[notification userInfo] objectForKey:@"key"];
  NSString  *selectedName = [self selectedAvailableTestName];

  NSUInteger  index = [availableTests indexOfObject: testName];
  NSAssert(index != NSNotFound, @"Test not found in available tests.");

  [availableTests removeObjectAtIndex:index];
  [availableTestsView reloadData];
  
  if ([testName isEqualToString: selectedName]) {
    // The removed test was selected. Clear the selection.
    [availableTestsView deselectAll: self];
  }
  else if (selectedName != nil) {
    // Make sure that the same test is still selected. 
    index = [availableTests indexOfObject: selectedName];
    [availableTestsView selectRowIndexes: [NSIndexSet indexSetWithIndex: index]
                    byExtendingSelection: NO];
  }

  [self updateWindowState:nil];
}


- (void) testUpdatedInRepository:(NSNotification *)notification {
  NSString  *testName = [[notification userInfo] objectForKey: @"key"];

  if ([selectedTestName isEqualToString: testName]) {
    // Invalidate the selected test description text (as it may have changed).
    [selectedTestName release];
    selectedTestName = nil;
  }
  
  [self updateWindowState: nil];
}


- (void) testRenamedInRepository:(NSNotification *)notification {
  NSString  *oldTestName = [[notification userInfo] objectForKey: @"oldkey"];
  NSString  *newTestName = [[notification userInfo] objectForKey: @"newkey"];

  NSUInteger  index = [availableTests indexOfObject: oldTestName];
  NSAssert(index != NSNotFound, @"Test not found in available tests.");

  NSString  *selectedName = [self selectedAvailableTestName];

  [availableTests replaceObjectAtIndex: index withObject: newTestName];
  // Ensure that the tests remain sorted.
  [availableTests sortUsingSelector: @selector(compare:)];
  [availableTestsView reloadData];
    
  if ([selectedName isEqualToString: oldTestName]) {
    // It was selected, so make sure it still is.
    selectedName = newTestName;
  }
  if (selectedName != nil) {
    // Make sure that the same test is still selected.
    index = [availableTests indexOfObject: selectedName];
    [availableTestsView selectRowIndexes: [NSIndexSet indexSetWithIndex: index] 
                    byExtendingSelection: NO];
  }
}


- (void) updateWindowState:(NSNotification *)notification {
  FilterTestRef  *selectedFilterTest = [self selectedFilterTest];
  NSString  *selectedAvailableTestName = [self selectedAvailableTestName];

  if (selectedAvailableTestName != nil) {
    NSUInteger  index = [self indexOfTestInFilterNamed: selectedAvailableTestName];
      
    if (index != NSNotFound) {
      // The window is in an anomalous situation: a test is selected in the
      // available tests view, even though the test is used in the filter.
      //
      // This anomalous situation can occur as follows:
      // 1. Create a mask, and press OK (to apply it and close the window).
      // 2. Edit the mask. Remove one of the tests from the filter, but now
      //    press Cancel (so that the mask remains unchanged, yet the window
      //    closes)
      // 3. Edit the mask again. Now the focus will still be on the test in the
      //    available test window that had been moved in Step 2. However, as 
      //    this change was undone by cancelling the mask, the test is actually
      //    not available and thus disabled.
    
      // Select the disabled test in the other view. 
      [filterTestsView selectRowIndexes: [NSIndexSet indexSetWithIndex: index]
                   byExtendingSelection: NO];

      [availableTestsView deselectAll: nil];
      selectedAvailableTestName = nil;

      [[self window] makeFirstResponder: filterTestsView];
    }
  }

  firstResponder = [[self window] firstResponder];
  BOOL  filterTestsHighlighted = (firstResponder == filterTestsView);
  BOOL  availableTestsHighlighted = ( firstResponder == availableTestsView );

  // Find out which test (if any) is currently highlighted.
  NSString  *newSelectedTestName = nil;

  if (filterTestsHighlighted) {
    newSelectedTestName = [selectedFilterTest name];
  }
  else if (availableTestsHighlighted) {
    newSelectedTestName = selectedAvailableTestName;
  }
  
  FileItemTest  *newSelectedTest = 
    [[testRepository testsByName] objectForKey: newSelectedTestName];

  // If highlighted test changed, update the description text view
  if (newSelectedTestName != selectedTestName) { 
    [selectedTestName release];
    selectedTestName = [newSelectedTestName retain];

    if (newSelectedTest != nil) {
      [testDescriptionView setString: [newSelectedTest description]];
    }
    else {
      [testDescriptionView setString: @""];
    }
  }
  
  // Update enabled status of buttons with context-dependent actions.
  BOOL  availableTestHighlighted = 
          ( selectedAvailableTestName != nil && availableTestsHighlighted );

  [editTestInRepositoryButton setEnabled: availableTestHighlighted];
  // Cannot remove an application-provided tess (it would automatically
  // re-appear anyway).
  [removeTestFromRepositoryButton setEnabled: 
    (availableTestHighlighted && 
      (newSelectedTest != [testRepository applicationProvidedTestForName: 
                                            selectedAvailableTestName])) ];

  [addTestToFilterButton setEnabled: availableTestHighlighted];
  [removeTestFromFilterButton setEnabled: 
    ( selectedFilterTest != nil && filterTestsHighlighted )];

  BOOL  nonEmptyFilter = ([filterTests count] > 0);

  [removeAllTestsFromFilterButton setEnabled: nonEmptyFilter];
  
  [okButton setEnabled: ( (nonEmptyFilter || allowEmptyFilter) &&
                          ![self isNameKnownInvalid] )];
}

- (void) updateWindowTitle {
  NSString  *name = [filterNameField stringValue];
  NSString  *title;
  if (name == nil || [name length]==0) {
    title = NSLocalizedString(@"Unnamed filter", @"Window title");
  }
  else {
    NSString  *format = NSLocalizedString(@"Filter - %@", @"Window title");
    title = [NSString stringWithFormat: format, name];
  }
  [[self window] setTitle: title];
}


- (void) textEditingStarted:(NSNotification *)notification {
  NSWindow  *window = [self window];
  BOOL  nameFieldIsFirstResponder =
    ( [[window firstResponder] isKindOfClass: [NSTextView class]] &&
      [window fieldEditor: NO forObject: nil] != nil &&
      [((NSTextView *)[window firstResponder]) delegate] == (id)filterNameField );

  if (nameFieldIsFirstResponder) { 
    // Disable Return key equivalent for OK button while editing is in 
    // progress. When the field is non-empty, Return should signal the end of
    // the edit session and enable the OK button, but not directly invoke it. 
    [okButton setKeyEquivalent: @""];
  }
}

- (void) textEditingStopped:(NSNotification *)notification {
  // Reenable the Return key equivalent again. It is done after a short delay
  // as otherwise it will still handle the Return key press that may have
  // triggered this event.
  [okButton performSelector: @selector(setKeyEquivalent:)
              withObject: @"\r" afterDelay: 0.1
              inModes: [NSArray arrayWithObjects: NSModalPanelRunLoopMode, 
                                                  NSDefaultRunLoopMode, nil]];
}


- (void) appDidUpdate:(NSNotification *)notification {
  // We want to detect when one of the filter views is newly selected (i.e.
  // became first responder) so that the description of the selected filter can
  // be updated. Apparently there are no events signalling first responder
  // changes, so doing it a bit more brute force.
  if ([[self window] firstResponder] != firstResponder) {
    [self updateWindowState: notification];
  }
}


- (BOOL) isNameKnownInvalid {
  NSString  *currentName = [filterNameField stringValue];
  return ( [currentName length] == 0 ||
           [currentName isEqualToString: invalidName] );
}


- (void) confirmTestRemovalAlertDidEnd:(NSAlert *)alert 
          returnCode:(int) returnCode contextInfo:(void *)testName {
  if (returnCode == NSAlertFirstButtonReturn) {
    // Delete confirmed.
    
    FileItemTest  *defaultTest = 
      [testRepository applicationProvidedTestForName: testName];
    NotifyingDictionary  *repositoryTestsByName =
      [testRepository testsByNameAsNotifyingDictionary];
    
    if (defaultTest == nil) {
      [repositoryTestsByName removeObjectForKey: testName];
    }
    else {
      // Replace it by the application-provided test with the same name
      // (this would happen anyway when the application is restarted).
      [repositoryTestsByName updateObject: defaultTest forKey: testName];
    }

    // Rest of delete handled in response to notification event.
  }
}

- (void) invalidNameAlertDidEnd:(NSAlert *)alert returnCode:(int) returnCode
           contextInfo:(void *)contextInfo {
}

@end // @implementation FilterWindowControl (PrivateMethods)
