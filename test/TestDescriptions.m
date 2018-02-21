#import "TestDescriptions.h"


NSString *descriptionForMatchTargets(NSArray *matchTargets) {
  NSEnumerator  *targetsEnum = [matchTargets objectEnumerator];

  // Can assume there is always one.
  NSString  *descr = [targetsEnum nextObject];

  NSString  *matchTarget = [targetsEnum nextObject];
  if (matchTarget) {
    // At least two match targets.
    NSString  *pairTemplate = 
      NSLocalizedStringFromTable(
        @"%@ or %@" , @"Tests", 
        @"Pair of match targets with 1: a target match, and 2: another target match");
      
    descr = [NSString stringWithFormat: pairTemplate, matchTarget, descr];

    NSString  *moreTemplate = 
      NSLocalizedStringFromTable(
        @"%@, %@" , @"Tests",
        @"Three or more match targets with 1: a target match, and 2: two or more other target matches");

    while (matchTarget = [targetsEnum nextObject]) {
      // Three or more
      descr = [NSString stringWithFormat: moreTemplate, matchTarget, descr];
    }
  }
  
  return descr;
}
