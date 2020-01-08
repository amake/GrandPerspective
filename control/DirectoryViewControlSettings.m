#import "DirectoryViewControlSettings.h"

#import "DirectoryViewDisplaySettings.h"
#import "PreferencesPanelControl.h"

@implementation DirectoryViewControlSettings

- (instancetype) init {
  NSUserDefaults  *userDefaults = [NSUserDefaults standardUserDefaults];

  return 
    [self initWithDisplaySettings: [DirectoryViewDisplaySettings defaultSettings]
                 unzoomedViewSize: NSMakeSize([userDefaults floatForKey: DefaultViewWindowWidth],
                                              [userDefaults floatForKey: DefaultViewWindowHeight])];
}

- (instancetype) initWithDisplaySettings:(DirectoryViewDisplaySettings *)displaySettings
                        unzoomedViewSize:(NSSize)unzoomedViewSize {
  if (self = [super init]) {
    _displaySettings = [displaySettings retain];
    _unzoomedViewSize = unzoomedViewSize;
  }
  
  return self;
}

- (void) dealloc {
  [_displaySettings release];

  [super dealloc];
}

@end
