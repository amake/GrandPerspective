#import "TimeBasedMapping.h"

#import "CompoundItem.h"
#import "DirectoryItem.h"
#import "PlainFileItem.h"

#import "PreferencesPanelControl.h"
#import "TreeWriter.h"

@interface TimeBasedMapping (PrivateMethods)

- (void) initTimeBounds: (DirectoryItem *)treeRoot;
- (void) visitItemToDetermineTimeBounds: (Item *)item;

@end // @interface TimeBasedMapping (PrivateMethods)


@implementation TimeBasedMapping

const int  secondsPerDay = 60 * 60 * 24;

// Set minimum time granularity to a minute 
const int  minTimeDelta = 60;


- (id) initWithFileItemMappingScheme: (NSObject <FileItemMappingScheme> *)schemeVal 
                                tree: (DirectoryItem *)tree {
  if (self = [super initWithFileItemMappingScheme: schemeVal]) {
    [self initTimeBounds: tree];
  }
  return self;
}


- (int) hashForFileItem: (PlainFileItem *)item atDepth: (int) depth {
  CFAbsoluteTime  itemTime = nowTime - [self timeForFileItem: item];
  CFAbsoluteTime  refTime = nowTime - minTime;
  int  hash = 0;
  
  while (YES) {
    if (itemTime > refTime) {
      return hash;
    }
    hash++;
    refTime = refTime / 2;
    if (refTime < minTimeDelta) {
      return hash;
    }
  }
}


- (BOOL) canProvideLegend {
  return YES;
}


//----------------------------------------------------------------------------
// Implementation of LegendProvidingFileItemMapping

- (NSString *) descriptionForHash: (int)hash {
  CFAbsoluteTime  lowerBound = 0;
  CFAbsoluteTime  upperBound = minTime;
  
  int i = hash;
  while (i > 0) {
    lowerBound = upperBound;
    upperBound = lowerBound + (nowTime - lowerBound) / 2;
    i--;
  }
  
  int  maxDelta = (int) floor((nowTime - lowerBound) / secondsPerDay);
  int  minDelta = (int) ceil((nowTime - upperBound) / secondsPerDay);
  
  if (hash == 0) {
    NSString *fmt = 
      NSLocalizedString(@"%d days ago or more", 
                        @"Legend for Time-based mapping schemes.");
    return [NSString stringWithFormat: fmt, minDelta];
  } else if (minDelta < maxDelta) {
    NSString *fmt = 
      NSLocalizedString(@"%d - %d days ago", 
                        @"Legend for Time-based mapping schemes.");
    return [NSString stringWithFormat: fmt, minDelta, maxDelta];
  } else {
    NSString *fmt = 
      NSLocalizedString(@"%d days ago", 
                        @"Legend for Time-based mapping schemes.");
    return [NSString stringWithFormat: fmt, maxDelta];
  }
}

- (NSString *) descriptionForRemainingHashes {
  return NSLocalizedString(@"More recent",
                           @"Legend for Time-based mapping schemes.");
}

@end // @implementation TimeBasedMapping


@implementation TimeBasedMapping (PrivateMethods)

- (void) initTimeBounds: (DirectoryItem *)treeRoot {
  minTime = 0;
  maxTime = 0;
  [self visitItemToDetermineTimeBounds: treeRoot];
  
  nowTime = CFAbsoluteTimeGetCurrent();
  if (maxTime > nowTime) {
    NSLog(@"Maximum time is in the future.");
  }
  if (minTime > nowTime) {
    NSLog(@"Minimum time is in the future.");
  }
  
  // Check if the preferences override the minimum.
  NSUserDefaults  *userDefaults = [NSUserDefaults standardUserDefaults];
  NSString  *minTimeBoundString = [userDefaults stringForKey: MinimumTimeBoundForColorMappingKey];
  CFAbsoluteTime minTimeBound;
  Boolean ok = CFDateFormatterGetAbsoluteTimeFromString([TreeWriter timeFormatter],
                                                        (CFStringRef) minTimeBoundString,
                                                        NULL,
                                                        &minTimeBound);
  if (! ok) {
    NSLog(@"Failed to parse preference value for %@: %@", 
          MinimumTimeBoundForColorMappingKey,
          minTimeBoundString);
  } else if (minTimeBound > nowTime) {
    NSLog(@"Ignoring preference value for %@. It occurs in the future.",
          MinimumTimeBoundForColorMappingKey);
  } else if (minTime < minTimeBound) {
    minTime = minTimeBound;
    NSLog(@"Basing minTime on value specified in preferences.");
  }

  NSLog(@"minTime=%@, maxTime=%@", 
        [FileItem stringForTime: minTime],
        [FileItem stringForTime: maxTime]);
}


- (void) visitItemToDetermineTimeBounds: (Item *)item {
  if ([item isVirtual]) {
    [self visitItemToDetermineTimeBounds: [((CompoundItem *)item) getFirst]];
    [self visitItemToDetermineTimeBounds: [((CompoundItem *)item) getSecond]];
  }
  else {
    FileItem  *fileItem = (FileItem *)item;
    
    if ([fileItem isPhysical]) {
      // Only consider actual files.
      
      CFAbsoluteTime  itemTime = [self timeForFileItem: fileItem];
      if (itemTime != 0) {
        if (minTime == 0 || itemTime < minTime) {
          minTime = itemTime;
        }
        if (maxTime == 0 || itemTime > maxTime) {
          maxTime = itemTime;
        }
      }
    }
    
    if ([fileItem isDirectory]) {
      [self visitItemToDetermineTimeBounds: [((DirectoryItem *)fileItem) getContents]];
    }
  }
}

@end // @implementation TimeBasedMapping (PrivateMethods)

