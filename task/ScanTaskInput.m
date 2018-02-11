#import "ScanTaskInput.h"

#import "PreferencesPanelControl.h"


@implementation ScanTaskInput

// Overrides designated initialiser
- (instancetype) init {
  NSAssert(NO, @"Use initWithPath:fileSizeMeasure:filterSet instead");
  return [self initWithPath: nil fileSizeMeasure: nil filterSet: nil];
}

- (instancetype) initWithPath:(NSString *)path
              fileSizeMeasure:(NSString *)fileSizeMeasureVal
                    filterSet:(FilterSet *)filterSetVal {

  NSUserDefaults  *userDefaults = [NSUserDefaults standardUserDefaults];
  
  BOOL  showPackageContentsByDefault =
    [userDefaults boolForKey: ShowPackageContentsByDefaultKey] ? NSOnState : NSOffState;
            
  return [self initWithPath: path
            fileSizeMeasure: fileSizeMeasureVal
                  filterSet: filterSetVal
            packagesAsFiles: !showPackageContentsByDefault];
}
         
- (instancetype) initWithPath:(NSString *)path
              fileSizeMeasure:(NSString *)fileSizeMeasure
                    filterSet:(FilterSet *)filterSet
              packagesAsFiles:(BOOL) packagesAsFiles {
  if (self = [super init]) {
    _path = [path retain];
    _fileSizeMeasure = [fileSizeMeasure retain];
    _filterSet = [filterSet retain];
    _packagesAsFiles = packagesAsFiles;
  }
  return self;
}

- (void) dealloc {
  [_path release];
  [_fileSizeMeasure release];
  [_filterSet release];
  
  [super dealloc];
}

@end
