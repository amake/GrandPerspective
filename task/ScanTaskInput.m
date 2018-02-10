#import "ScanTaskInput.h"

#import "PreferencesPanelControl.h"


@implementation ScanTaskInput

// Overrides designated initialiser
- (instancetype) init {
  NSAssert(NO, @"Use initWithPath:fileSizeMeasure:filterSet instead");
  return nil;
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
              fileSizeMeasure:(NSString *)fileSizeMeasureVal
                    filterSet:(FilterSet *)filterSetVal
              packagesAsFiles:(BOOL) packagesAsFilesVal {
  if (self = [super init]) {
    pathToScan = [path retain];
    fileSizeMeasure = [fileSizeMeasureVal retain];
    filterSet = [filterSetVal retain];
    packagesAsFiles = packagesAsFilesVal;
  }
  return self;
}

- (void) dealloc {
  [pathToScan release];
  [fileSizeMeasure release];
  [filterSet release];
  
  [super dealloc];
}


- (NSString *) pathToScan {
  return pathToScan;
}

- (NSString *) fileSizeMeasure {
  return fileSizeMeasure;
}

- (FilterSet *) filterSet {
  return filterSet;
}

- (BOOL) packagesAsFiles {
  return packagesAsFiles;
}

@end
