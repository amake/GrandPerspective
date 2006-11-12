#import "PreferencesPanelControl.h"

#import "DirectoryViewControl.h"
#import "FileItemHashingCollection.h"
#import "ColorListCollection.h"


@interface PreferencesPanelControl (PrivateMethods)

- (void) updateButtonState;

@end

@implementation PreferencesPanelControl

// Special case: should not cover (override) super's designated initialiser in
// NSWindowController's case
- (id) init {
  if (self = [super initWithWindowNibName: @"PreferencesPanel" owner: self]) {
    defaultColorMappingChanged = NO;
    defaultColorPaletteChanged = NO;
  }

  return self;
}

- (void) dealloc {
  [localisedColorMappingNamesReverseLookup release];
  [localisedColorPaletteNamesReverseLookup release];
  
  [super dealloc];
}


- (void) windowDidLoad {
  NSUserDefaults  *userDefaults = [NSUserDefaults standardUserDefaults];
  
  FileItemHashingCollection  *colorMappings = 
      [[FileItemHashingCollection defaultFileItemHashingCollection] retain];
  ColorListCollection  *colorPalettes = 
      [[ColorListCollection defaultColorListCollection] retain];
  
  [defaultColorMappingPopUp removeAllItems];  
  localisedColorMappingNamesReverseLookup =
    [[DirectoryViewControl
        addLocalisedNamesToPopUp: defaultColorMappingPopUp
        names: [colorMappings allKeys]
        selectName: [userDefaults stringForKey: @"defaultColorMapping"]
        table: @"mappings"] retain];

  [defaultColorPalettePopUp removeAllItems];
  localisedColorPaletteNamesReverseLookup =
    [[DirectoryViewControl
        addLocalisedNamesToPopUp: defaultColorPalettePopUp
        names: [colorPalettes allKeys]
        selectName: [userDefaults stringForKey: @"defaultColorPalette"] 
        table: @"palettes"] retain];

  [self updateButtonState];
}


- (IBAction) cancelAction: (id)sender {
  [[self window] close];
}

- (IBAction) okAction: (id)sender {
  [[self window] close];

  NSUserDefaults  *userDefaults = [NSUserDefaults standardUserDefaults];

  if (defaultColorMappingChanged) {
    NSString  *localisedName = [defaultColorMappingPopUp titleOfSelectedItem];
    NSString  *name = 
      [localisedColorMappingNamesReverseLookup objectForKey: localisedName];

    [userDefaults setObject: name forKey: @"defaultColorMapping"];
    
    defaultColorMappingChanged = NO;
  }
  
  if (defaultColorPaletteChanged) {
    NSString  *localisedName = [defaultColorPalettePopUp titleOfSelectedItem];
    NSString  *name = 
      [localisedColorPaletteNamesReverseLookup objectForKey: localisedName];
    
    [userDefaults setObject: name forKey: @"defaultColorPalette"];
      
    defaultColorPaletteChanged = NO;
  }
  
  [self updateButtonState];
}


- (IBAction) defaultColorMappingChanged: (id) sender {
  defaultColorMappingChanged = YES;
  [self updateButtonState];
}

- (IBAction) defaultColorPaletteChanged: (id) sender {
  defaultColorPaletteChanged = YES;
  [self updateButtonState];
}

@end // @implementation PreferencesPanelControl


@implementation PreferencesPanelControl (PrivateMethods)

- (void) updateButtonState {
  [okButton setEnabled: (defaultColorMappingChanged || 
                         defaultColorPaletteChanged)];
}

@end // @implementation PreferencesPanelControl (PrivateMethods)
