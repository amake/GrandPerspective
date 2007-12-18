#import "PreferencesPanelControl.h"

#import "DirectoryViewControl.h"
#import "FileItemHashingCollection.h"
#import "ColorListCollection.h"
#import "FileSizeMeasureCollection.h"


NSString  *PreferencesChangedEvent = @"preferencesChanged";

NSString  *FileDeletionTargetsKey = @"fileDeletionTargets";
NSString  *ConfirmFileDeletionKey = @"confirmFileDeletion";


@interface PreferencesPanelControl (PrivateMethods)

- (void) updateButtonState;

@end

@implementation PreferencesPanelControl

// Special case: should not cover (override) super's designated initialiser in
// NSWindowController's case
- (id) init {
  if (self = [super initWithWindowNibName: @"PreferencesPanel" owner: self]) {
    changeSet = [[NSMutableSet alloc] initWithCapacity: 4];
    
    // Trigger loading of the window
    [self window];
  }

  return self;
}

- (void) dealloc {
  [localizedFileSizeMeasureNamesReverseLookup release];
  [localizedColorMappingNamesReverseLookup release];
  [localizedColorPaletteNamesReverseLookup release];
  
  [changeSet release];
  
  [super dealloc];
}


- (void) windowDidLoad {
  NSUserDefaults  *userDefaults = [NSUserDefaults standardUserDefaults];
  
  [[NSNotificationCenter defaultCenter]
      addObserver: self selector: @selector(windowWillClose:)
        name: NSWindowWillCloseNotification object: [self window]];

  // Note: These collections take care of setting the application default, so
  // they should be initialised before the defaults are retrieved.
  FileItemHashingCollection  *colorMappings = 
      [FileItemHashingCollection defaultFileItemHashingCollection];
  ColorListCollection  *colorPalettes = 
      [ColorListCollection defaultColorListCollection];
  FileSizeMeasureCollection  *fileSizeMeasures = 
      [FileSizeMeasureCollection defaultFileSizeMeasureCollection];

  [fileDeletionPopUp removeAllItems];
  localizedFileDeletionTargetNamesReverseLookup =
    [[DirectoryViewControl
        addLocalisedNamesToPopUp: fileDeletionPopUp
        names: [DirectoryViewControl fileDeletionTargetNames]
        selectName: [userDefaults stringForKey: FileDeletionTargetsKey]
        table: @"Names"] retain];
  [fileDeletionConfirmationCheckBox setState: 
     ([userDefaults boolForKey: ConfirmFileDeletionKey]
        ? NSOnState : NSOffState)];

  [fileSizeMeasurePopUp removeAllItems];
  localizedFileSizeMeasureNamesReverseLookup =
    [[DirectoryViewControl
        addLocalisedNamesToPopUp: fileSizeMeasurePopUp
        names: [fileSizeMeasures allKeys]
        selectName: [userDefaults stringForKey: @"fileSizeMeasure"]
        table: @"Names"] retain];

  [defaultColorMappingPopUp removeAllItems];  
  localizedColorMappingNamesReverseLookup =
    [[DirectoryViewControl
        addLocalisedNamesToPopUp: defaultColorMappingPopUp
        names: [colorMappings allKeys]
        selectName: [userDefaults stringForKey: @"defaultColorMapping"]
        table: @"Names"] retain];

  [defaultColorPalettePopUp removeAllItems];
  localizedColorPaletteNamesReverseLookup =
    [[DirectoryViewControl
        addLocalisedNamesToPopUp: defaultColorPalettePopUp
        names: [colorPalettes allKeys]
        selectName: [userDefaults stringForKey: @"defaultColorPalette"] 
        table: @"Names"] retain];

  [self updateButtonState];
  
  [[self window] center];
  [[self window] makeKeyAndOrderFront: self];
}


- (void) windowWillClose:(NSNotification*)notification {
   [self autorelease];
}


- (IBAction) cancelAction: (id)sender {
  [[self window] close];
}

- (IBAction) okAction: (id)sender {
  [[self window] close];

  NSUserDefaults  *userDefaults = [NSUserDefaults standardUserDefaults];

  if ([changeSet containsObject: fileDeletionPopUp]) {
    NSString  *localizedName = [fileDeletionPopUp titleOfSelectedItem];
    NSString  *name = [localizedFileDeletionTargetNamesReverseLookup 
                                          objectForKey: localizedName];

    [userDefaults setObject: name forKey: FileDeletionTargetsKey];
  }
  
  if ([changeSet containsObject: fileDeletionConfirmationCheckBox]) {
    BOOL  enabled = [fileDeletionConfirmationCheckBox state] == NSOnState;

    [userDefaults setBool: enabled forKey: ConfirmFileDeletionKey];
  }

  if ([changeSet containsObject: fileSizeMeasurePopUp]) {
    NSString  *localizedName = [fileSizeMeasurePopUp titleOfSelectedItem];
    NSString  *name = 
      [localizedFileSizeMeasureNamesReverseLookup objectForKey: localizedName];

    [userDefaults setObject: name forKey: @"fileSizeMeasure"];
  }

  if ([changeSet containsObject: defaultColorMappingPopUp]) {
    NSString  *localizedName = [defaultColorMappingPopUp titleOfSelectedItem];
    NSString  *name = 
      [localizedColorMappingNamesReverseLookup objectForKey: localizedName];

    [userDefaults setObject: name forKey: @"defaultColorMapping"];
  }
  
  if ([changeSet containsObject: defaultColorPalettePopUp]) {
    NSString  *localizedName = [defaultColorPalettePopUp titleOfSelectedItem];
    NSString  *name = 
      [localizedColorPaletteNamesReverseLookup objectForKey: localizedName];
    
    [userDefaults setObject: name forKey: @"defaultColorPalette"];
  }
  
  [changeSet removeAllObjects];
  
  [self updateButtonState];
  
  [[NSNotificationCenter defaultCenter]
      postNotificationName: PreferencesChangedEvent object: userDefaults];
}


- (IBAction) valueChanged: (id) sender {
  [changeSet addObject: sender];

  [self updateButtonState];
}

@end // @implementation PreferencesPanelControl


@implementation PreferencesPanelControl (PrivateMethods)

- (void) updateButtonState {
  [okButton setEnabled: [changeSet count] > 0];
  
  NSString  *localizedName = [fileDeletionPopUp titleOfSelectedItem];
  NSString  *name = 
    [localizedFileDeletionTargetNamesReverseLookup objectForKey: localizedName];
  [fileDeletionConfirmationCheckBox setEnabled:
    ! [name isEqualToString: DeleteNothing]];
}

@end // @implementation PreferencesPanelControl (PrivateMethods)
