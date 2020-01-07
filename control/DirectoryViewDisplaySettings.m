#import "DirectoryViewDisplaySettings.h"

#import "PreferencesPanelControl.h"

@implementation DirectoryViewDisplaySettings

- (instancetype) init {
  NSUserDefaults  *ud = [NSUserDefaults standardUserDefaults];

  return
    [self initWithColorMappingKey: [ud stringForKey: DefaultColorMappingKey]
                  colorPaletteKey: [ud stringForKey: DefaultColorPaletteKey]
                         maskName: [ud stringForKey: DefaultFilterName]
                      maskEnabled: NO
                 showEntireVolume: [[ud objectForKey: ShowEntireVolumeByDefaultKey] boolValue]
              showPackageContents: [[ud objectForKey: ShowPackageContentsByDefaultKey] boolValue]];
}

- (instancetype) initWithColorMappingKey:(NSString *)colorMappingKey
                         colorPaletteKey:(NSString *)colorPaletteKey
                                maskName:(NSString *)maskName
                             maskEnabled:(BOOL)maskEnabled
                        showEntireVolume:(BOOL)showEntireVolume
                     showPackageContents:(BOOL)showPackageContents {
  if (self = [super init]) {
    _colorMappingKey = [colorMappingKey retain];
    _colorPaletteKey = [colorPaletteKey retain];
    _maskName = [maskName retain];
    _fileItemMaskEnabled = maskEnabled;
    _showEntireVolume = showEntireVolume;
    _showPackageContents = showPackageContents;
  }

  return self;
}

- (void) dealloc {
  [_colorMappingKey release];
  [_colorPaletteKey release];
  [_maskName release];

  [super dealloc];
}

+ (DirectoryViewDisplaySettings *)defaultSettings {
  return [[[DirectoryViewDisplaySettings alloc] init] autorelease];
}

@end
