#import "NSURL.h"

@implementation NSURL (HelperMethods)

- (BOOL) isDirectory {
  NSError  *error = nil;
  NSNumber  *isDirectory;
  
  [self getResourceValue: &isDirectory forKey: NSURLIsDirectoryKey error: &error];
  if (error != nil) {
    NSLog(@"Failed to obtain directory status for %@: %@", self, [error description]);
    return NO;
  }
  
  return [isDirectory boolValue];
}

- (BOOL) isPackage {
  NSError  *error = nil;
  NSNumber  *isPackage;
  
  [self getResourceValue: &isPackage forKey: NSURLIsPackageKey error: &error];
  if (error != nil) {
    NSLog(@"Failed to obtain package status for %@: %@", self, [error description]);
    return NO;
  }
  
  return [isPackage boolValue];
}

- (BOOL) isHardLinked {
  NSNumber  *linkCount;
  NSError  *error = nil;
  
  [self getResourceValue: &linkCount forKey: NSURLLinkCountKey error: &error];
  if (error != nil) {
    NSLog(@"Failed to obtain link count for %@: %@", self, [error description]);
    return NO;
  }
  
  return [linkCount integerValue] > 1;
}

- (CFAbsoluteTime) creationTime {
  NSDate  *creationTime;
  NSError  *error = nil;
  
  [self getResourceValue: &creationTime forKey:NSURLCreationDateKey error: &error];
  if (error != nil) {
    NSLog(@"Failed to obtain creation time for %@: %@", self, [error description]);
    return NO;
  }
  
  return [creationTime timeIntervalSinceReferenceDate];
}

- (CFAbsoluteTime) modificationTime {
  NSDate  *modificationTime;
  NSError  *error = nil;
  
  [self getResourceValue: &modificationTime forKey:NSURLContentModificationDateKey error: &error];
  if (error != nil) {
    NSLog(@"Failed to obtain modification time for %@: %@", self, [error description]);
    return NO;
  }
  
  return [modificationTime timeIntervalSinceReferenceDate];
}

- (CFAbsoluteTime) accessTime {
  NSDate  *accessTime;
  NSError  *error = nil;
  
  [self getResourceValue: &accessTime forKey:NSURLContentAccessDateKey error: &error];
  if (error != nil) {
    NSLog(@"Failed to obtain access time for %@: %@", self, [error description]);
    return NO;
  }
  
  return [accessTime timeIntervalSinceReferenceDate];
}

@end
