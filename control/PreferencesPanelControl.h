#import <Cocoa/Cocoa.h>


extern NSString  *FileDeletionTargetsKey;
extern NSString  *ConfirmFileDeletionKey;
extern NSString  *ConfirmFolderDeletionKey;
extern NSString  *DefaultRescanActionKey;
extern NSString  *RescanBehaviourKey;
extern NSString  *FileSizeMeasureKey;
extern NSString  *DefaultColorMappingKey;
extern NSString  *DefaultColorPaletteKey;
extern NSString  *DefaultFilterName;
extern NSString  *DefaultColorGradient;
extern NSString  *MinimumTimeBoundForColorMappingKey;
extern NSString  *ShowPackageContentsByDefaultKey;
extern NSString  *ShowEntireVolumeByDefaultKey;
extern NSString  *ProgressPanelRefreshRateKey;
extern NSString  *DefaultViewWindowWidth;
extern NSString  *DefaultViewWindowHeight;
extern NSString  *CustomFileOpenApplication;
extern NSString  *CustomFileRevealApplication;
extern NSString  *UpdateFiltersBeforeUse;
extern NSString  *TreeMemoryZoneKey;
extern NSString  *DelayBeforeAutomaticScanAfterStartupKey;

@class FilterPopUpControl;

@interface PreferencesPanelControl : NSWindowController {

  IBOutlet NSPopUpButton  *fileDeletionPopUp;
  IBOutlet NSButton  *fileDeletionConfirmationCheckBox;
  
  IBOutlet NSPopUpButton  *rescanActionPopUp;
  IBOutlet NSPopUpButton  *rescanBehaviourPopUp;
  
  IBOutlet NSPopUpButton  *fileSizeMeasurePopUp;

  IBOutlet NSPopUpButton  *defaultColorMappingPopUp;
  IBOutlet NSPopUpButton  *defaultColorPalettePopUp;
  IBOutlet NSPopUpButton  *defaultFilterPopUp;
  
  IBOutlet NSButton  *showPackageContentsByDefaultCheckBox;
  IBOutlet NSButton  *showEntireVolumeByDefaultCheckBox;
  
  FilterPopUpControl  *filterPopUpControl;
}

- (IBAction) popUpValueChanged:(id) sender;

- (IBAction) valueChanged:(id) sender;

@end
