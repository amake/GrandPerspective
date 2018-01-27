#import "FilterTestWindowControl.h"

#import "FileItem.h"

#import "FilterTest.h"

#import "FileItemTest.h"
#import "CompoundAndItemTest.h"
#import "ItemNameTest.h"
#import "ItemPathTest.h"
#import "ItemTypeTest.h"
#import "ItemSizeTest.h"
#import "ItemFlagsTest.h"
#import "SelectiveItemTest.h"

#import "MultiMatchStringTest.h"
#import "StringEqualityTest.h"
#import "StringContainmentTest.h"
#import "StringPrefixTest.h"
#import "StringSuffixTest.h"

#import "UniformType.h"
#import "UniformTypeInventory.h"

#import "ControlConstants.h"
#import "NameValidator.h"


// testTargetPopUp choices
#define POPUP_FILES              0
#define POPUP_FOLDERS            1
#define POPUP_FILES_AND_FOLDERS  2

// nameMatchPopUp and pathMatchPopUp choices
#define POPUP_STRING_IS           0
#define POPUP_STRING_CONTAINS     1
#define POPUP_STRING_STARTS_WITH  2
#define POPUP_STRING_ENDS_WITH    3

// typeMatchPopUp
#define POPUP_TYPE_CONFORMS_TO  0
#define POPUP_TYPE_EQUALS       1

// addTypeTargetButton
#define POPUP_ADD_TYPE  0

// hardLinkStatusPopUp and packageStatusPopUp
#define POPUP_FLAG_IS      0
#define POPUP_FLAG_IS_NOT  1

// sizeLowerBoundsUnits and sizeUpperBoundsUnits choices
#define POPUP_BYTES  0
#define POPUP_KB     1
#define POPUP_MB     2
#define POPUP_GB     3


@interface FilterTestWindowControl (PrivateMethods) 

- (void) resetState;
- (void) updateStateBasedOnTest:(FileItemTest *)test;
- (void) updateStateBasedOnItemNameTest:(ItemNameTest *)test;
- (void) updateStateBasedOnItemPathTest:(ItemPathTest *)test;
- (void) updateStateBasedOnItemTypeTest:(ItemTypeTest *)test;
- (void) updateStateBasedOnItemSizeTest:(ItemSizeTest *)test;
- (void) updateStateBasedOnItemFlagsTest:(ItemFlagsTest *)test;
- (FileItemTest *)updateStateBasedOnSelectiveItemTest:(SelectiveItemTest *)test;

- (ItemNameTest *)itemNameTestBasedOnState;
- (ItemPathTest *)itemPathTestBasedOnState;
- (ItemTypeTest *)itemTypeTestBasedOnState;
- (ItemSizeTest *)itemSizeTestBasedOnState;
- (ItemFlagsTest *)itemFlagsTestBasedOnState;
- (FileItemTest *)selectiveItemTestBasedOnState:(FileItemTest *)subTest;

- (IBAction) updateEnabledState:(id) sender;
- (void) updateWindowTitle;

- (BOOL) tryStopFieldEditor;

- (void) textEditingStarted:(NSNotification *)notification;
- (void) textEditingStopped:(NSNotification *)notification;

- (BOOL) isNameKnownInvalid;

- (void) invalidNameAlertDidEnd:(NSAlert *)alert returnCode:(int) returnCode
           contextInfo:(void *)contextInfo;

@end // @interface FilterTestWindowControl (PrivateMethods)


@interface MultiMatchControls 
  : NSObject <NSTableViewDataSource, NSTableViewDelegate> {
  NSPopUpButton  *matchPopUpButton;
  NSTableView  *targetsView;
  NSButton  *addTargetButton;
  NSButton  *removeTargetButton;

  NSMutableArray  *matchTargets;
  BOOL  enabled;
}

- (id) initWithMatchModePopUpButton:(NSPopUpButton *)popUpButton
         targetsView:(NSTableView *)targetsView
         addTargetButton:(NSButton *)addTargetButton
         removeTargetButton:(NSButton *)removeTargetButton;

- (void) resetState;

- (void) setEnabled:(BOOL) enabled;

- (BOOL) hasTargets;
- (void) addTarget;
- (void) removeTarget;

@end


@interface MultiMatchControls (PrivateMethods)

- (void) updateEnabledState;

@end


@interface StringMatchControls : MultiMatchControls {
  NSButton  *caseInsensitiveCheckBox;
  FilterTestWindowControl  *windowControl;
  
  /* Tracks if an edit of a match is in progress. If so, the list of matches
   * should not be manipulated, or the table ends up in an inconsistent state.
   */
  BOOL  editInProgress;
}
 
- (id) initWithMatchModePopUpButton:(NSPopUpButton *)popUpButton
         targetsView:(NSTableView *)targetsView
         caseInsensitiveCheckBox:(NSButton *)caseCheckBox
         addTargetButton:(NSButton *)addTargetButton
         removeTargetButton:(NSButton *)removeTargetButton
         windowControl:(FilterTestWindowControl *)windowControl;

- (void) updateStateBasedOnStringTest:(MultiMatchStringTest *)test;
- (MultiMatchStringTest *)stringTestBasedOnState;

@end // @interface StringMatchControls


@interface StringMatchControls (PrivateMethods)

- (void) didBeginEditing:(NSNotification *)notification;
- (void) didEndEditing:(NSNotification *)notification;

@end // @interface StringMatchControls (PrivateMethods)


@interface TypeMatchControls : MultiMatchControls {

}

- (void) updateStateBasedOnItemTypeTest:(ItemTypeTest *)test;
- (ItemTypeTest *)itemTypeTestBasedOnState;

@end


@implementation FilterTestWindowControl

+ (id) defaultInstance {
  FilterTestWindowControl  *defaultInstance = nil;

  if (defaultInstance == nil) {
    defaultInstance = [[FilterTestWindowControl alloc] init];
  }
  
  return defaultInstance;
}

// Special case: should not cover (override) super's designated initialiser in
// NSWindowController's case
- (id) init { 
  if (self = [super initWithWindowNibName: @"FilterTestWindow" owner: self]) {
    testName = nil;
    nameValidator = nil;
    invalidName = nil;
  }
  return self;
}


- (void) dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  
  [nameTestControls release];
  [pathTestControls release];
  [typeTestControls release];
  
  [testName release];
  [nameValidator release];
  [invalidName release];

  [super dealloc];
}


- (void) windowDidLoad {
  nameTestControls = [[StringMatchControls alloc]
                         initWithMatchModePopUpButton: nameMatchPopUpButton
                         targetsView: nameTargetsView
                         caseInsensitiveCheckBox: nameCaseInsensitiveCheckBox
                         addTargetButton: addNameTargetButton
                         removeTargetButton: removeNameTargetButton
                         windowControl: self];
  pathTestControls = [[StringMatchControls alloc]
                         initWithMatchModePopUpButton: pathMatchPopUpButton
                         targetsView: pathTargetsView
                         caseInsensitiveCheckBox: pathCaseInsensitiveCheckBox
                         addTargetButton: addPathTargetButton
                         removeTargetButton: removePathTargetButton
                         windowControl: self];
  typeTestControls = [[TypeMatchControls alloc]
                         initWithMatchModePopUpButton: typeMatchPopUpButton
                         targetsView: typeTargetsView
                         addTargetButton: addTypeTargetButton
                         removeTargetButton: removeTypeTargetButton];

  NSNotificationCenter  *nc = [NSNotificationCenter defaultCenter];
  [nc addObserver: self selector: @selector(textEditingStarted:) 
          name: NSTextDidBeginEditingNotification object: nil];
  [nc addObserver: self selector: @selector(textEditingStopped:) 
          name: NSTextDidEndEditingNotification object: nil];

  [self updateEnabledState: nil];
}


- (NSString *)fileItemTestName {
  if ([testNameField isEnabled]) {
    // No fixed "visible" name was set, so get the name from the text field.
    return [testNameField stringValue];
  }
  else {
    // The test name field was showing the test's visible name. Return its
    // original name.
    return testName;
  }
}


- (void) setNameValidator:(NSObject<NameValidator> *)validator {
  if (validator != nameValidator) {
    [nameValidator release];
    nameValidator = [validator retain];
  }
}


// Configures the window to represent the given test.
- (void) representFilterTest:(FilterTest *)filterTest {
  [self resetState];
  
  if (filterTest == nil) {
    // No test specified. Leave window in default state.
    return;
  }
  
  // Remember the original name of the test
  [testName release];
  testName = [[filterTest name] retain];
  [testNameField setStringValue: testName];  
  FileItemTest  *test = [filterTest fileItemTest];
  
  if ([test isKindOfClass: [SelectiveItemTest class]]) {
    // It is a selective test. Update state and continue with its subtest
    
    test = [self updateStateBasedOnSelectiveItemTest: 
                   (SelectiveItemTest *)test];
  }
  else {
    [testTargetPopUp selectItemAtIndex: POPUP_FILES_AND_FOLDERS];
  }

  
  if ([test isKindOfClass:[CompoundAndItemTest class]]) {
    // It is a compound test. Iterate over all subtests.
    NSEnumerator  *subTests = 
      [[((CompoundAndItemTest *)test) subItemTests] objectEnumerator];
    FileItemTest  *subTest;
    while (subTest = [subTests nextObject]) {
      [self updateStateBasedOnTest:subTest];
    } 
  }
  else {
    // It is a stand-alone test.
    [self updateStateBasedOnTest:test];
  } 

  [self updateWindowTitle];
  [self updateEnabledState: nil];
}

- (FilterTest *)createFilterTest {
  NSMutableArray  *subTests = [NSMutableArray arrayWithCapacity: 4];
  FileItemTest  *subTest;
  
  subTest = [self itemNameTestBasedOnState];
  if (subTest != nil) {
    [subTests addObject: subTest];
  }
  
  subTest = [self itemPathTestBasedOnState];
  if (subTest != nil) {
    [subTests addObject: subTest];
  }

  subTest = [self itemFlagsTestBasedOnState];
  if (subTest != nil) {
    [subTests addObject: subTest];
  }
  
  if ( [testTargetPopUp indexOfSelectedItem] == POPUP_FILES ) {
    // Add any file-only tests
    
    subTest = [self itemSizeTestBasedOnState];
    if (subTest != nil) {
      [subTests addObject: subTest];
    }
    
    subTest = [self itemTypeTestBasedOnState];
    if (subTest != nil) {
      [subTests addObject: subTest];
    }
  }
  
  FileItemTest  *test;
  if ([subTests count] == 0) {
    test = nil;
  }
  else if ([subTests count] == 1) {
    test = [subTests lastObject];
  }
  else {
    test = [[[CompoundAndItemTest alloc] initWithSubItemTests:subTests]
                autorelease];
  }
  
  test = [self selectiveItemTestBasedOnState: test];
    
  return [FilterTest filterTestWithName: [self fileItemTestName] 
                       fileItemTest: test];
}

- (void) setVisibleName:(NSString *)name {
  [testNameField setStringValue: name];
  [testNameField setEnabled: NO];
  [self updateWindowTitle];
}


- (void)windowDidBecomeKey:(NSNotification *)notification {
  finalNotificationFired = NO; 
  
  if (invalidName) {
    [[self window] makeFirstResponder: testNameField];
  }
}

- (BOOL) windowShouldClose:(id) window {
  return [self tryStopFieldEditor];
}

- (void) windowWillClose:(NSNotification *)notification {
  if ( !finalNotificationFired ) {
    // The window is closing while no "okPerformed" or "cancelPerformed" has
    // been fired yet. This means that the user is closing the window using
    // the window's red close button.
    
    finalNotificationFired = YES;
    [[NSNotificationCenter defaultCenter] 
        postNotificationName: ClosePerformedEvent object: self];
  }
}

- (IBAction) cancelAction:(id) sender {
  // Note: The window's Cancel key should have the Escape key as equivalent to
  // ensure that this method also gets invoked when the Escape key is pressed.
  // Otherwise, the Escape key will immediately close the window.

  if ([self tryStopFieldEditor]) {
    finalNotificationFired = YES;
    [[NSNotificationCenter defaultCenter] 
        postNotificationName: CancelPerformedEvent object: self];
  }
}

- (IBAction) okAction:(id) sender {
  if ([self tryStopFieldEditor]) {
    // If the field editor was active, it resigned its first responder status,
    // meaning that the window can be closed.

    // Check if the name of the test is okay as well.
    NSString  *errorMsg = 
      [nameValidator checkNameIsValid: [self fileItemTestName]];
      
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
      invalidName = [[self fileItemTestName] retain];
    }
    else {
      finalNotificationFired = YES;
      [[NSNotificationCenter defaultCenter] 
          postNotificationName: OkPerformedEvent object: self];
    }
  }
}


- (IBAction) testNameChanged:(id) sender {
  [self updateWindowTitle];
  [self updateEnabledState: nil];
}

// Auto-corrects the lower/upper bound fields so that they contain a valid
// numeric value.
- (IBAction) sizeBoundEntered:(id) sender {
  int  value = [sender intValue];
  
  if (value < 0) {
    value = 0;
  }
  
  [sender setIntValue: value];
}


- (IBAction) targetPopUpChanged:(id) sender {
  [self updateEnabledState: sender];
}


- (IBAction) nameCheckBoxChanged:(id) sender {
  [self updateEnabledState: sender];
}

- (IBAction) pathCheckBoxChanged:(id) sender {
  [self updateEnabledState: sender];
}

- (IBAction) hardLinkCheckBoxChanged:(id) sender {
  [self updateEnabledState: sender];
}

- (IBAction) packageCheckBoxChanged:(id) sender {
  [self updateEnabledState: sender];
}

- (IBAction) typeCheckBoxChanged:(id) sender {
  [self updateEnabledState: sender];
}

- (IBAction) lowerBoundCheckBoxChanged:(id) sender {
  [self updateEnabledState: sender];
  
  if ([sender state]==NSOnState) {
    [[self window] makeFirstResponder: sizeLowerBoundField];
  }
}

- (IBAction) upperBoundCheckBoxChanged:(id) sender { 
  [self updateEnabledState: sender];
  
  if ([sender state]==NSOnState) {
    [[self window] makeFirstResponder: sizeUpperBoundField];
  }
}


- (IBAction) addNameTarget:(id) sender {
  [nameTestControls addTarget];
  [self updateEnabledState: nil];
}

- (IBAction) removeNameTarget:(id) sender {
  [nameTestControls removeTarget];
  [self updateEnabledState: nil];
}

- (IBAction) addPathTarget:(id) sender {
  [pathTestControls addTarget];
  [self updateEnabledState: nil];
}

- (IBAction) removePathTarget:(id) sender {
  [pathTestControls removeTarget];
  [self updateEnabledState: nil];
}

- (IBAction) addTypeTarget:(id) sender {
  [typeTestControls addTarget];
  [self updateEnabledState: nil];
}

- (IBAction) removeTypeTarget:(id) sender {
  [typeTestControls removeTarget];
  [self updateEnabledState: nil];
}


@end // @implementation FilterTestWindowControl


@implementation FilterTestWindowControl (PrivateMethods) 

- (void) resetState {
  [testNameField setStringValue: @""];
  [testNameField setEnabled: YES];
  
  // Forget about any previously reported invalid names.
  [invalidName release];
  invalidName = nil;
  
  [testTargetPopUp selectItemAtIndex: POPUP_FILES];

  [nameCheckBox setState: NSOffState];
  [nameTestControls resetState];
  
  [pathCheckBox setState: NSOffState];
  [pathTestControls resetState];

  [typeCheckBox setState: NSOffState];
  [typeTestControls resetState];

  [sizeLowerBoundCheckBox setState: NSOffState];
  [sizeLowerBoundField setIntValue: 0];
  [sizeLowerBoundUnits selectItemAtIndex: POPUP_BYTES];
  
  [sizeUpperBoundCheckBox setState: NSOffState];
  [sizeUpperBoundField setIntValue: 0];
  [sizeUpperBoundUnits selectItemAtIndex: POPUP_BYTES];
  
  [hardLinkCheckBox setState: NSOffState];
  [hardLinkStatusPopUp selectItemAtIndex: POPUP_FLAG_IS];

  [packageCheckBox setState: NSOffState];
  [packageStatusPopUp selectItemAtIndex: POPUP_FLAG_IS];
  
  [self updateWindowTitle];
  [self updateEnabledState: nil];
}


- (void) updateStateBasedOnTest:(FileItemTest *)test {
  if ([test isKindOfClass: [ItemNameTest class]]) {
    [self updateStateBasedOnItemNameTest: (ItemNameTest *)test];
  }
  else if ([test isKindOfClass: [ItemPathTest class]]) {
    [self updateStateBasedOnItemPathTest: (ItemPathTest *)test];
  }
  else if ([test isKindOfClass: [ItemTypeTest class]]) {
    [self updateStateBasedOnItemTypeTest: (ItemTypeTest *)test];
  }
  else if ([test isKindOfClass: [ItemSizeTest class]]) {
    [self updateStateBasedOnItemSizeTest: (ItemSizeTest *)test];
  }
  else if ([test isKindOfClass: [ItemFlagsTest class]]) {
    [self updateStateBasedOnItemFlagsTest: (ItemFlagsTest *)test];
  }

  else {
    NSAssert(NO, @"Unexpected test.");
  }
}


- (void) updateStateBasedOnItemNameTest:(ItemNameTest *)test {
  MultiMatchStringTest  *stringTest = (MultiMatchStringTest*)[test stringTest];
  
  [nameTestControls updateStateBasedOnStringTest: stringTest];
  [nameCheckBox setState: NSOnState];
}


- (void) updateStateBasedOnItemPathTest:(ItemPathTest *)test {
  MultiMatchStringTest  *stringTest = (MultiMatchStringTest*)[test stringTest];
  
  [pathTestControls updateStateBasedOnStringTest: stringTest];
  [pathCheckBox setState: NSOnState];
}


- (void) updateStateBasedOnItemTypeTest:(ItemTypeTest *)test {
  [typeTestControls updateStateBasedOnItemTypeTest: test];
  [typeCheckBox setState: NSOnState];
}


- (void) updateStateBasedOnItemSizeTest:(ItemSizeTest *)test {
  int  bytesUnit = [FileItem bytesPerKilobyte];
  
  if ([test hasLowerBound]) {
    ITEM_SIZE  bound = [test lowerBound];
    int  i = POPUP_BYTES;
    
    if (bound > 0) {
      while (i < POPUP_GB && (bound % bytesUnit)==0) {
        i++;
        bound /= bytesUnit;
      }
    }
    
    [sizeLowerBoundCheckBox setState: NSOnState]; 
    [sizeLowerBoundField setIntegerValue: bound];
    [sizeLowerBoundUnits selectItemAtIndex: i]; 
  }

  if ([test hasUpperBound]) {
    ITEM_SIZE  bound = [test upperBound];
    int  i = POPUP_BYTES;
          
    if (bound > 0) {
      while (i < POPUP_GB && (bound % bytesUnit)==0) {
        i++;
        bound /= bytesUnit;
      }
    }
    
    [sizeUpperBoundCheckBox setState: NSOnState];
    [sizeUpperBoundField setIntegerValue: bound];
    [sizeUpperBoundUnits selectItemAtIndex: i];
  }
}


- (void) updateStateBasedOnItemFlagsTest:(ItemFlagsTest *)test {
  if ([test flagsMask] & FILE_IS_HARDLINKED) {
    [hardLinkCheckBox setState: NSOnState];
    
    [hardLinkStatusPopUp selectItemAtIndex: 
       ( ([test desiredResult] & FILE_IS_HARDLINKED) 
         ? POPUP_FLAG_IS 
         : POPUP_FLAG_IS_NOT ) ];
  }
  
  if ([test flagsMask] & FILE_IS_PACKAGE) {
    [packageCheckBox setState: NSOnState];
    
    [packageStatusPopUp selectItemAtIndex: 
       ( ([test desiredResult] & FILE_IS_PACKAGE) 
         ? POPUP_FLAG_IS 
         : POPUP_FLAG_IS_NOT ) ];
  }
}


- (FileItemTest *)updateStateBasedOnSelectiveItemTest: 
                    (SelectiveItemTest *)test {
  [testTargetPopUp selectItemAtIndex: ( [test applyToFilesOnly] 
                                        ? POPUP_FILES 
                                        : POPUP_FOLDERS ) ];
  
  return [test subItemTest];
}


- (ItemNameTest *)itemNameTestBasedOnState {
  if ([nameCheckBox state] != NSOnState) {
    return nil;
  }
  
  MultiMatchStringTest  *stringTest = [nameTestControls stringTestBasedOnState];
  return ( (stringTest != nil )
           ? [[[ItemNameTest alloc] initWithStringTest: stringTest] autorelease]
           : nil );
}


- (ItemPathTest *)itemPathTestBasedOnState {
  if ([pathCheckBox state] != NSOnState) {
    return nil;
  }
  
  MultiMatchStringTest  *stringTest = [pathTestControls stringTestBasedOnState];
  
  return ( (stringTest != nil)
           ? [[[ItemPathTest alloc] initWithStringTest: stringTest] autorelease]
           : nil );
}


- (ItemTypeTest *)itemTypeTestBasedOnState {
  return ( ([typeCheckBox state] == NSOnState)
           ? [typeTestControls itemTypeTestBasedOnState] 
           : nil );
}


- (ItemSizeTest *)itemSizeTestBasedOnState {
  int  bytesUnit = [FileItem bytesPerKilobyte];

  ITEM_SIZE  lowerBound = MAX(0, [sizeLowerBoundField intValue]);
  NSUInteger  i = [sizeLowerBoundUnits indexOfSelectedItem];
  while (i-- > 0) {
    lowerBound *= bytesUnit;
  }

  ITEM_SIZE  upperBound = MAX(0, [sizeUpperBoundField intValue]);
  i = [sizeUpperBoundUnits indexOfSelectedItem];
  while (i-- > 0) {
    upperBound *= bytesUnit;
  }
  
  if ([sizeLowerBoundCheckBox state]==NSOnState && lowerBound>0) {
    if ([sizeUpperBoundCheckBox state]==NSOnState) {
      return [[[ItemSizeTest alloc] 
                  initWithLowerBound:lowerBound upperBound:upperBound] 
                  autorelease];
    }
    else {
      return [[[ItemSizeTest alloc] initWithLowerBound:lowerBound] autorelease];
    }
  }
  else {
    if ([sizeUpperBoundCheckBox state]==NSOnState) {
      return [[[ItemSizeTest alloc] initWithUpperBound:upperBound] autorelease];
    }
    else {
      return nil;
    }
  }
}


- (ItemFlagsTest *)itemFlagsTestBasedOnState {
  UInt8  flagsMask = 0;
  UInt8  desiredResult = 0;
  
  if ([hardLinkCheckBox state] == NSOnState) {
    flagsMask |= FILE_IS_HARDLINKED;
    if ([hardLinkStatusPopUp indexOfSelectedItem] == POPUP_FLAG_IS) {
      desiredResult |= FILE_IS_HARDLINKED;
    }
  }
  
  if ([packageCheckBox state] == NSOnState) {
    flagsMask |= FILE_IS_PACKAGE;
    if ([packageStatusPopUp indexOfSelectedItem] == POPUP_FLAG_IS) {
      desiredResult |= FILE_IS_PACKAGE;
    }
  }
  
  if (flagsMask) {
    return [[[ItemFlagsTest alloc] initWithFlagsMask: flagsMask 
                                     desiredResult: desiredResult] autorelease];
  }
  else {
    return nil;
  }
}


- (FileItemTest *)selectiveItemTestBasedOnState:(FileItemTest *)subTest {
  NSUInteger  index = [testTargetPopUp indexOfSelectedItem];
  
  if (index == POPUP_FILES_AND_FOLDERS) { 
    return subTest;
  }
  else {
    BOOL  onlyFiles = (index == POPUP_FILES);
  
    return [[[SelectiveItemTest alloc] initWithSubItemTest: subTest 
                                         onlyFiles: onlyFiles] autorelease];
  } 
}


- (IBAction) updateEnabledState:(id) sender {
  // Note: "sender" is ignored. Always updating all.
  
  BOOL  targetsOnlyFiles = 
          [testTargetPopUp indexOfSelectedItem] == POPUP_FILES;
  
  BOOL  nameTestUsed = [nameCheckBox state]==NSOnState;
  BOOL  pathTestUsed = [pathCheckBox state]==NSOnState;
  BOOL  hardLinkTestUsed = [hardLinkCheckBox state]==NSOnState;
  BOOL  packageTestUsed = [packageCheckBox state]==NSOnState;
  BOOL  typeTestUsed = ( [typeCheckBox state]==NSOnState && targetsOnlyFiles );
  BOOL  lowerBoundTestUsed = ( [sizeLowerBoundCheckBox state]==NSOnState
                               && targetsOnlyFiles );
  BOOL  upperBoundTestUsed = ( [sizeUpperBoundCheckBox state]==NSOnState
                               && targetsOnlyFiles );
  
  [nameTestControls setEnabled: nameTestUsed];
  [pathTestControls setEnabled: pathTestUsed];

  [hardLinkStatusPopUp setEnabled: hardLinkTestUsed];
  [packageStatusPopUp setEnabled: packageTestUsed];
  
  [typeCheckBox setEnabled: targetsOnlyFiles];
  [typeTestControls setEnabled: typeTestUsed];
  
  [sizeLowerBoundCheckBox setEnabled: targetsOnlyFiles];
  [sizeLowerBoundField setEnabled: lowerBoundTestUsed];
  [sizeLowerBoundUnits setEnabled: lowerBoundTestUsed];

  [sizeUpperBoundCheckBox setEnabled: targetsOnlyFiles];
  [sizeUpperBoundField setEnabled: upperBoundTestUsed];
  [sizeUpperBoundUnits setEnabled: upperBoundTestUsed];

  [okButton setEnabled:
     ![self isNameKnownInvalid]
     && ( ( nameTestUsed && [nameTestControls hasTargets] )
          || ( pathTestUsed && [pathTestControls hasTargets] )
          || ( typeTestUsed && [typeTestControls hasTargets] )
          || lowerBoundTestUsed 
          || upperBoundTestUsed 
          || hardLinkTestUsed
          || packageTestUsed) ];
}


- (void) updateWindowTitle {
  NSString  *name = [testNameField stringValue];
  NSString  *title;
  if (name == nil || [name length]==0) {
    title = NSLocalizedString(@"Unnamed filter test", @"Window title");
  }
  else {
    NSString  *format = NSLocalizedString(@"Filter test - %@", @"Window title");
    title = [NSString stringWithFormat: format, name];
  }
  [[self window] setTitle: title];
}


- (BOOL) tryStopFieldEditor {
  // Try making the window first responder. If this fails, it means that a 
  // field editor is being used that does not want to give up its first 
  // responder status because its delegate tells it not to (because its text 
  // value is still invalid).
  //
  // The field editor can be made to give up its first responder status by 
  // "brute force" using endEditingFor:. However, this then requires extra work
  // to ensure the state is consistent, and does not seem worth the effort.
  return ([[self window] makeFirstResponder: [self window]]);
}


- (void) textEditingStarted:(NSNotification *)notification {
  NSWindow  *window = [self window];
  BOOL  nameFieldIsFirstResponder =
    ( [[window firstResponder] isKindOfClass: [NSTextView class]] &&
      [window fieldEditor: NO forObject: nil] != nil &&
      [((NSTextView *)[window firstResponder]) delegate] == (id)testNameField );

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


- (BOOL) isNameKnownInvalid {
  NSString  *currentName = [testNameField stringValue];
  return ( [currentName length] == 0 ||
           [currentName isEqualToString: invalidName] );
}

- (void) invalidNameAlertDidEnd:(NSAlert *)alert returnCode:(int) returnCode
           contextInfo:(void *)contextInfo {
}

@end // @implementation FilterTestWindowControl (PrivateMethods) 


@implementation MultiMatchControls

- (id) initWithMatchModePopUpButton:(NSPopUpButton *)popUpButton
         targetsView:(NSTableView *)targetsTableViewVal
         addTargetButton:(NSButton *)addButton
         removeTargetButton:(NSButton *)removeButton {
  if (self = [super init]) {
    matchPopUpButton = [popUpButton retain];
    targetsView = [targetsTableViewVal retain];
    addTargetButton = [addButton retain];
    removeTargetButton = [removeButton retain];
    
    matchTargets = [[NSMutableArray alloc] initWithCapacity: 4];
    
    [targetsView setDataSource: self];
    [targetsView setDelegate: self]; 
  }
  
  return self;
}


- (void) dealloc {
  [matchPopUpButton release];
  [targetsView release];
  [addTargetButton release];
  [removeTargetButton release];
  
  [matchTargets release];

  [super dealloc];
}


- (void) resetState {
  [matchPopUpButton selectItemAtIndex: 0];
  
  [matchTargets removeAllObjects];
  [targetsView reloadData];
}


- (void) setEnabled:(BOOL) enabledVal {
  enabled = enabledVal;
  
  [self updateEnabledState];
}


- (BOOL) hasTargets {
  return [matchTargets count] > 0;
}

- (void) addTarget {
  NSAssert(NO, @"Abtract method");
}

- (void) removeTarget {
  NSInteger  selectedRow = [targetsView selectedRow];

  NSAssert(selectedRow >= 0, @"No row selected");
  [matchTargets removeObjectAtIndex: selectedRow];

  if (selectedRow == [matchTargets count] && selectedRow > 0) {
    [targetsView selectRowIndexes: [NSIndexSet indexSetWithIndex: selectedRow - 1] 
             byExtendingSelection: NO];
  }

  [targetsView reloadData];
}


//----------------------------------------------------------------------------
// Delegate methods for NSTable

- (void) tableViewSelectionDidChange:(NSNotification *)notification {
  [self updateEnabledState];
}


//----------------------------------------------------------------------------
// NSTableSource

- (NSInteger) numberOfRowsInTableView:(NSTableView *)tableView {
  return [matchTargets count];
}

- (id) tableView:(NSTableView *)tableView 
         objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger) row {
  return [matchTargets objectAtIndex: row];
}

@end // @implementation MultiMatchControls


@implementation MultiMatchControls (PrivateMethods)

- (void) updateEnabledState {
  [matchPopUpButton setEnabled: enabled];
  [targetsView setEnabled: enabled];
  [addTargetButton setEnabled: enabled];
  [removeTargetButton setEnabled: (enabled 
                                   && [targetsView numberOfSelectedRows] > 0)];
}

@end // @implementation MultiMatchControls (PrivateMethods)


@implementation StringMatchControls

// Overrides designated initialiser
- (id) initWithMatchModePopUpButton:(NSPopUpButton *)popUpButton
         targetsView:(NSTableView *)targetsTableViewVal
         addTargetButton:(NSButton *)addButton
         removeTargetButton:(NSButton *)removeButton {
  NSAssert(NO, @"Use other initialiser.");
  return nil;
}

- (id) initWithMatchModePopUpButton:(NSPopUpButton *)popUpButton
         targetsView:(NSTableView *)targetsTableViewVal
         caseInsensitiveCheckBox:(NSButton *)caseCheckBox
         addTargetButton:(NSButton *)addButton
         removeTargetButton:(NSButton *)removeButton 
         windowControl:(FilterTestWindowControl *)windowControlVal {
  if (self = [super initWithMatchModePopUpButton: popUpButton
                      targetsView: targetsTableViewVal
                      addTargetButton: addButton
                      removeTargetButton: removeButton]) {
    caseInsensitiveCheckBox = [caseCheckBox retain];
    windowControl = [windowControlVal retain];
    
    editInProgress = NO;
    
    NSNotificationCenter  *nc = [NSNotificationCenter defaultCenter];

    [nc addObserver: self selector: @selector(didBeginEditing:)
          name: NSControlTextDidBeginEditingNotification object: targetsView];
    [nc addObserver: self selector: @selector(didEndEditing:)
          name: NSControlTextDidEndEditingNotification object: targetsView];
  }
  
  return self;
}


- (void) dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver: self];

  [caseInsensitiveCheckBox release];
  [windowControl release];

  [super dealloc];
}


- (void) resetState {
  [super resetState];
  
  [matchPopUpButton selectItemAtIndex: POPUP_STRING_IS];
  [caseInsensitiveCheckBox setState: NSOffState];
}


- (void) addTarget {
  NSAssert(!editInProgress, @"Cannot edit target while edit in progress.");

  if (![windowControl tryStopFieldEditor]) {
    // Another field editor is already active and does not want to resign
    // first responder status.
    return;
  }

  NSUInteger  newRow = [matchTargets count];
  
  [matchTargets addObject: 
     NSLocalizedString( @"New match", 
                        @"Initial match value in FilterTestWindow" ) ];
  [targetsView reloadData];
  [targetsView selectRowIndexes: [NSIndexSet indexSetWithIndex: newRow]
           byExtendingSelection: NO];
  
  editInProgress = YES;
  [self updateEnabledState];
  
  [targetsView editColumn: 0 row: newRow withEvent: nil select: YES];
}

- (void) removeTarget {
  NSAssert(!editInProgress, @"Cannot remove target while edit in progress.");
  
  [super removeTarget];
}


- (void) updateStateBasedOnStringTest:(MultiMatchStringTest *)test {
  int  index = -1;
    
  if ([test isKindOfClass: [StringEqualityTest class]]) {
    index = POPUP_STRING_IS;
  }
  else if ([test isKindOfClass: [StringContainmentTest class]]) {
    index = POPUP_STRING_CONTAINS;
  }
  else if ([test isKindOfClass: [StringPrefixTest class]]) {
    index = POPUP_STRING_STARTS_WITH;
  }
  else if ([test isKindOfClass: [StringSuffixTest class]]) {
    index = POPUP_STRING_ENDS_WITH;
  }
  else {
    NSAssert(NO, @"Unknown string test.");
  }
  [matchPopUpButton selectItemAtIndex: index];
  
  [matchTargets removeAllObjects];
  [matchTargets addObjectsFromArray: [test matchTargets]];
  [targetsView reloadData];
  
  [caseInsensitiveCheckBox setState:
     ([test isCaseSensitive] ? NSOffState : NSOnState)];
}


- (MultiMatchStringTest *)stringTestBasedOnState {
  if (! [self hasTargets]) {
    return nil;
  }
  
  MultiMatchStringTest  *stringTest = nil;
  switch ([matchPopUpButton indexOfSelectedItem]) {
    case POPUP_STRING_IS: 
      stringTest = [StringEqualityTest alloc]; 
      break;
    case POPUP_STRING_CONTAINS: 
      stringTest = [StringContainmentTest alloc]; 
      break;
    case POPUP_STRING_STARTS_WITH: 
      stringTest = [StringPrefixTest alloc]; 
      break;
    case POPUP_STRING_ENDS_WITH: 
      stringTest = [StringSuffixTest alloc]; 
      break;
    default: NSAssert(NO, @"Unexpected matching index.");
  }
      
  BOOL  caseSensitive = ([caseInsensitiveCheckBox state] == NSOffState);
  stringTest = [[stringTest initWithMatchTargets: matchTargets
                              caseSensitive: caseSensitive] autorelease];
      
  return stringTest;
}


//----------------------------------------------------------------------------
// Delegate methods for NSTable

- (BOOL) control:(NSControl *)control textShouldEndEditing:(NSText *)editor {
  return [[editor string] length] > 0;
}


//----------------------------------------------------------------------------
// NSTableSource

- (void) tableView:(NSTableView *)tableView setObjectValue:(id) object 
           forTableColumn:(NSTableColumn *)column row:(NSInteger) row {
  [matchTargets replaceObjectAtIndex: row withObject: object];
}

- (BOOL) tableView:(NSTableView *)tableView 
           shouldEditTableColumn:(NSTableColumn *)column row:(NSInteger) row {
  if (![tableView isEnabled] || 
      ![windowControl tryStopFieldEditor]) {
    return NO;
  }
           
  // Switch to "edit in progress" mode immediately. If not done here, the
  // notification is only sent when the first change is made to the text.
  // However, we like to disable the Remove button as soon as the field editor
  // is active. Otherwise, removal will first remove the cell, then stop the
  // field editor, which overwrites the old value over what has become a
  // different target alltogether.
  [self didBeginEditing: nil];

  return YES;
}


@end // implementation StringMatchControls


@implementation StringMatchControls (PrivateMethods)

- (void) updateEnabledState {
  [super updateEnabledState];
  
  [caseInsensitiveCheckBox setEnabled: enabled];
  
  if (editInProgress) {
    [addTargetButton setEnabled: NO];
    [removeTargetButton setEnabled: NO];
  }
}


- (void) didBeginEditing:(NSNotification *)notification {
  editInProgress = YES;
  
  [self updateEnabledState];
}

- (void) didEndEditing:(NSNotification *)notification {
  editInProgress = NO;

  [self updateEnabledState];
}

@end // @implementation StringMatchControls (PrivateMethods)


@implementation TypeMatchControls

- (id) initWithMatchModePopUpButton:(NSPopUpButton *)popUpButton
         targetsView:(NSTableView *)targetsTableViewVal
         addTargetButton:(NSButton *)addButton
         removeTargetButton:(NSButton *)removeButton {
  if (self = [super initWithMatchModePopUpButton: popUpButton
                      targetsView: targetsTableViewVal
                      addTargetButton: addButton
                      removeTargetButton: removeButton]) {

    // Add all known UniformTypes to the "Add target" popup button
    UniformTypeInventory  *typeInventory = 
      [UniformTypeInventory defaultUniformTypeInventory];

    NSMutableArray  *unsortedTypes = 
      [NSMutableArray arrayWithCapacity: [typeInventory count]];
    NSEnumerator  *typesEnum = [typeInventory uniformTypeEnumerator];
    UniformType  *type;
    while (type = [typesEnum nextObject]) {
      [unsortedTypes addObject: [type uniformTypeIdentifier]];
    }
    
    NSArray  *sortedTypes =
               [unsortedTypes sortedArrayUsingSelector: @selector(compare:)]; 
    [((NSPopUpButton *)addButton) addItemsWithTitles: sortedTypes];
  }
  
  return self;
}


- (void) resetState {
  [super resetState];

  [matchPopUpButton selectItemAtIndex: POPUP_TYPE_CONFORMS_TO];
  [((NSPopUpButton *)addTargetButton) selectItemAtIndex: POPUP_ADD_TYPE];
}


- (void) addTarget {
  NSPopUpButton  *popUp = (NSPopUpButton *)addTargetButton;
  NSInteger  selectedIndex = [popUp indexOfSelectedItem];
  if (selectedIndex <= 0) {
    return;
  }

  UniformTypeInventory  *typeInventory = 
    [UniformTypeInventory defaultUniformTypeInventory];

  UniformType  *type = 
    [typeInventory uniformTypeForIdentifier: [popUp titleOfSelectedItem]];
  // Restore popup state
  [popUp selectItemAtIndex: POPUP_ADD_TYPE];

  NSUInteger  newRow = [matchTargets count];

  [matchTargets addObject: type];
  [targetsView reloadData];
  [targetsView selectRowIndexes: [NSIndexSet indexSetWithIndex: newRow]
           byExtendingSelection: NO];
  
  [self updateEnabledState];
}


- (void) updateStateBasedOnItemTypeTest: (ItemTypeTest *)test {
  [matchPopUpButton selectItemAtIndex: ( [test isStrict] 
                                         ? POPUP_TYPE_EQUALS
                                         : POPUP_TYPE_CONFORMS_TO )];
  
  [matchTargets removeAllObjects];
  [matchTargets addObjectsFromArray: [test matchTargets]];
  [targetsView reloadData];
}

- (ItemTypeTest *)itemTypeTestBasedOnState {
  if (! [self hasTargets]) {
    return nil;
  }
  
  BOOL  isStrict = [matchPopUpButton indexOfSelectedItem] == POPUP_TYPE_EQUALS;

  return [[[ItemTypeTest alloc] initWithMatchTargets: matchTargets
                                  strict: isStrict] autorelease];
}


//----------------------------------------------------------------------------
// NSTableSource

- (id) tableView:(NSTableView *)tableView 
         objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger) row {
  return [[matchTargets objectAtIndex: row] uniformTypeIdentifier];
}

@end // @implementation TypeMatchControls


