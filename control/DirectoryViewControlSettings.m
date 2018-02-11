#import "DirectoryViewControlSettings.h"

#import "PreferencesPanelControl.h"

@implementation DirectoryViewControlSettings

- (instancetype) init {
  NSUserDefaults  *userDefaults = [NSUserDefaults standardUserDefaults];

  return 
    [self initWithColorMappingKey: [userDefaults stringForKey: DefaultColorMappingKey]
                  colorPaletteKey: [userDefaults stringForKey: DefaultColorPaletteKey]
                         maskName: [userDefaults stringForKey: DefaultFilterName]
                      maskEnabled: NO
                 showEntireVolume: [[userDefaults objectForKey: ShowEntireVolumeByDefaultKey] boolValue]
              showPackageContents: [[userDefaults objectForKey: ShowPackageContentsByDefaultKey] boolValue]
                 unzoomedViewSize: NSMakeSize([userDefaults floatForKey: DefaultViewWindowWidth],
                                              [userDefaults floatForKey: DefaultViewWindowHeight])];
}

- (instancetype) initWithColorMappingKey:(NSString *)colorMappingKey
                         colorPaletteKey:(NSString *)colorPaletteKey
                                maskName:(NSString *)maskName
                             maskEnabled:(BOOL)maskEnabled
                        showEntireVolume:(BOOL)showEntireVolume
                     showPackageContents:(BOOL)showPackageContents
                        unzoomedViewSize:(NSSize)unzoomedViewSize {
  if (self = [super init]) {
    _colorMappingKey = [colorMappingKey retain];
    _colorPaletteKey = [colorPaletteKey retain];
    _maskName = [maskName retain];
    _fileItemMaskEnabled = maskEnabled;
    _showEntireVolume = showEntireVolume;
    _showPackageContents = showPackageContents;
    _unzoomedViewSize = unzoomedViewSize;
  }
  
  return self;
}

- (void) dealloc {
  [_colorMappingKey release];
  [_colorPaletteKey release];
  [_maskName release];

  [super dealloc];
}

@end
