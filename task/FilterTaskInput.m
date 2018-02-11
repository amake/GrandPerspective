#import "FilterTaskInput.h"

#import "TreeContext.h"
#import "PreferencesPanelControl.h"


@implementation FilterTaskInput

// Overrides designated initialiser
- (instancetype) init {
  NSAssert(NO, @"Use initWithOldContext:filterSet: instead");
  return [self initWithTreeContext: nil filterSet: nil];
}

- (instancetype) initWithTreeContext:(TreeContext *)treeContextVal
                           filterSet:(FilterSet *)filterSetVal {
  NSUserDefaults  *userDefaults = [NSUserDefaults standardUserDefaults];
  
  BOOL  showPackageContentsByDefault =
    [userDefaults boolForKey: ShowPackageContentsByDefaultKey] ? NSOnState : NSOffState;

  return [self initWithTreeContext: treeContextVal
                         filterSet: filterSetVal
                   packagesAsFiles: !showPackageContentsByDefault];
}

- (instancetype) initWithTreeContext:(TreeContext *)treeContext
                           filterSet:(FilterSet *)filterSet
                     packagesAsFiles:(BOOL) packagesAsFiles {
  if (self = [super init]) {
    _treeContext = [treeContext retain];
    _filterSet = [filterSet retain];
    
    packagesAsFiles = packagesAsFiles;
  }
  return self;
}

- (void) dealloc {
  [_treeContext release];
  [_filterSet release];
  
  [super dealloc];
}

@end
