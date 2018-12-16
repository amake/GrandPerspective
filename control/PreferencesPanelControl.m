#import "PreferencesPanelControl.h"

#import "DirectoryViewControl.h"
#import "MainMenuControl.h"
#import "FileItemMappingCollection.h"
#import "ColorListCollection.h"
#import "TreeBuilder.h"

#import "FilterPopUpControl.h"

#import "UniqueTagsTransformer.h"

NSString  *FileDeletionTargetsKey = @"fileDeletionTargets";
NSString  *ConfirmFileDeletionKey = @"confirmFileDeletion";
NSString  *DefaultRescanActionKey = @"defaultRescanAction";
NSString  *RescanBehaviourKey = @"rescanBehaviour";
NSString  *NoViewsBehaviourKey = @"noViewsBehaviour";
NSString  *FileSizeMeasureKey = @"fileSizeMeasure";
NSString  *FileSizeUnitSystemKey = @"fileSizeUnitSystem";
NSString  *DefaultColorMappingKey = @"defaultColorMapping";
NSString  *DefaultColorPaletteKey = @"defaultColorPalette";
NSString  *DefaultFilterName = @"defaultFilter";
NSString  *ShowPackageContentsByDefaultKey = @"showPackageContentsByDefault";
NSString  *ShowEntireVolumeByDefaultKey = @"showEntireVolumeByDefault";


/* Note: The preferences below cannot currently be changed from the preferences panel; they are set
 * by the application defaults and can be changed by manually editing the user preferences file.
 */
NSString  *ConfirmFolderDeletionKey = @"confirmFolderDeletion";
NSString  *DefaultColorGradient = @"defaultColorGradient";
NSString  *MinimumTimeBoundForColorMappingKey = @"minimumTimeBoundForColorMapping";
NSString  *ProgressPanelRefreshRateKey = @"progressPanelRefreshRate";
NSString  *DefaultViewWindowWidth = @"defaultViewWindowWidth";
NSString  *DefaultViewWindowHeight = @"defaultViewWindowHeight";
NSString  *CustomFileOpenApplication = @"customFileOpenApplication";
NSString  *CustomFileRevealApplication = @"customFileRevealApplication";
NSString  *UpdateFiltersBeforeUse = @"updateFiltersBeforeUse";
NSString  *TreeMemoryZoneKey = @"treeMemoryZone";
NSString  *DelayBeforeWelcomeWindowAfterStartupKey = @"delayBeforeWelcomeWindowAfterStartup";

@interface PreferencesPanelControl (PrivateMethods)

+ (BOOL) doesAppHaveFileDeletePermission;

- (void) setupPopUp:(NSPopUpButton *)popUp key:(NSString *)key content:(NSArray *)names;

- (void) setPopUp:(NSPopUpButton *)popUp toValue:(NSString *)value;

- (void) updateButtonState;

@end

@implementation PreferencesPanelControl

static BOOL appHasDeletePermission;

// Thread-safe initialisation
+ (void)initialize {
  appHasDeletePermission = [PreferencesPanelControl doesAppHaveFileDeletePermission];
}

+ (BOOL) appHasDeletePermission {
  return appHasDeletePermission;
}

- (instancetype) init {
  if (self = [super initWithWindow: nil]) {
    // Trigger loading of the window
    [self window];
  }

  return self;
}

- (void) dealloc {
  [filterPopUpControl release];
  
  [super dealloc];
}


- (NSString *)windowNibName {
  return @"PreferencesPanel";
}

- (void) windowDidLoad {
  NSUserDefaults  *userDefaults = [NSUserDefaults standardUserDefaults];

  // Configure all pop-up buttons.
  [self setupPopUp: fileDeletionPopUp
               key: FileDeletionTargetsKey
           content: [DirectoryViewControl fileDeletionTargetNames]];
  [self setupPopUp: rescanActionPopUp
               key: DefaultRescanActionKey
           content: [MainMenuControl rescanActionNames]];
  [self setupPopUp: rescanBehaviourPopUp
               key: RescanBehaviourKey
           content: [MainMenuControl rescanBehaviourNames]];
  [self setupPopUp: noViewsBehaviourPopUp
               key: NoViewsBehaviourKey
           content: [MainMenuControl noViewsBehaviourNames]];
  [self setupPopUp: fileSizeMeasurePopUp
               key: FileSizeMeasureKey
           content: [TreeBuilder fileSizeMeasureNames]];
  [self setupPopUp: fileSizeUnitSystemPopUp
               key: FileSizeUnitSystemKey
           content: [FileItem fileSizeUnitSystemNames]];
  [self setupPopUp: defaultColorMappingPopUp
               key: DefaultColorMappingKey
           content:  [[FileItemMappingCollection defaultFileItemMappingCollection] allKeys]];
  [self setupPopUp: defaultColorPalettePopUp
               key: DefaultColorPaletteKey
           content: [[ColorListCollection defaultColorListCollection] allKeys]];

  if (! appHasDeletePermission) {
    // Cannot delete, so fix visible setting to "DeleteNothing" and prevent changes
    [fileDeletionPopUp setEnabled: false];
    [self setPopUp: fileDeletionPopUp toValue: DeleteNothing];
  }

  // The filter pop-up uses its own control that keeps it up to date. Its entries can change when
  // filters are added/removed.
  filterPopUpControl = [[FilterPopUpControl alloc] initWithPopUpButton: defaultFilterPopUp];
  [filterPopUpControl selectFilterNamed: [userDefaults stringForKey: DefaultFilterName]];

  UniqueTagsTransformer  *tagMaker = [UniqueTagsTransformer defaultUniqueTagsTransformer];
  defaultFilterPopUp.tag = [[tagMaker transformedValue: DefaultFilterName] intValue];
  
  fileDeletionConfirmationCheckBox.state =
    [userDefaults boolForKey: ConfirmFileDeletionKey] ? NSOnState : NSOffState;
  showPackageContentsByDefaultCheckBox.state =
    [userDefaults boolForKey: ShowPackageContentsByDefaultKey] ? NSOnState : NSOffState;
  showEntireVolumeByDefaultCheckBox.state =
    [userDefaults boolForKey: ShowEntireVolumeByDefaultKey] ? NSOnState : NSOffState;

  [self updateButtonState];
  
  [self.window center];
}


- (IBAction) popUpValueChanged:(id)sender {
  NSUserDefaults  *userDefaults = [NSUserDefaults standardUserDefaults];
  UniqueTagsTransformer  *tagMaker = [UniqueTagsTransformer defaultUniqueTagsTransformer];

  NSPopUpButton  *popUp = sender;
  NSString  *name = [tagMaker nameForTag: popUp.selectedItem.tag];
  NSString  *key = [tagMaker nameForTag: popUp.tag];

  [userDefaults setObject: name forKey: key];
  
  if (popUp == fileDeletionPopUp) {
    [self updateButtonState];
  }
}

- (IBAction) valueChanged:(id)sender {
  NSUserDefaults  *userDefaults = [NSUserDefaults standardUserDefaults];

  if (sender == fileDeletionConfirmationCheckBox) {
    BOOL  enabled = [sender state] == NSOnState;

    [userDefaults setBool: enabled forKey: ConfirmFileDeletionKey];
  }
  else if (sender == showPackageContentsByDefaultCheckBox) {
    BOOL  enabled = [sender state] == NSOnState;
    
    [userDefaults setBool: enabled forKey: ShowPackageContentsByDefaultKey];
  }
  else if (sender == showEntireVolumeByDefaultCheckBox) {
    BOOL  enabled = [sender state] == NSOnState;
    
    [userDefaults setBool: enabled forKey: ShowEntireVolumeByDefaultKey];
  }
  else {
    NSAssert(NO, @"Unexpected sender for -valueChanged.");
  }
}

@end // @implementation PreferencesPanelControl


@implementation PreferencesPanelControl (PrivateMethods)

- (void) setupPopUp:(NSPopUpButton *)popUp
                key:(NSString *)key
            content:(NSArray *)names {
  UniqueTagsTransformer  *tagMaker = [UniqueTagsTransformer defaultUniqueTagsTransformer];
  NSUserDefaults  *userDefaults = [NSUserDefaults standardUserDefaults];
  
  // Associate the pop-up with its key in the preferences by their tag.
  popUp.tag = [[tagMaker transformedValue: key] intValue];

  // Initialise the pop-up with its (localized) content
  [popUp removeAllItems];
  [tagMaker addLocalisedNames: names
                      toPopUp: popUp
                       select: [userDefaults stringForKey: key]
                        table: @"Names"];
}

- (void) setPopUp: (NSPopUpButton *)popUp toValue:(NSString *)value {
  UniqueTagsTransformer  *tagMaker = [UniqueTagsTransformer defaultUniqueTagsTransformer];

  NSUInteger  tag = [tagMaker tagForName: value];
  [popUp selectItemAtIndex: [popUp indexOfItemWithTag: tag]];
}

- (void) updateButtonState {
  UniqueTagsTransformer  *tagMaker = [UniqueTagsTransformer defaultUniqueTagsTransformer];
  NSString  *name = [tagMaker nameForTag: fileDeletionPopUp.selectedItem.tag];

  fileDeletionConfirmationCheckBox.enabled = ![name isEqualToString: DeleteNothing];
}

/* Check if the application has permission to delete files. The assumption is that the application
 * has this permission unless it is established that it is sandboxed and that it lacks the needed
 * read-write permissions for files selected by the user.
 */
+ (BOOL) doesAppHaveFileDeletePermission {
  // By default assume the app has delete permission. In that case, when there is a failure
  // establishing the correct permission, the worst that can happen is that delete fails (which
  // may happen anyway, e.g. when a file has read-only settings). The alternative is that the app
  // would unnecessarily prevent the user from deleting files, after the user has indicated he
  // want to be able to do this.
  BOOL  canDelete = true;
  OSStatus  err;
  SecCodeRef  me;
  CFDictionaryRef  dynamicInfo;

  NSLog(@"Trying to establish application entitlements");

  // On Mojave this invocation results in the following log messages:
  //  [logging-persist] cannot open file at line 42249 of [95fbac39ba]
  //  [logging-persist] os_unix.c:42249: (0) open(/var/db/DetachedSignatures) - Undefined error: 0
  // Hopefully this will be fixed/resolved in a future version of macOS.
  err = SecCodeCopySelf(kSecCSDefaultFlags, &me);

  if (err != errSecSuccess) {
    NSLog(@"Failed to successfully invoke SecCodeCopySelf -> %d", err);
    return canDelete;
  }

  err = SecCodeCopySigningInformation(me, (SecCSFlags) kSecCSDynamicInformation, &dynamicInfo);
  if (err != errSecSuccess) {
    NSLog(@"Failed to successfully invoke SecCodeCopySigningInformation -> %d", err);
  }
  else {
    NSDictionary  *entitlements = CFDictionaryGetValue(dynamicInfo, kSecCodeInfoEntitlementsDict);
    NSLog(@"entitlements = %@", entitlements);

    canDelete = (
      !entitlements[@"com.apple.security.app-sandbox"] ||
      entitlements[@"com.apple.security.files.user-selected.read-write"]
    );
  }

  CFRelease(dynamicInfo);
  NSLog(@"doesAppHaveFileDeletePermission = %d", canDelete);
  return canDelete;
}

@end // @implementation PreferencesPanelControl (PrivateMethods)
